@isTest
private class EmailtoLead_test {
static testMethod void EmailtoLead_test() {
    Id contentDistributionRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Content_Distribution' AND SObjectType = 'Lead' LIMIT 1].Id;
	Messaging.InboundEmail email  = new Messaging.InboundEmail();
	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	email.plainTextBody = 'This should become a note Please provide  chair details information';
	email.fromAddress = 'Mythili.g333@etggs.com';
	email.subject = 'Intrested in chairs';
	email.fromName = 'FirstName lastName';
	Messaging.InboundEmail.binaryAttachment binaryAttachment = new Messaging.InboundEmail.binaryAttachment();
	binaryAttachment.Filename = 'test.pdf';
	binaryAttachment.body = blob.valueOf('my attachment text');
	email.binaryAttachments = new Messaging.InboundEmail.binaryAttachment[] {binaryAttachment};
	Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
	textAttachment.Filename = 'test.txt';
	textAttachment.body = 'my attachment text';
	email.textAttachments = new Messaging.InboundEmail.TextAttachment[] {textAttachment};   
		
		Lead l = new lead(firstName='John', 
						  lastName='Smith',
						  Company='Salesforce', 
						  Email='user@acme.com', 
						  HasOptedOutOfEmail=false,RecordTypeId = contentDistributionRecordTypeId);
	insert l;
	Campaign C = new Campaign(Name = 'test Campaign');
	insert C;
	ETLCS__C cs = new ETLCS__C();
	cs.Lead_Status__c = 'Open';
	cs.Lead_Source__c ='Inbound Email';
	cs.Blocked_Domains__c = 'Yahoo.com,outlook.com';
	cs.Allow_Duplicates__c = true;
	cs.Auto_Lead_Owner_Assignment__c = true;
	cs.Auto_Lead_Owner_Assignment_Notification__c = true;
	cs.Campaign_ID__c = C.Id;
	cs.Assign_Lead_to_campaign_ID__c = true;
	insert cs;
	
	Attachment attachment = new Attachment();
	attachment.Body = Blob.valueOf(' chairs');
	attachment.Name = String.valueOf('test.txt');
	attachment.ParentId = l.Id; 
	insert attachment;     
	Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
	efa.setFileName(attachment.Name);
	efa.setBody(attachment.Body);
	efa.setContentType(attachment.ContentType);
	List<CampaignMember> members = new List<CampaignMember>();
	CampaignMember cm = new CampaignMember(CampaignId = C.id,LeadId = l.Id);
	members.add(cm);
	
	insert members; 
	EmailToLead el = new EmailToLead();
	
	Test.startTest();
	Messaging.InboundEmailResult result = el.handleInboundEmail(email, env);
	Test.stopTest();
	
	System.assert (result.success, 'InboundEmailResult returned a failure message');
	
	Lead [] leadDb = [SELECT Id FROM Lead where Email=:email.FromAddress];
	System.assertEquals (1, leadDb.size(),'Lead was not inserted');
}

//
static testMethod void TB_Email_to_leadtestmethod() {
    Id contentDistributionRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Content_Distribution' AND SObjectType = 'Lead' LIMIT 1].Id;
	Messaging.InboundEmail email  = new Messaging.InboundEmail();
	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	email.plainTextBody = 'This should become a note Please provide takara chair details information';
	email.fromAddress = 'user@acme.com';
	email.subject = 'Intrested in  chairs';
	email.fromName = 'FirstName';
	Messaging.InboundEmail.binaryAttachment binaryAttachment = new Messaging.InboundEmail.binaryAttachment();
	binaryAttachment.Filename = 'test.pdf';
	binaryAttachment.body = blob.valueOf('my attachment text');
	email.binaryAttachments = new Messaging.InboundEmail.binaryAttachment[] {binaryAttachment};
	Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
	textAttachment.Filename = 'test.txt';
	textAttachment.body = 'my attachment text';
	email.textAttachments = new Messaging.InboundEmail.TextAttachment[] {textAttachment};   
		Lead l = new lead(firstName='John', 
						  lastName='Smith',
						  Company='Salesforce', 
						  Email='user@acme.com', 
						  HasOptedOutOfEmail=false,RecordTypeId = contentDistributionRecordTypeId);
	insert l;
	Campaign C = new Campaign(Name = 'test Campaign');
	insert C;
	Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]; 
	User usr = new User(LastName = 'Kurnool',
						FirstName='Mahaa',
						Alias = 'Mk',
						Email = 'kurnool.Mahaa@gmail.com',
						Username = 'kurnool.Mahaa@gmail.com',
						ProfileId = profileId.id,
						TimeZoneSidKey = 'GMT',
						LanguageLocaleKey = 'en_US',
						EmailEncodingKey = 'UTF-8',
						LocaleSidKey = 'en_US');
	
