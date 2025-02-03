global with sharing class E2Lcustomsettings {
public   string  strLeadStatus {get;set;}
public   string strLeadsource {get;set;}   
public   string Blockeddomains{get;set;}
public   Boolean  AllowDuplicates {get;set;}
public   Boolean  AutoLeadOwnerAssignment{get;set;}
public   Boolean  AutoLeadOwnerAssignmentNotification {get;set;}
public   string  LeadOwnerId_Queue {get;set;}
public   string  CampaignID {get;set;}
public   Boolean  AssignLeadtocampaignID {get;set;}
public   Boolean  CheckforSourceNullvalues = False;
public   Boolean  CheckforStatusNullvalues = False;
Public   Boolean  checkforcampaignIdNullvalues = False;
Public   Boolean  checkforLeadownerIDNullvalues = False;
Public   Boolean  checkforLeadownerID_QueueNullvalues = False; 
Public   Boolean  checkforcampaignId_QueueNullvalues = false;
Public String Savesettings {get;set;}
ETLCS__C cs = ETLCS__C.getOrgDefaults();
Public E2Lcustomsettings(){   
	strLeadStatus = cs.Lead_Status__c;
	strLeadsource = cs.Lead_Source__c;
	LeadOwnerId_Queue = cs.Lead_Owner_Id__c;
	Blockeddomains = cs.Blocked_Domains__c;
	AutoLeadOwnerAssignment = cs.Auto_Lead_Owner_Assignment__c;
	Allowduplicates = cs.Allow_Duplicates__c;
	AutoLeadOwnerAssignmentNotification = cs.Auto_Lead_Owner_Assignment_Notification__c; 
	CampaignID = cs.Campaign_ID__c;
	AssignLeadtocampaignID = cs.Assign_Lead_to_campaign_ID__c;  
}  

Public void Savesettings(){
	
   if(strLeadStatus == '' || strLeadStatus == null){
	   ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter Lead Status Value'));
	   CheckforStatusNullvalues = true;
	}
	else{
	 CheckforStatusNullvalues = false;   
	}
  
	if ((CampaignID == '' ||  CampaignID == null ) && AssignLeadtocampaignID == true ){
	 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter Campaign ID Value'));
	  checkforcampaignIdNullvalues = true;  
	}
	 else{
	 checkforcampaignIdNullvalues = false;   
	}
	if (CampaignID.length() > 0 &&  AssignLeadtocampaignID == false){
	   System.debug('Campaign id value' + CampaignID );
		System.debug('Campaign id value size' + CampaignID.Length());
		
	 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select Assign Lead to CampaignId checkbox'));
	  checkforcampaignId_QueueNullvalues = true; 
	}
	 else{
	 checkforcampaignId_QueueNullvalues = false;   
	}
	if((LeadOwnerId_Queue == '' || LeadOwnerId_Queue == null) && AutoLeadOwnerAssignment == true ){
	 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter LeadOwner Id / Queue Value'));
	  checkforLeadownerID_QueueNullvalues = true;
	}
	 else{
	 checkforLeadownerID_QueueNullvalues = false;   
	}
	  if(LeadOwnerId_Queue.length()>0 && AutoLeadOwnerAssignment == false  ){
	   System.debug('LeadOwnerId_Queue value' + LeadOwnerId_Queue );
	   System.debug('LeadOwnerId_Queue value Size ' + LeadOwnerId_Queue.length());
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select Auto Lead Owner Assignment checkbox'));
	   checkforLeadownerIDNullvalues = true; 
	}  
	 else{
	 checkforLeadownerIDNullvalues = false;   
	} 
	   
if( strLeadsource == '' ||  strLeadsource == null){
   ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter Lead Source Value'));
	   CheckforSourceNullvalues = true;
   }
   else
		{
			CheckforSourceNullvalues = false;
		} 

	
	if ((CheckforStatusNullvalues == false) && (CheckforSourceNullvalues == false) && (checkforcampaignIdNullvalues == false) && (checkforLeadownerIDNullvalues == false) &&(checkforLeadownerID_QueueNullvalues == false) && (checkforcampaignId_QueueNullvalues ==false) )
	{        
		if(schema.SObjectType.ETLCS__C.fields.Lead_Status__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Lead_Status__c.iscreateable()){
			cs.Lead_Status__c = strLeadStatus;
		}
		if(schema.SObjectType.ETLCS__C.fields.Lead_Source__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Lead_Source__c.iscreateable()){
			cs.Lead_Source__c = strLeadsource;
		}
		if(schema.SObjectType.ETLCS__C.fields.Lead_Owner_Id__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Lead_Owner_Id__c	.iscreateable()){
			cs.Lead_Owner_Id__c = LeadOwnerId_Queue ;
		}
		if(schema.SObjectType.ETLCS__C.fields.Blocked_Domains__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Blocked_Domains__c.iscreateable()){
			cs.Blocked_Domains__c = Blockeddomains;
		}
		if(schema.SObjectType.ETLCS__C.fields.Auto_Lead_Owner_Assignment__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Auto_Lead_Owner_Assignment__c.iscreateable()){
			cs.Auto_Lead_Owner_Assignment__c = AutoLeadOwnerAssignment;
		}
		if(schema.SObjectType.ETLCS__C.fields.Allow_Duplicates__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Allow_Duplicates__c.iscreateable()){
			cs.Allow_Duplicates__c =  Allowduplicates;
		}
		if(schema.SObjectType.ETLCS__C.fields.Auto_Lead_Owner_Assignment_Notification__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Auto_Lead_Owner_Assignment_Notification__c.iscreateable()){
			cs.Auto_Lead_Owner_Assignment_Notification__c =AutoLeadOwnerAssignmentNotification; 
		}
		if(schema.SObjectType.ETLCS__C.fields.Campaign_ID__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Campaign_ID__c.iscreateable()){
			cs.Campaign_ID__c = CampaignID;
		}
		if(schema.SObjectType.ETLCS__C.fields.Assign_Lead_to_campaign_ID__c.isupdateable() && schema.SObjectType.ETLCS__C.fields.Assign_Lead_to_campaign_ID__c.iscreateable()){
			cs.Assign_Lead_to_campaign_ID__c = AssignLeadtocampaignID;  
		}
		if(schema.SObjectType.ETLCS__C.isupdateable() && schema.SObjectType.ETLCS__C.iscreateable() ){
			Upsert cs;
		}
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Values Saved successfully!')); 
	}

}

}