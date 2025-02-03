public class TerritoryController {
    
    // Method to fetch territories and sub-territories recursively
    @AuraEnabled(cacheable=true)
    public static List<TerritoryWrapper> getTerritoriesWithSubTerritories() {
        // Query all territories and their parent-child relationships
        List<Master_Territory__c> territories = [SELECT Id, Name, Parent_Territory__r.Name FROM Master_Territory__c];

        // Map to hold TerritoryWrapper objects by Territory ID
        Map<Id, TerritoryWrapper> territoryMap = new Map<Id, TerritoryWrapper>();
        
        // Create TerritoryWrapper objects for each territory
        for (Master_Territory__c territory : territories) {
            TerritoryWrapper wrapper = new TerritoryWrapper(territory.Id, territory.Name);
            territoryMap.put(territory.Id, wrapper);
        }

        // List to hold root-level territories (World)
        List<TerritoryWrapper> rootTerritories = new List<TerritoryWrapper>();

        // Build the parent-child relationship
        for (Master_Territory__c territory : territories) {
            if (territory.Parent_Territory__c == null) {
                // Add root territory (e.g., World) to rootTerritories list
                rootTerritories.add(territoryMap.get(territory.Id));
            } else {
                // If the territory has a parent, add it to its parent territory's subTerritories list
                TerritoryWrapper parentWrapper = territoryMap.get(territory.Parent_Territory__c);
                if (parentWrapper != null) {
                    parentWrapper.subTerritories.add(territoryMap.get(territory.Id));
                }
            }
        }

        // Return the root territories (World and its sub-territories)
        return rootTerritories;
    }

    // Wrapper class to represent each territory and its sub-territories
    public class TerritoryWrapper {
        @AuraEnabled public Id territoryId;
        @AuraEnabled public String territoryName;
        @AuraEnabled public List<TerritoryWrapper> subTerritories;

        // Constructor for TerritoryWrapper
        public TerritoryWrapper(Id id, String name) {
            this.territoryId = id;
            this.territoryName = name;
            this.subTerritories = new List<TerritoryWrapper>();
        }
    }
}