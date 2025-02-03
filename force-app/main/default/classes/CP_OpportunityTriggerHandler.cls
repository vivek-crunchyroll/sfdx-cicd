public without sharing class CP_OpportunityTriggerHandler {
    
    public static String consumerProductsRecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('Consumer_Products').getRecordTypeId();
    
    public static void beforeInsert(List<Opportunity> opportunities){
        List<Pricebook2> standardPricebook = [Select Id From Pricebook2 Where IsActive = true Limit 1];
        for(Opportunity opp : opportunities){
            //checking whether the record is related to consumer products or not
            if(opp.RecordTypeId == consumerProductsRecordTypeId){
                if(opp.Pricebook2Id == null && !standardPricebook.isEmpty()){
                    opp.Pricebook2Id = standardPricebook[0].Id;
                }
            }
        }
    }
    
   
    public static void beforeUpdate(List<Opportunity> opportunities, Map<id,Opportunity> oldMap){
        for (Opportunity opp : opportunities) {
            if(opp.RecordTypeId == consumerProductsRecordTypeId){
                Opportunity oldopp = oldMap.get(opp.Id);
                
                if(oldOpp != null && oldOpp.StageName != opp.StageName){
                   
                    //Populate Licensor Review Start Date
                    if(opp.StageName == 'Licensor Review' && oldOpp.StageName != 'Licensor Review' && opp.Licensor_Review_Start_Date__c == null){
                           opp.Licensor_Review_Start_Date__c = System.now();   
                    }
                    
                    //Populate Licensor Review End Date 
                    else if (opp.stageName == 'Approved' && oldopp.stageName == 'Licensor Review' && opp.Licensor_Review_End_Date__c == null){
                           opp.Licensor_Review_End_Date__c = system.now();   
                    }
                }
            }
        }   
    }
    
    public static void afterInsert(List<Opportunity> opportunities){
        List<Opportunity> convertedOpportunities = new List<Opportunity>();
        Set<Id> convertedLeadIds = new Set<Id>();
        
        for(Opportunity opp : opportunities){
            //checking whether the record is related to consumer products or not
            if(opp.RecordTypeId == consumerProductsRecordTypeId){
                if(String.isNotBlank(opp.Lead_Record_ID__c)){
                    convertedOpportunities.add(opp);
                    convertedLeadIds.add(opp.Lead_Record_ID__c);
                }
            }
        }
        
        if(!convertedOpportunities.isEmpty()){
            createLineItems(convertedOpportunities, convertedLeadIds);
            addDealAsParentToRightsSet(convertedOpportunities, convertedLeadIds);
        }
    }
    public static void afterUpdate(List<Opportunity> opportunities, Map<Id,Opportunity> oldmap ){
        List<Opportunity> opportunitiesToprocess = new List<Opportunity>();
        List<Opportunity> approvedOpportunities = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if(opp.RecordTypeId == consumerProductsRecordTypeId){
                Opportunity oldOpp = oldMap.get(opp.Id);
                if (opp.StageName == 'Licensor Review' && oldOpp.StageName != 'Licensor Review') {
                    opportunitiesToprocess.add(opp);
                    oppIds.add(opp.Id);
                }
                if(opp.StageName == 'Approved' && oldOpp.StageName == 'Licensor Review'){
                   approvedOpportunities.add(opp);
                }
            }
        }
        if (!opportunitiesToProcess.isEmpty()) {
            sendEmailToPublicGroupForEachOpportunity(opportunitiesToprocess, oppIds);
        }
        
        if(!approvedOpportunities.isEmpty()){
            publishEventOnDealApproval(approvedOpportunities);
        }
    }
    
    
    //Send Email to user when multiple records updated  
    public static void sendEmailToPublicGroupForEachOpportunity(List<Opportunity> opportunities, Set<Id> oppIds) {
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Visualforce_Email_Template' LIMIT 1].Id;
        String publicGroupName = 'Consumer_Products_Team'; 
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = :publicGroupName AND Type = 'Regular' LIMIT 1];
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :publicGroup.Id];
        Set<Id> consumerProductUserIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            if (member.UserOrGroupId!= null){
                System.debug('UserOrGroupId: ' + member.UserOrGroupId);
                if (member.UserOrGroupId.getSObjectType() == User.sObjectType) {
                    consumerProductUserIds.add(member.UserOrGroupId);
                }
            }
        }
        
        List<String> emailAddresses = new List<String>();
        for(User usr : [SELECT Email FROM User WHERE Id IN:consumerProductUserIds]){
            if (usr.Email != null) {
                emailAddresses.add(usr.Email);
            }
        }
        system.debug('emails:::'+emailAddresses);
        
        Map<Id, Id> oppIdWithCDLinkId = new Map<Id, Id>();
        for(ContentDocumentLink cdLink : [Select Id, LinkedEntityId, ContentDocumentId From ContentDocumentLink Where LinkedEntityId IN: oppIds]){
            oppIdWithCDLinkId.put(cdLink.LinkedEntityId, cdLink.ContentDocumentId);
        }
        
        Map<Id, ContentVersion> cdLinkIdWithContentVersion = new Map<Id, ContentVersion>();
        for(ContentVersion cv : [SELECT Id, Title, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN: oppIdWithCDLinkId.values()]){
            cdLinkIdWithContentVersion.put(cv.ContentDocumentId, cv);
        }
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opportunities) {
            emails.add(sendEmailForOpportunity(opp, emailAddresses, emailTemplateId, oppIdWithCDLinkId, cdLinkIdWithContentVersion));
        }
        
        // Send the emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    // Method to send a separate email for a single Opportunity
    public static Messaging.SingleEmailMessage sendEmailForOpportunity(Opportunity opp, List<String> emailAddresses, Id emailTemplateId, Map<Id, Id> oppIdWithCDLinkId, Map<Id, ContentVersion> cdLinkIdWithContentVersion) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(emailAddresses);
        email.setTemplateId(emailTemplateId);
        email.setSaveAsActivity(false);
        email.setTargetObjectId(UserInfo.getUserId());
        email.setWhatId(opp.Id);
        
        if(oppIdWithCDLinkId.containsKey(opp.Id) && cdLinkIdWithContentVersion.containsKey(oppIdWithCDLinkId.get(opp.Id))){
            ContentVersion contentVersion = cdLinkIdWithContentVersion.get(oppIdWithCDLinkId.get(opp.Id));
            
            // Create the attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(contentVersion.Title + '.xlsx'); 
            attachment.setBody(contentVersion.VersionData);
            
            // Attach the file to the email
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        }
        
        return email;
    }
    
    
    
    public static void createLineItems(List<Opportunity> opportunities, Set<Id> convertedLeadIds){
        Map<Id, List<Titles_Interested__c>> leadWithTitles = new Map<Id, List<Titles_Interested__c>>();
        for(Titles_Interested__c title : [Select Id, Lead__c, Title__c From Titles_Interested__c Where Lead__c IN: convertedLeadIds]){
            if(!leadWithTitles.containsKey(title.Lead__c)){
                leadWithTitles.put(title.Lead__c, new List<Titles_Interested__c>());
            }
            List<Titles_Interested__c> titlesInterested =  leadWithTitles.get(title.Lead__c);
            titlesInterested.add(title);
            leadWithTitles.put(title.Lead__c, titlesInterested);
        }
        
        if(!leadWithTitles.isEmpty()){
            List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
            for(Opportunity opp : opportunities){
                for(Titles_Interested__c title : leadWithTitles.get(opp.Lead_Record_ID__c)){
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.Product2Id = title.Title__c;
                    oli.OpportunityId = opp.Id;
                    lineItems.add(oli);
                }
            }
            
            if(!lineItems.isEmpty()){
                insert lineItems;
            }
        }
    }
    
    public static void addDealAsParentToRightsSet(List<Opportunity> opportunities, Set<Id> convertedLeadIds){
        Map<Id, Rights_Set__c> leadIdWithRightsSet = new Map<Id, Rights_Set__c>();
        for(Rights_Set__c rights : [Select Id, Lead__c From Rights_Set__c Where Lead__c IN: convertedLeadIds]){
            leadIdWithRightsSet.put(rights.Lead__c, rights);
        }
        
        if(!leadIdWithRightsSet.isEmpty()){
            List<Rights_Set__c> rightsToUpdate = new List<Rights_Set__c>();
            for(Opportunity opp : opportunities){
                if(leadIdWithRightsSet.containsKey(opp.Lead_Record_ID__c)){
                    Rights_Set__c rights = leadIdWithRightsSet.get(opp.Lead_Record_ID__c);
                    rights.Deal__c = opp.Id;
                    rightsToUpdate.add(rights);
                }
            }
            if(!rightsToUpdate.isEmpty()){
                update rightsToUpdate;
            }
        }
    }
    
    public static void publishEventOnDealApproval(List<Opportunity> approvedOpportunities){
        List<Deal_Approved__e> dealApprovedEvents = new List< Deal_Approved__e>();
        for(Opportunity opp : approvedOpportunities){
            Deal_Approved__e dealEvent = new Deal_Approved__e();
            dealEvent.Deal_Id__c = opp.Id;
            dealApprovedEvents.add(dealEvent);
        }
        
        
        List<Database.SaveResult> results = EventBus.publish(dealApprovedEvents);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    errorLogs.add(Utility.prepareErrorLog(err.getMessage(), 'Apex', '', sr.getId()));
                    System.debug('Error returned: ' + err.getStatusCode());
                }
            }       
        }
        Utility.createErrorLog(errorLogs);
    }
}