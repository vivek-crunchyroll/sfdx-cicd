@isTest
public class OpportunityLineItemHandlerTest {  
    @testSetup static void setup() {
        RecordType contentDistributionRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Content_Distribution'AND SObjectType = 'Opportunity' LIMIT 1];
        List<Account> Accts = new List<Account>();
        for(Integer i=0;i<2;i++) {
            Accts.add(new Account(Name = 'TestAcct'+i));
        }
        insert Accts; 
        
        Date myDate = Date.newInstance(2023,9, 5);
        List<Opportunity> Opps = new List<Opportunity>();
        for(Integer i=0;i<2;i++) {
            Opps.add(new Opportunity(Name = 'TestOpps'+i,AccountId = Accts[0].id, StageName = 'In Take',CloseDate = myDate,RecordTypeId = contentDistributionRecordType.Id));
        }
        insert Opps; 
        
        
        
        List<Product2> Pro =new List<Product2>();
        for(Integer i=0;i<2;i++) {
            Pro.add(new Product2(Name = 'Head set'+i, IsActive = true,Rightsline_ID__c = 'RL-' + i));
        }
        insert Pro;
        
        List<Pricebook2> PB2 =new List<Pricebook2>();
        for(Integer i=0;i<2;i++) {
            PB2.add(new Pricebook2(Name = 'Test Pricebook'+i, IsActive =true));
        }
        insert PB2;
        
        List<PricebookEntry> PBE =new List<PricebookEntry>();       
        PBE.add(new PricebookEntry(Pricebook2Id =Test.getStandardPricebookId(), Product2Id = Pro[0].Id,UnitPrice = 10000,IsActive = true,UseStandardPrice = false));
        insert PBE;
        
        List<OpportunityLineItem> OLI = new List<OpportunityLineItem>();
        for(Integer i=0;i<2;i++) {
            OLI.add(new OpportunityLineItem(OpportunityId =Opps[0].id,Product2Id =Pro[0].id,PriceBookEntryId =PBE[0].id, Territories_Requested__c = 'Algeria;American Samoa'));
        }
        insert OLI; 
    }        
    @isTest 
    static void testOnInsert() {
        Account acc1 = [SELECT Id FROM Account WHERE Name='TestAcct0' LIMIT 1];
        Opportunity Opp1 = [SELECT Id FROM Opportunity WHERE Name='TestOpps0' LIMIT 1];
        OpportunityLineItem OLI1 = [SELECT Id,Name,Territories_Requested__c,OpportunityId,Product2Id,PriceBookEntryId,Deal_Record_Type__c FROM OpportunityLineItem LIMIT 1];
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{OLI1};           
            Test.startTest();
        OpportunityLineItemHandler.onInsert(oliList);
        Test.stopTest(); 

        List<Territory__c> territories = [SELECT Id FROM Territory__c WHERE Deal_Title_del__c = : OLI1.Id];
       
        
    }
    
    @isTest
    static void testOnUpdate() {
        Account acc1 = [SELECT Id FROM Account WHERE Name='TestAcct0' LIMIT 1];
        Opportunity Opp1 = [SELECT Id,Name FROM Opportunity WHERE Name='TestOpps0' LIMIT 1];
        
        OpportunityLineItem OLI1 = [SELECT Id,Name,Territories_Requested__c,OpportunityId,Product2Id,PriceBookEntryId,Deal_Record_Type__c FROM OpportunityLineItem LIMIT 1];
        
        OLI1.Territories_Requested__c = 'Austria';
        update OLI1;
        
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{OLI1};                
            Test.startTest();
        OpportunityLineItemHandler.onUpdate(oliList);
        Test.stopTest();

        List<Territory__c> territories = [SELECT Id FROM Territory__c WHERE Deal_Title_del__c = :OLI1.Id];
        
    }
    
    @isTest
    static void testOnDelete() {
        Account acc1 = [SELECT Id FROM Account WHERE Name='TestAcct0' LIMIT 1];
        Opportunity Opp1 = [SELECT Id FROM Opportunity WHERE Name='TestOpps0' LIMIT 1];
        OpportunityLineItem OLI1 = [SELECT Id,Name,Territories_Requested__c,OpportunityId,Product2Id,PriceBookEntryId,Deal_Record_Type__c FROM OpportunityLineItem LIMIT 1];
        
        List<OpportunityLineItem> deletedOliList = new List<OpportunityLineItem>{OLI1};             
            Test.startTest();
        OpportunityLineItemHandler.onDelete(deletedOliList);
        delete deletedOliList;
        Test.stopTest();

        List<Territory__c> territories = [SELECT Id FROM Territory__c WHERE Deal_Title_del__c = :OLI1.Id];
        
    }
}