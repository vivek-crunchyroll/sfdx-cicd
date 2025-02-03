global class EmailToLead implements Messaging.InboundEmailHandler {
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
														   Messaging.InboundEnvelope env)
	{
		
		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
		String Fname;
		String Lname;
		String companyName;
		String[] cname;
		String strLeadStatus;  
		String strLeadsource;
		String Blockeddomains;
		String[] lstbd;
		String Stremaildomain;
		Boolean Blockeddomainsfound;
		Boolean AllowDuplicates;
		Boolean AutoLeadOwnerAssignment;
		String LeadOwnerId;
		Lead newLead = new Lead();
		Lead dupeLead;
		String strCampaignId;
		Boolean AssignLeadtoCampaignID;
		List<Lead> lstdupleads = new List<Lead>();
		ETLCS__C cs = ETLCS__C.getOrgDefaults();
		Blockeddomains = cs.Blocked_Domains__c;
		AutoLeadOwnerAssignment = cs.Auto_Lead_Owner_Assignment__c ; 
		LeadOwnerId = cs.Lead_Owner_Id__c;
		strCampaignId = cs.Campaign_ID__c;
		AssignLeadtoCampaignID = cs.Assign_Lead_to_campaign_ID__c;
        
        Id contentDistributionRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Content_Distribution' AND SObjectType = 'Lead' LIMIT 1].Id;
        
		String[] Emailaddress = email.fromAddress.split('@');
		cname = Emailaddress[1].split('\\.');
		Stremaildomain = Emailaddress[1];
		if(email.fromName != null){
		String[] FullName = email.fromName.split(' ');    
        system.debug('FullName :'+FullName);    
		if(FullName.size()==2){
				Fname = FullName[0];
				Lname = FullName[1];  
				CompanyName = cname[0]; 
			}
			else{
                Fname = FullName[0];
                if(FullName.size()==2){
				Lname = FullName[1];
                }
                else{
                  Lname = FullName[0];  
                }
                //Lname = FullName[0];
				companyName = cname[0];  
			}
		}
		else{
			if(Emailaddress[0].contains('\\.')){
				String[] LeadName = Emailaddress[0].split('\\.'); 
				Fname = LeadName[0];
				Lname = LeadName[1];  
				
			}
			else{
				Lname = Emailaddress[0];  
			}
		}
		
		if(!AutoLeadOwnerAssignment){
			newLead.Email = Email.fromAddress;
			newLead.FirstName = Fname;
			newLead.LastName = Lname;
			newLead.Company = companyName;
			newLead.Description = email.subject;
			newLead.Status = cs.Lead_Status__c ;
			newLead.LeadSource = cs.Lead_Source__c;
            newLead.RecordTypeId = contentDistributionRecordTypeId;
		}
		else {
			if(LeadOwnerId != NULL){
				newLead.Email = email.fromAddress;
				newLead.FirstName = Fname;
				newLead.LastName = Lname;
				newLead.Company = companyName;
				newLead.Description = email.subject;
				newLead.Status = cs.Lead_Status__c ;
				newLead.LeadSource = cs.Lead_Source__c; 
				newLead.OwnerId = LeadOwnerId;
                newLead.RecordTypeId = contentDistributionRecordTypeId;
			}
			else{
				newLead.Email = email.fromAddress;
				newLead.FirstName = Fname;
				newLead.LastName = Lname;
				newLead.Company = companyName;
				newLead.Description = email.subject;
				newLead.Status = cs.Lead_Status__c ;
				newLead.LeadSource = cs.Lead_Source__c;
                newLead.RecordTypeId = contentDistributionRecordTypeId;
				
			}
		}
		lstdupleads = [select email from lead where email =: email.fromAddress AND RecordTypeId = :contentDistributionRecordTypeId order by Createddate desc];
		if(lstdupleads.size()>0){
			dupeLead = lstdupleads[0];  
		}
		if (cs.Allow_Duplicates__c){
			if (lstdupleads.size()==0)
			{
				AllowDuplicates = true;
			}
			else if(lstdupleads.size()>0)
			{
				AllowDuplicates = true;
			}
		}
		else if(!cs.Allow_Duplicates__c)
		{
			if (lstdupleads.size()==0)
			{
				AllowDuplicates = true;
			}
			else if(lstdupleads.size()>0)
			{
				AllowDuplicates = false;
			}
		}
		System.debug('New Lead record: ' + newLead );  
		System.debug('cs.Blocked_Domains__c : ' + cs.Blocked_Domains__c ); 
		if(cs.Blocked_Domains__c != NULL && cs.Blocked_Domains__c !=''){
			lstbd = Blockeddomains.split(',');
			System.debug('lstbd : ' + lstbd ); 
			if(lstbd.contains(Stremaildomain)){
				Blockeddomainsfound = true;
			}
			else{
				Blockeddomainsfound = false;  
			}
		}
		else
		{
			Blockeddomainsfound = false;  
		}
		System.debug('Blockeddomainfound: ' + Blockeddomainsfound ); 
		if (AllowDuplicates){
			   if(!Blockeddomainsfound){  
				Database.SaveResult sr = Database.insert(newLead, false);
				if (!sr.isSuccess()) {
					for(Database.Error duplicateError : sr.getErrors()){
						Datacloud.DuplicateResult duplicateResult = 
							((Database.DuplicateError)duplicateError).getDuplicateResult();
						System.debug('Duplicate records have been detected by ' +  duplicateResult.getDuplicateRule());
						System.debug(duplicateResult.getErrorMessage());
					}
					Database.DMLOptions dml = new Database.DMLOptions(); 
					dml.DuplicateRuleHeader.AllowSave = true;
					Database.SaveResult sr2 = Database.insert(newLead, dml);
					if (sr2.isSuccess()) {
						System.debug('Duplicate account has been inserted in Salesforce!');
					}
				} 
				if(email.plainTextBody!= null && newLead.id !=null){ // && newLead.id !=null
					Attachment plaintextattachment = new Attachment();
					plaintextattachment.Name = 'Email from '+email.fromAddress+'.txt';                                            
					plaintextattachment.Body = Blob.valueOf(email.plainTextBody) ;                                          
					plaintextattachment.ParentId = newLead.Id;
					insert plaintextattachment; 
				} 
				if(email.textAttachments != null) {
					if(email.textAttachments.size() > 0){
						for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
							Attachment attachment = new Attachment();
							attachment.Name = tAttachment.fileName;
							attachment.Body = Blob.valueOf(tAttachment.body);
							attachment.ParentId = newLead.Id;
							insert attachment;
							System.debug('attachment successfully attached to the Lead');
						}            
					}
				}
		  
				if (email.binaryAttachments != NULL) {
					if(email.binaryAttachments.size() > 0){
						for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
							Attachment attachment = new Attachment();
							attachment.Name = bAttachment.fileName;
							attachment.Body = bAttachment.body;
							attachment.ParentId = newLead.Id;
							insert attachment; 
						}
					}
					
				}
				
		   } 
			 
			if(!Blockeddomainsfound && cs.Assign_Lead_to_campaign_ID__c == true ){
				List<CampaignMember> members = new List<CampaignMember>();
				CampaignMember cm = new CampaignMember(CampaignId = strCampaignId,LeadId = newLead.Id);
				members.add(cm);
				insert members;  
			}
			else{
			}
		
		} 
		
		else {
			if(email.plainTextBody!= null){
				Attachment plaintextattachment = new Attachment();
				plaintextattachment.Name = 'Email from '+email.fromAddress+'.txt';                                            
				plaintextattachment.Body = Blob.valueOf(email.plainTextBody) ;                                          
				plaintextattachment.ParentId = dupeLead.Id;
				insert plaintextattachment; 
			} 
			
			if(email.textAttachments != null) {
				if(email.textAttachments.size() > 0){
					for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
						Attachment attachment = new Attachment();
						attachment.Name = tAttachment.fileName;
						attachment.Body = Blob.valueOf(tAttachment.body);
						attachment.ParentId = dupeLead.Id;
						insert attachment;
						System.debug('attachment successfully attached to the Lead');
					}            
				}
			}
		
			if (email.binaryAttachments != NULL) {
				if(email.binaryAttachments.size() > 0){
					for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
						Attachment attachment = new Attachment();
						attachment.Name = bAttachment.fileName;
						attachment.Body = bAttachment.body;
						attachment.ParentId = dupeLead.Id;
						insert attachment; 
					}
				}
				
			}
			if(!Blockeddomainsfound && cs.Assign_Lead_to_campaign_ID__c == true ){
				List<CampaignMember> members = new List<CampaignMember>();
				CampaignMember cm = new CampaignMember(CampaignId = strCampaignId,LeadId = dupeLead.Id);
				members.add(cm);
				insert members;  
			}
			else{
			}
		
		}
		result.success = true;          
		return result;
	}  

}