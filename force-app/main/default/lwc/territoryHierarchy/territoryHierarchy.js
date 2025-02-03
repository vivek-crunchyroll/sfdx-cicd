import { LightningElement, wire } from 'lwc';
import getTerritoriesWithSubTerritories from '@salesforce/apex/TerritoryController.getTerritoriesWithSubTerritories';

export default class TerritoryHierarchy extends LightningElement {
    territoryHierarchy = [];

    // Wire method to fetch territory hierarchy from Apex
    @wire(getTerritoriesWithSubTerritories)
    wiredTerritories({ error, data }) {
        if (data) {
            this.territoryHierarchy = data;  // Store the fetched hierarchy in territoryHierarchy
        } else if (error) {
            console.error('Error fetching territories:', error);
        }
    }

    // Recursive function to render sub-territories
    renderSubTerritories(territories) {
        return territories.map((territory) => {
            return `
                <ul>
                    <li>${territory.territoryName}
                        ${territory.subTerritories && territory.subTerritories.length > 0 
                            ? this.renderSubTerritories(territory.subTerritories) 
                            : ''}
                    </li>
                </ul>
            `;
        }).join('');
    }
}