public class LicensorReviewcomponentController {
    public Opportunity opp { get; set; }
    public List<OpportunityLineItem> lineItems { get; set; }
    public String startDateFormatted { get; set; }
    public String endDateFormatted { get; set; }
    
    private string opportunityId;
    
    public string getOpportunityId() {
        return opportunityId;
    }

    public void setOpportunityId(String oppId) {
        opportunityId = oppId;
        getOpps();
        
    }
    
    
    public void getOpps() {
        opp = new Opportunity();
        lineItems = new List<OpportunityLineItem>();
        System.debug(opportunityId);
        List<Opportunity> getOpp = [SELECT Id,Name, Account.Name, ContactId,Distribution_Channels__c, MG_Payment_Schedule__c, Contract_Term_Start__c,Contract_Term_End__c,Royalty_Rate__c,	Applicant_Contact__c,Owner.Name,FOB__c,Wholesale__c,Retail_Direct_To_Consumer__c,Other_Royalty_Rate__c,Country_of_Production__c,Territory__c,Property_Description__c,Exclusivity__c,Minimum_Guarantee__c
               FROM Opportunity 
               WHERE Id = :opportunityId 
               LIMIT 1];
        
        if(!getOpp.isEmpty()){
            opp = getOpp[0];
        }
        
        system.debug('opp:::'+opp);
        
        if (opp.Id != null){
            List<OpportunityLineItem> getItems = [SELECT Id, Name,Product2.Name from OpportunityLineItem where OpportunityId=: opp.Id];
            if(!getItems.isEmpty()){
                lineItems = getItems;
            }
        }
          if (opp.Contract_Term_Start__c != null) {
            
            DateTime startDateTime = DateTime.newInstance(opp.Contract_Term_Start__c, Time.newInstance(0, 0, 0, 0));
            startDateFormatted = startDateTime.format('MM/dd/yyyy');
        }
        
        if (opp.Contract_Term_End__c != null) {
            
            DateTime endDateTime = DateTime.newInstance(opp.Contract_Term_End__c, Time.newInstance(0, 0, 0, 0));
            endDateFormatted = endDateTime.format('MM/dd/yyyy');
        }
    }
}