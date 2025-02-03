@isTest
public class TerritoryAssignmentControllerTest {
    
    @testSetup
    private static void createMasterTerritories(){
        //Data Setup for Master Territory
        Master_Territory__c m1 = new Master_Territory__c();
        m1.Name = 'World';
        insert m1;
        
        List<Master_Territory__c> worldSubTerritories = new List<Master_Territory__c>();
        Master_Territory__c m2 = new Master_Territory__c();
        m2.Name = 'Americas';
        m2.Parent_Territory__c = m1.Id;
        worldSubTerritories.add(m2);
        
        Master_Territory__c m3 = new Master_Territory__c();
        m3.Name = 'Asia';
        m3.Parent_Territory__c = m1.Id;
        worldSubTerritories.add(m3);        
        
        Master_Territory__c m4 = new Master_Territory__c();
        m4.Name = 'Europe';
        m4.Parent_Territory__c = m1.Id;
        worldSubTerritories.add(m4);
        insert worldSubTerritories;
        
        Master_Territory__c m5 = new Master_Territory__c();
        m5.Name = 'India';
        m5.Parent_Territory__c = m3.Id;
        insert m5;
        
        String consumerProductsRecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('Consumer_Products').getRecordTypeId();
        String licenseeRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Licensee').getRecordTypeId();
        String rightsOutRecordTypeId = Schema.getGlobalDescribe().get('Rights_Set__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Rights_Out').getRecordTypeId();
        
        Account acc = new Account();
        acc.RecordTypeId = licenseeRecordTypeId;
        acc.Name = 'ABC Wholesale Company';
        insert acc;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update pb;
        
        Product2 product = new Product2();
        product.Name = 'Chainsaw Series Season 01';
        product.IsActive = true;
        product.Rightsline_ID__c = '12341';
        insert product;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = product.Id;
        pbe.UnitPrice = 0.01;
        insert pbe;
        
        //Create a Deal
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = consumerProductsRecordTypeId;
        opp.Name = 'Chainsaw Series Season 01';
        opp.AccountId = acc.Id;
        opp.StageName = 'Pending Deal Memo';
        opp.CloseDate = Date.today().addDays(30);
        opp.Pricebook2Id = Test.getStandardPricebookId();
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.Product2Id = product.Id;
        oli.OpportunityId = opp.Id;
        //insert oli;
        
        Rights_Set__c rights = new Rights_Set__c();
        rights.RecordTypeId = rightsOutRecordTypeId;
        rights.Deal__c = opp.Id;
        insert rights;
        
        CP_Territory__c territory = new CP_Territory__c();
        territory.Name = 'India';
        territory.Rights_Set__c = rights.Id;
        territory.Master_Territory__c = m5.Id;
        insert territory;        
    }
    
    @isTest
    private static void getTerritoryHierarchyTest(){
        List<Opportunity> opps = [Select Id From Opportunity Limit 1];
        if(!opps.isEmpty()){
            TerritoryAssignmentController.getTerritoryHierarchy(opps[0].Id);
            Master_Territory__c getIndiaTerritory = [Select Id From Master_Territory__c Where Name = 'India' Limit 1];
            Master_Territory__c getAmericasTerritory = [Select Id From Master_Territory__c Where Name = 'World' Limit 1];
            TerritoryAssignmentController.assignTerritories(new List<String>{getAmericasTerritory.Id}, new List<String>{getIndiaTerritory.Id}, opps[0].Id);
        }
    }
}