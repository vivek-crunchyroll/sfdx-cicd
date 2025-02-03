@isTest
private class Email2LeadConfigurations_test {
    static testMethod void Email2LeadConfigurations_test() {
        string  CampaignID; 
        Boolean  AssignLeadtocampaignID; 
        Boolean  CheckforSourceNullvalues; 
        Boolean  CheckforStatusNullvalues; 
        Campaign Cn = new Campaign(Name = 'test Campaign');
        insert Cn;
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]; 
        User usr = new User(LastName = 'Abcd',
                            FirstName='efgh',
                            Alias = 'Mk',
                            Email = 'testuser@gmail.com',
                            Username = 'testE2luser@gmail.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US');
        Insert usr;
       System.debug('checking user id ' + usr.id); 
        E2Lcustomsettings e2lcust = new E2Lcustomsettings();
        e2lcust.strLeadStatus = 'New';
        e2lcust.strLeadsource = 'Inbound Email'; 
        e2lcust.Blockeddomains = 'gmail.com,yahoo.com';
        e2lcust.AllowDuplicates = true;
        e2lcust.AutoLeadOwnerAssignment = true;
        e2lcust.AutoLeadOwnerAssignmentNotification = false;
        e2lcust.LeadOwnerId_Queue = usr.id;
        e2lcust.CampaignID = cn.id;
        e2lcust.AssignLeadtocampaignID = true;
        e2lcust.Savesettings();
        campaign[] CM = [SELECT Id FROM campaign ];
        System.assertEquals (1,CM.size(),'Campaign is created');
    }
   
}