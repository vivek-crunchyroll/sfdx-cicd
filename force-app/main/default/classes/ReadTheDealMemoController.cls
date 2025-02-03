public with sharing class ReadTheDealMemoController {

    @AuraEnabled
    public static String getFileContent(Id leadId) {
        List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :leadId];    
        if (contentLinks.isEmpty()) {
            throw new AuraHandledException('No files found for this Lead.');
        }
        //Fetch first file Content
        ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentLinks[0].ContentDocumentId LIMIT 1];
        ContentVersion version = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Id = :document.LatestPublishedVersionId LIMIT 1];
        
        //return base64 encoded content
        String base64Content = EncodingUtil.base64Encode(version.VersionData);
        return base64Content;
    } 
    
    @AuraEnabled
    public static Map<String, Object> saveExtractData(String leadId, String jsonData){
        Map<String, Object> response = new Map<String, Object>();
    
        // lists for Titles Interested and unmatched products
        List<Titles_Interested__c> titlesInterestedList = new List<Titles_Interested__c>();
        List<String> unmatchedProducts = new List<String>();
        Set<Id> existingTitlesSet = new Set<Id>();
        
        
        excelSheetWrapper extractedData = (excelSheetWrapper) System.json.deserialize(jsonData,excelSheetWrapper.class );
        
        Lead leadToUpdate = [SELECT Id,Applicant_Contact__c,Applicant_Type__c,Applicant_Contact_Email__c,Created_Date__c,Jurisdiction_Business_Structure__c,VAT_or_TAX_ID__c,Signatory_Contact__c,
                            Signatory_Contact_Email__c,Accounts_Payable_Contact__c,Accounts_Payable_Contact_Email__c,Creative_Contact__c,Creative_Contact_Email__c,Submission_Contact__c,Submission_Contact_Email__c, 
                            Property__c,Territory__c,Distribution_Channels__c,Exclusivity__c,Country_of_Production__c,Target_Demographic__c,Minimum_Guarantee__c,Advance__c,MG_Payment_Schedule__c,Company,NA__c,LATAM__c,
                            ANZ__c,EMEA__c,Street,Term_Length_Start__c,Term_Length_End__c,Wholesale__c,Retail_Direct_To_Consumer__c,FOB__c,Other_Royalty_Rate__c,Distribution_Channels_Other__c FROM Lead WHERE Id=:leadId LIMIT 1];
    
        
    
        // Split the product names by semicolon and trim whitespace
        List<String> productNames = new List<String>();
        if (extractedData.property != null) {
        productNames = extractedData.property.split(';|,');
        for (Integer i = 0; i < productNames.size(); i++) {
            productNames[i] = productNames[i].trim(); 
        }
    }

        //Check if products are empty.
        if (productNames.isEmpty()) {
            response.put('noProductsWarning', 'No products found in the property field.');
        }
    
    // Query all existing Titles_Interested__c records for the lead
    List<Titles_Interested__c> existingTitles = [SELECT Id, Title__c FROM Titles_Interested__c WHERE Lead__c = :leadId];
    for (Titles_Interested__c title : existingTitles) {
        existingTitlesSet.add(title.Title__c);
    }
    
    // Query all Product2 records in one go
            Map<String, Product2> productMap = new Map<String, Product2>();
            for (Product2 product : [SELECT Id, Name FROM Product2 WHERE Name IN :productNames]) {
                productMap.put(product.Name, product);
            }
    
        
        for (String productName : productNames) {
                if ( productMap.containsKey(productName)) {
                Product2 product = productMap.get(productName);
                if (!existingTitlesSet.contains(product.Id)) {
                    Titles_Interested__c titleInterested = new Titles_Interested__c();
                    titleInterested.Lead__c = leadId; 
                    titleInterested.Title__c = product.Id; 
                    titlesInterestedList.add(titleInterested);
                }
            }else {
                unmatchedProducts.add(productName);
            }
        }
        
         // Insert all matched Titles_Interested__c records
        if (!titlesInterestedList.isEmpty()) {
            try {
                insert titlesInterestedList;
                response.put('success', 'Matched products have been saved successfully.');
            } catch (DmlException e) {
                response.put('error', 'Error inserting matched products: ' + e.getMessage());
            }
        }
    
        // If there are unmatched products, throw a warning
        if (!unmatchedProducts.isEmpty()) {
            String warningMessage = 'The following products do not match: ' + String.join(unmatchedProducts, ', ');
            response.put('warning', warningMessage);  
        }
    
        //Update the Lead fields with the extracted data
        leadToUpdate.Applicant_Contact__c = extractedData.ApplicantContact;
        leadToUpdate.Applicant_Type__c = extractedData.ApplicationType;
        leadToUpdate.Company = extractedData.Applicant;
        leadToUpdate.Applicant_Contact_Email__c = extractedData.ApplicantEmail;
        leadToUpdate.Created_Date__c = extractedData.ApplicationDate;
        leadToUpdate.Jurisdiction_Business_Structure__c = extractedData.Jurisdiction;
        leadToUpdate.Phone = extractedData.Telephone;
        leadToUpdate.VAT_or_TAX_ID__c = extractedData.VAT;
        leadToUpdate.Signatory_Contact__c = extractedData.SignatoryContact;
        leadToUpdate.Signatory_Contact_Email__c = extractedData.SignatoryEmail;
        leadToUpdate.Accounts_Payable_Contact__c = extractedData.AccountsPayableContact;
        leadToUpdate.Accounts_Payable_Contact_Email__c = extractedData.AccountsPayableEmail;
        leadToUpdate.Creative_Contact__c = extractedData.CreativeContact;
        leadToUpdate.Creative_Contact_Email__c = extractedData.CreativeContactEmail;
        leadToUpdate.Submission_Contact__c = extractedData.SubmissionsContact;
        leadToUpdate.Submission_Contact_Email__c = extractedData.SubmissionsContactEmail;
        leadToUpdate.Property__c = extractedData.property;
        leadToUpdate.Territory__c = extractedData.Territory;
        leadToUpdate.Distribution_Channels__c = extractedData.distributionChannels;
        leadToUpdate.Exclusivity__c = extractedData.Exclusivity;
        leadToUpdate.Country_of_Production__c = extractedData.CountryofProduction;
        leadToUpdate.Target_Demographic__c = extractedData.TargetDemographic;
        leadToUpdate.Term_Length_Start__c = extractedData.TermLengthStart;
        leadToUpdate.Term_Length_End__c = extractedData.TermLengthEnd;
        leadToUpdate.Minimum_Guarantee__c = extractedData.MinimumGuarantee;
        leadToUpdate.Advance__c = extractedData.Advance;
        leadToUpdate.MG_Payment_Schedule__c = extractedData.MGPaymentSchedule;
        leadToUpdate.LATAM__c = extractedData.LATAM;
        leadToUpdate.NA__c = extractedData.NA;
        leadToUpdate.ANZ__c = extractedData.ANZ;
        leadToUpdate.EMEA__c = extractedData.EMEA;
        leadToUpdate.Street = extractedData.ApplicantAddress;
        leadToUpdate.Wholesale__c = extractedData.WholeSale;
        leadToUpdate.Retail_Direct_To_Consumer__c = extractedData.RetailDirectToConsumer;
        leadToUpdate.FOB__c = extractedData.FOB;
        leadToUpdate.Other_Royalty_Rate__c = extractedData.OtherRoyaltyRate;
        leadToUpdate.Distribution_Channels_Other__c = extractedData.DistributionChannelsOther;
        
        try {
            update leadToUpdate;
            response.put('leadUpdate', 'Lead updated successfully.');
        } catch (DmlException e) {
            response.put('leadError', 'Error updating lead: ' + e.getMessage());
        }

        // Now handle the Rights_Set__c object
        Rights_Set__c rights;
        Id existingRightsSetId = checkExistingIfAny(leadId);

        if (existingRightsSetId != null) {
            System.debug(' Existing Rights_Set__c found: ' + existingRightsSetId);
            rights = [SELECT Id, Distribution_Channels__c, Distribution_Channels_Other__c FROM Rights_Set__c WHERE Id = :existingRightsSetId LIMIT 1];
        } else {
            System.debug(' No existing Rights_Set__c found, creating new one');
            rights = new Rights_Set__c();
            rights.Name = 'Rights Out';
            rights.Lead__c = leadId;
            rights.RecordTypeId = Schema.getGlobalDescribe().get('Rights_Set__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Rights_Out').getRecordTypeId();
        }
        // Set the distribution channels
        rights.Distribution_Channels__c = extractedData.distributionChannels;
        rights.Distribution_Channels_Other__c = extractedData.DistributionChannelsOther;

        System.debug(' Preparing to upsert Rights_Set__c with Distribution_Channels__c: ' + rights.Distribution_Channels__c);
        System.debug(' Preparing to upsert Rights_Set__c with Distribution_Channels_Other__c: ' + rights.Distribution_Channels_Other__c);

        // Upsert the Rights_Set__c record
        try {
            upsert rights;
            response.put('rightsUpdate', 'Rights Set updated successfully.');
            System.debug(' Rights_Set__c Upsert Successful, Record ID: ' + rights.Id);
        } catch (DmlException e) {
            response.put('rightsError', 'Error updating Rights Set: ' + e.getMessage());
        } catch (Exception e) {
            response.put('rightsError', 'General Error: ' + e.getMessage());
        }

               
        
        return response;
    
    }
    
    @AuraEnabled
    public static Id getRightsSetIdByCategory(String categoryName) {
    Media__c mediaRecord = [SELECT Rights_Set__c FROM Media__c WHERE Name = :categoryName LIMIT 1];
    return mediaRecord.Rights_Set__c;
    }
    
    
    //categoryList
    @AuraEnabled
    public static void saveSelectedCategories(String leadId, List<String> categories) {
        Rights_Set__c rights = new Rights_Set__c();
        rights.Id = checkExistingIfAny(leadId);
        rights.Name = 'Rights Out';
        rights.Lead__c = leadId;
        rights.RecordTypeId = Schema.getGlobalDescribe().get('Rights_Set__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Rights_Out').getRecordTypeId();
        //rights.Distribution_Channels__c = distributionChannels;
        //rights.Distribution_Channels_Other__c = DistributionChannelsOther;
        upsert rights;
    
        // Query existing Media__c records
        List<Media__c> existingMedia = [SELECT Name FROM Media__c WHERE Rights_Set__c = :rights.Id];
        Set<String> existingMediaNames = new Set<String>();
        for (Media__c media : existingMedia) {
        existingMediaNames.add(media.Name);
        }
    
        // Prepare list of new Media__c records
        List<Media__c> mediaRecords = new List<Media__c>();
        for(Media_Rights__c mr : [Select Id, Name From Media_Rights__c Where Name IN: categories]){
            if (!existingMediaNames.contains(mr.Name)) {
            Media__c mediaRecord = new Media__c();
            mediaRecord.Name = mr.Name;
            mediaRecord.Rights_Set__c = rights.Id;
            mediaRecord.Media_Rights__c = mr.Id;
            mediaRecords.add(mediaRecord);
            }
        }
    
        if (!mediaRecords.isEmpty()) {
            insert mediaRecords;
        }
    }
    
    public static Id checkExistingIfAny(String recordId){
        List<Rights_Set__c> getRightsSet = [Select Id From Rights_Set__c Where Lead__c =: recordId Limit 1 ];
        if(!getRightsSet.isEmpty()){
            return getRightsSet[0].Id;
        }
        else{
            return null;
        }
    }
    
    public class excelSheetWrapper{
        public String ApplicationType;	
        public Date ApplicationDate;	
        public String Applicant;	
        public String Jurisdiction;	
        public String ApplicantAddress;	
        public String Telephone;	
        public String VAT;	
        public string ApplicantContact;	
        public String ApplicantEmail;	
        public String SignatoryContact;	
        public String SignatoryEmail;	
        public string AccountsPayableContact;	
        public String AccountsPayableEmail;	
        public String CreativeContact;	
        public String CreativeContactEmail;	
        public string SubmissionsContact;	
        public String SubmissionsContactEmail;	
        public String property;	
        public String Territory;	
        public String distributionChannels;	
        public String Exclusivity;	
        public String CountryofProduction;	
        public String TargetDemographic;
        public Date TermLengthStart;
        public Date TermLengthEnd;	
        public Integer MinimumGuarantee;	
        public Integer Advance;	
        public String MGPaymentSchedule;	
        public Integer LATAM;
        public Integer NA;
        Public Integer ANZ;
        public Integer EMEA;
        public Decimal WholeSale;
        public Decimal RetailDirectToConsumer;
        public Decimal FOB;
        public Decimal OtherRoyaltyRate;
        public string DistributionChannelsOther;	
    }
    
    
    public static excelSheetWrapper parse(String json){
        return (excelSheetWrapper) System.JSON.deserialize(json, excelSheetWrapper.class);
    }
    
    
    }