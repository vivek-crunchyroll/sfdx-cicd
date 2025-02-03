@isTest
public class TestDeleteTerritoryBasedonDeal {
    static testMethod void testDeleteTerritoryBasedonDeal() {
        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;
        Date myDate = Date.newInstance(2023, 9, 5);
        
        RecordType contentDistributionRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Content_Distribution'AND SObjectType = 'Opportunity' LIMIT 1];
        
        Opportunity Opp =new Opportunity();
        Opp.Name = 'Test Deal';
        Opp.AccountId = acc.Id;
        Opp.StageName = 'In Take';
        Opp.Licensor_Approved__c =true;
        Opp.CloseDate = myDate; 
        opp.RecordTypeId = contentDistributionRecordType.Id;
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', StageName = 'In Take',Licensor_Approved__c = true, CloseDate = Date.today(),RecordTypeId = contentDistributionRecordType.Id);
        insert testOpp;
        
        Product2 Pro = new Product2(Name = 'Head set',IsActive = true);
        insert Pro;
        system.assertEquals(Pro.Name,'Head set'); 
        
        Pricebook2 PB2 = new Pricebook2(Name = 'Test Pricebook', IsActive =true);
        insert PB2;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id =Test.getStandardPricebookId();
        standardPrice.Product2Id = Pro.Id;
        standardPrice.UnitPrice = 10000;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice;

        OpportunityLineItem OLI = new OpportunityLineItem();
        OLI.OpportunityId = Opp.Id; 
        OLI.Territories_Requested__c = 'Algeria;American Samoa'; 
        OLI.PricebookEntryId = standardPrice.id;
        OpportunityLineItem testOppLineItem = new OpportunityLineItem(OpportunityId = testOpp.Id,PricebookEntryId = standardPrice.id, Quantity = 1);
        insert testOppLineItem;

        delete testOpp;
        Test.startTest();
        List<OpportunityLineItem> deletedOliList = new List<OpportunityLineItem>();
         OpportunityLineItemHandler.onDelete(deletedOliList);
        Test.stopTest();
    }
}