public without sharing class TerritoryAssignmentController {

    public static Map<Id, Id> getExistingTerritories(String recordId) {
        String rightOutRecordTypeId = Schema.getGlobalDescribe().get('Rights_Set__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Rights_Out').getRecordTypeId();
        Map<Id, Id> existingTerritoryIds = new Map<Id, Id>();
        for(CP_Territory__c territory : [Select Id, Master_Territory__c From CP_Territory__c Where Rights_Set__r.Deal__c =: recordId]){
            existingTerritoryIds.put(territory.Master_Territory__c, territory.Id);
        }
        return existingTerritoryIds;
    }

    public static Map<String, Set<Id>> getAvailableRights(String recordId){
        List<OpportunityLineItem> getTheTitle = [Select Id, Product2Id From OpportunityLineItem Where OpportunityId =: recordId Limit 1];
        if(!getTheTitle.isEmpty()){
            String productId = getTheTitle[0].Product2Id;

            Set<Id> oppsMightHaveRightsIn = new Set<Id>();
            Set<Id> oppsMightHaveRightsOut = new Set<Id>();
            for(OpportunityLineItem oli : [Select Id, OpportunityId, Opportunity.RecordType.DeveloperName From OpportunityLineItem Where Product2Id =: productId AND OpportunityId !=: recordId]){
                if(oli.Opportunity.RecordType.DeveloperName == 'Content_Distribution'){
                    oppsMightHaveRightsIn.add(oli.OpportunityId);
                }
                else if(oli.Opportunity.RecordType.DeveloperName == 'Consumer_Products'){
                    oppsMightHaveRightsOut.add(oli.OpportunityId);
                }
            }

            List<CP_Territory__c> territories = [Select Id, Name, Deal__r.Name, Master_Territory__c, Rights_Set__r.RecordType.DeveloperName From CP_Territory__c Where Deal__c IN: oppsMightHaveRightsIn OR Deal__c IN: oppsMightHaveRightsOut ORDER BY Rights_Set__r.RecordType.DeveloperName ASC];
            Set<Id> territoriesAvailableSet = new Set<Id>();
            Set<Id> territoriesNotAvailabeSet = new Set<Id>();
            
            for(CP_Territory__c territory : territories){
                if(territory.Rights_Set__r.RecordType.DeveloperName == 'Rights_In'){
                    territoriesAvailableSet.add(territory.Master_Territory__c);
                }
                else if(territory.Rights_Set__r.RecordType.DeveloperName == 'Rights_Out'){
                    territoriesNotAvailabeSet.add(territory.Master_Territory__c);
                }
            }

            Map<String, Set<Id>> rightsWithTerritoryIds = new Map<String, Set<Id>>();
            if(!territoriesAvailableSet.isEmpty()){
                rightsWithTerritoryIds.put('Rights_In', territoriesAvailableSet);
            }
            if(!territoriesNotAvailabeSet.isEmpty()){
                rightsWithTerritoryIds.put('Rights_Out', territoriesNotAvailabeSet);
            }
            return rightsWithTerritoryIds;
        }
        return new Map<String, Set<Id>>();
    }
    
    @AuraEnabled(cacheable=false)
    public static List<TerritoryHierarchy> getTerritoryHierarchy(String recordId) {
        // Get Existing Territories
        Map<Id, Id> existingTerritoryIds = getExistingTerritories(recordId);
        
        //Get Available Territories
        Set<Id> territoriesAvailableSet = new Set<Id>();
        Set<Id> territoriesNotAvailabeSet = new Set<Id>();
        Map<String, Set<Id>> rightsWithTerritoryIds = getAvailableRights(recordId);
        if(rightsWithTerritoryIds.containsKey('Rights_In') && rightsWithTerritoryIds.get('Rights_In') != null){
            territoriesAvailableSet.addAll(rightsWithTerritoryIds.get('Rights_In'));
        }
        if(rightsWithTerritoryIds.containsKey('Rights_Out') && rightsWithTerritoryIds.get('Rights_Out') != null){
            territoriesNotAvailabeSet.addAll(rightsWithTerritoryIds.get('Rights_Out'));
        }
        // Query Master_Territory__c and its relationships
        List<Master_Territory__c> territories = [SELECT Id, Name, Parent_Territory__c, Parent_Territory__r.Name FROM Master_Territory__c ORDER BY Parent_Territory__r.Name DESC];

        // Create a map to hold territories by their Id
        Map<String, TerritoryHierarchy> territoryMap = new Map<String, TerritoryHierarchy>();

        // Loop through the territories to build territory objects
        for (Master_Territory__c territory : territories) {
            //If no Rights_In information is provided, all territories will be available. However, if Rights_In information is available, only the specified territories will be enabled, and the rest will be disabled on the UI. 
            //Additionally, if the same title has Rights_Out as part of a different deal, the corresponding territories will also be disabled on the UI.
            Boolean disabled = (territoriesAvailableSet.isEmpty() && territoriesNotAvailabeSet.isEmpty()) ? false : (!territoriesAvailableSet.contains(territory.Id) ? true : (territoriesNotAvailabeSet.contains(territory.Id) ? true : false));
            // Create a TerritoryHierarchy object
            TerritoryHierarchy territoryHierarchy = new TerritoryHierarchy(territory.Id, territory.Name, existingTerritoryIds.containsKey(territory.Id), disabled);
            territoryMap.put(territory.Id, territoryHierarchy);
        }
        
        // Now, link children to their respective parent territories
        List<TerritoryHierarchy> rootTerritories = new List<TerritoryHierarchy>();
        

        for (Master_Territory__c territory : territories) {
            TerritoryHierarchy territoryHierarchy = territoryMap.get(territory.Id);
            territoryHierarchy.isExpanded = true;
            territoryHierarchy.iconName = 'utility:chevrondown';
            
            // If there's a parent, assign this territory as a child of the parent
            if (territory.Parent_Territory__c != null) {
                TerritoryHierarchy parentTerritory = territoryMap.get(territory.Parent_Territory__c);
                if(territoryHierarchy.checked){
                    parentTerritory.isExpanded = true;
                    parentTerritory.iconName = 'utility:chevrondown';
                }
                else{
                    parentTerritory.isExpanded = false;
                    parentTerritory.iconName = 'utility:chevronright';
                }
                if (parentTerritory != null) {
                    parentTerritory.children.add(territoryHierarchy);
                }
            } else {
                // If there's no parent, this is a root territory
                rootTerritories.add(territoryHierarchy);
            }
        }

        for(TerritoryHierarchy th : rootTerritories){
            th.isExpanded = true;
            th.iconName = 'utility:chevrondown';
        }
        
        // Return the root level territories, which will have the full hierarchy
        return rootTerritories;
    }

    @AuraEnabled(cacheable=false)
    public static String assignTerritories(List<String> selectedTerritoryIds, List<String> removedTerritoryIds, String recordId){
        System.debug('removedTerritoryIds ::: '+removedTerritoryIds);
        Rights_Set__c rights = new Rights_Set__c();
        rights.Id = checkExistingIfAny(recordId);
        rights.Name = 'Rights Out';
        rights.Deal__c = recordId;
        rights.RecordTypeId = Schema.getGlobalDescribe().get('Rights_Set__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Rights_Out').getRecordTypeId();
        upsert rights;

        Map<Id, String> territoryWithName = new Map<Id, String>();
        Map<Id, List<Master_Territory__c>> territoryIdWithSubTerritories = new Map<Id, List<Master_Territory__c>>();
        for(Master_Territory__c terr : [SELECT Id, Name, Parent_Territory__c, Parent_Territory__r.Name FROM Master_Territory__c ORDER BY Parent_Territory__r.Name DESC]){
            territoryWithName.put(terr.Id, terr.Name);
            if(territoryIdWithSubTerritories.containsKey(terr.Parent_Territory__c)){
                List<Master_Territory__c> subTerritories = territoryIdWithSubTerritories.get(terr.Parent_Territory__c);
                subTerritories.add(terr);
                territoryIdWithSubTerritories.put(terr.Parent_Territory__c, subTerritories);
            }
            else{
                territoryIdWithSubTerritories.put(terr.Parent_Territory__c, new List<Master_Territory__c>{terr});
            }
        }

        Map<Id, Id> existingIdSet = getExistingTerritories(recordId);

        List<CP_Territory__c> territories = new List<CP_Territory__c>();
        for(String territoryId : selectedTerritoryIds){
            if(territoryWithName.containsKey(territoryId) && !existingIdSet.containsKey(territoryId)){
                CP_Territory__c territory = new CP_Territory__c();
                territory.Rights_Set__c = rights.Id;
                territory.Name = territoryWithName.get(territoryId);
                territory.Master_Territory__c = territoryId;
                territory.Deal__c = recordId;
                territory.Type__c = 'M';
                territories.add(territory);
                territories.addAll(createSubTerritories(territoryId, territoryIdWithSubTerritories, rights.Id, recordId, existingIdSet));
            }
        }
        try{
            if(!removedTerritoryIds.isEmpty()){
                deleteRemovedTerritories(removedTerritoryIds, territoryIdWithSubTerritories, recordId); 
            }
            if(!territories.isEmpty()){
                upsert territories;
            }
            return 'SUCCESS';
        }
        catch(Exception ex){
            System.debug('There is exception '+ex.getMessage()+' at line number '+ex.getLineNumber());
            return 'There is exception '+ex.getMessage()+' at line number '+ex.getLineNumber();
        }
    }
    

    public static Id checkExistingIfAny(String recordId){
        List<Rights_Set__c> getRightsSet = [Select Id From Rights_Set__c Where Deal__c =: recordId Limit 1];
        if(!getRightsSet.isEmpty()){
            return getRightsSet[0].Id;
        }
        else{
            return null;
        }
    }

    private static List<CP_Territory__c> createSubTerritories(Id parentMasterTerritoryId, Map<Id, List<Master_Territory__c>> territoryIdWithSubTerritories, String rightsId, String recordId, Map<Id, Id> existingIdSet) {
        List<CP_Territory__c> localSubTerritories = new List<CP_Territory__c>();
        if(territoryIdWithSubTerritories.containsKey(parentMasterTerritoryId)){
            // Loop through sub-territories and create Territory__c records
            for (Master_Territory__c subTerritory : territoryIdWithSubTerritories.get(parentMasterTerritoryId)) {
                // Create a new Territory__c record for each sub-territory
                CP_Territory__c territory = new CP_Territory__c();
                territory.Rights_Set__c = rightsId;
                territory.Name = subTerritory.Name;
                territory.Master_Territory__c = subTerritory.Id;
                territory.Deal__c = recordId;
                territory.Type__c = 'C';
                territory.Id = existingIdSet.containsKey(subTerritory.Id) ? existingIdSet.get(subTerritory.Id) : null;
                localSubTerritories.add(territory);
                // Recursively create sub-territories for this sub-territory
                localSubTerritories.addAll(createSubTerritories(subTerritory.Id, territoryIdWithSubTerritories, rightsId, recordId, existingIdSet));
            }
        }
        return localSubTerritories;
    }

    public static void deleteRemovedTerritories(List<String> removedTerritoryIds, Map<Id, List<Master_Territory__c>> territoryIdWithSubTerritories, String recordId){
        Set<Id> territoryIdsToDelete = new Set<Id>();
        for(String territoryId : removedTerritoryIds){
            territoryIdsToDelete.add(territoryId);
            territoryIdsToDelete.addAll(getSubTerritoriesToDelete(territoryId, territoryIdWithSubTerritories));
        }

        List<CP_Territory__c> getTerritoriesToDelete = [Select Id From CP_Territory__c Where Rights_Set__r.Deal__c =: recordId AND Master_Territory__c IN: territoryIdsToDelete];
        if(!getTerritoriesToDelete.isEmpty()){
            try{
                delete getTerritoriesToDelete;
            }
            catch(Exception ex){
                System.debug('There is exception '+ex.getMessage()+' at line number '+ex.getLineNumber());
            }
        }
    }

    private static Set<Id> getSubTerritoriesToDelete(String territoryId, Map<Id, List<Master_Territory__c>> territoryIdWithSubTerritories){
        Set<Id> territoryIdsToDelete = new Set<Id>();
        if(territoryIdWithSubTerritories.containsKey(territoryId)){
            for(Master_Territory__c subTerritory : territoryIdWithSubTerritories.get(territoryId)){
                territoryIdsToDelete.add(subTerritory.Id);

                // Recursively getSubTerritoriesToDelete for this sub-territory
                territoryIdsToDelete.addAll(getSubTerritoriesToDelete(subTerritory.Id, territoryIdWithSubTerritories));
            }
        }
        return territoryIdsToDelete;
    }

    // Inner class to structure the territory hierarchy
    public class TerritoryHierarchy {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String iconName;
        @AuraEnabled public Boolean isExpanded;
        @AuraEnabled public Boolean checked;
        @AuraEnabled public Boolean disabled;
        @AuraEnabled public List<TerritoryHierarchy> children = new List<TerritoryHierarchy>();
        
        public TerritoryHierarchy(Id id, String name, Boolean checked, Boolean disabled) {
            this.id = id;
            this.name = name;
            this.iconName = 'utility:utility:chevronright';
            this.isExpanded = false;
            this.checked = checked;
            this.disabled = disabled;
        }
    }
}