	ETLCS__C cs = new ETLCS__C();
	cs.Lead_Status__c = 'Open';
	cs.Lead_Source__c ='Inbound Email';
	cs.Blocked_Domains__c = 'Yahoo.com,outlook.com';
	cs.Allow_Duplicates__c = false;
	cs.Auto_Lead_Owner_Assignment__c = false;
	cs.Auto_Lead_Owner_Assignment_Notification__c = false;
	cs.Lead_Owner_Id__c  = usr.id;
	cs.Assign_Lead_to_campaign_ID__c = false;
	cs.Campaign_ID__c = C.Id;
	cs.Assign_Lead_to_campaign_ID__c = true;
	insert cs;            
	Attachment attachment = new Attachment();
	attachment.Body = Blob.valueOf('Intrested in chairs');
	attachment.Name = String.valueOf('test.txt');
	attachment.ParentId = l.Id; 
	insert attachment;     
	Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
	efa.setFileName(attachment.Name);
	efa.setBody(attachment.Body);
	efa.setContentType(attachment.ContentType);
	EmailToLead el = new EmailToLead(); 
	Test.startTest();
	Messaging.InboundEmailResult result = el.handleInboundEmail(email, env);
	Test.stopTest();
	System.assert (result.success, 'InboundEmailResult returned a failure message');
	Lead [] leadDb = [SELECT Id FROM Lead where Email=:email.FromAddress];
	System.assertEquals (1, leadDb.size(),'Lead was not inserted');
}

static testMethod void TB_Email_to_leadtestmethodnew() {
    Id contentDistributionRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Content_Distribution' AND SObjectType = 'Lead' LIMIT 1].Id;
	Messaging.InboundEmail email  = new Messaging.InboundEmail();
	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	email.plainTextBody = 'This should become a note Please provide chair details information';
	email.fromAddress = 'Mythili.g376@etggs.com';
	email.subject = 'Intrested in chairs';
	Messaging.InboundEmail.binaryAttachment binaryAttachment = new Messaging.InboundEmail.binaryAttachment();
	binaryAttachment.Filename = 'test.pdf';
	binaryAttachment.body = blob.valueOf('my attachment text');
	email.binaryAttachments = new Messaging.InboundEmail.binaryAttachment[] {binaryAttachment};
	Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
	textAttachment.Filename = 'test.txt';
	textAttachment.body = 'my attachment text';
	email.textAttachments = new Messaging.InboundEmail.TextAttachment[] {textAttachment};   
		
		Lead l = new lead(firstName='John', 
						  lastName='Smith',
						  Company='Salesforce', 
						  Email='user@acme.com', 
						  HasOptedOutOfEmail=false,RecordTypeId = contentDistributionRecordTypeId);
	insert l;
	
	ETLCS__C cs = new ETLCS__C();
	cs.Lead_Status__c = 'Open';
	cs.Lead_Source__c ='Inbound Email';
	cs.Blocked_Domains__c = 'Yahoo.com,outlook.com';
	cs.Allow_Duplicates__c = True;
	cs.Auto_Lead_Owner_Assignment__c = false;
	cs.Auto_Lead_Owner_Assignment_Notification__c = false; 
	insert cs;
	
	Attachment attachment = new Attachment();
	attachment.Body = Blob.valueOf('intrested in chairs');
	attachment.Name = String.valueOf('test.txt');
	attachment.ParentId = l.Id; 
	insert attachment;     
	Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
	efa.setFileName(attachment.Name);
	efa.setBody(attachment.Body);
	efa.setContentType(attachment.ContentType);
	EmailToLead el = new EmailToLead();
	String CampaignID;
	String LeadId; 
	Test.startTest();
	Test.stopTest();
	Lead [] leadDb = [SELECT Id FROM Lead where Email=:email.FromAddress];
	System.assertEquals (0, leadDb.size(),'Lead was not inserted');
}

}