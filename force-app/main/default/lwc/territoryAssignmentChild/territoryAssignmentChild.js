import { LightningElement, api, track } from 'lwc';

export default class TerritoryAssignmentChild extends LightningElement {
    _territories = [];  // Private variable to hold the copy
    @track localTerritories = [];  // Local copy to work with

    // Setter for the @api property 'territories'
    @api
    set territories(value) {
        // Store the original array in the private variable and update localTerritories
        this._territories = JSON.parse(JSON.stringify(value));
        this.localTerritories = [...this._territories];  // Make a shallow copy
    }

    // Getter for the @api property 'territories' (optional, if you need to access it)
    get territories() {
        return this._territories;
    }

    selectedTerritories = [];
    removedTerritories = [];
    selectedTerritoryNames = [];
    removedTerritoryNames = [];

    handleToggle(event) {
        const rowId = event.target.dataset.id;
        const rowIndex = this.localTerritories.findIndex(item => item.id === rowId);
        if (rowIndex !== -1) {
            this.localTerritories[rowIndex].isExpanded = !this.localTerritories[rowIndex].isExpanded;
            // Change the icon based on visibility
            this.localTerritories[rowIndex].iconName = this.localTerritories[rowIndex].isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
        }
    }

    handleChange(event) {
        const getId = event.target.dataset.id;
        const getName = event.target.dataset.name;
        if (event.target.checked) {
            //To add selected
            if (!this.selectedTerritories.includes(getId)) {
                this.selectedTerritories.push(getId);
            }
            if (!this.selectedTerritoryNames.includes(getName)) {
                this.selectedTerritoryNames.push(getName);
            }
            //To remove selected
            const index = this.removedTerritories.indexOf(getId);
            if (index > -1) {
                this.removedTerritories.splice(index, 1);
            }

            const nameIndex = this.removedTerritoryNames.indexOf(getName);
            if (nameIndex > -1) {
                this.removedTerritoryNames.splice(nameIndex, 1);
            }

        }
        else {
            //To remove unselected
            const index = this.selectedTerritories.indexOf(getId);
            if (index > -1) {
                this.selectedTerritories.splice(index, 1);
            }

            const nameIndex = this.selectedTerritoryNames.indexOf(getName);
            if (nameIndex > -1) {
                this.selectedTerritoryNames.splice(nameIndex, 1);
            }

            //To add unselected
            if (!this.removedTerritories.includes(getId)) {
                this.removedTerritories.push(getId);
            }

            if (!this.removedTerritoryNames.includes(getName)) {
                this.removedTerritoryNames.push(getName);
            }
        }
        console.log(JSON.stringify(this.selectedTerritories));

        // Dispatch the selected IDs to the parent component
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { selected: this.selectedTerritories, removed: this.removedTerritories, selectedNames: this.selectedTerritoryNames, removedNames :this.removedTerritoryNames }, // Pass the selected IDs as the event's detail
            bubbles: true, // Allow event to propagate up the DOM tree
            composed: true // Allows event to cross shadow DOM boundaries
        }));
    }

    handleSelectionChange(event) {
        console.log("In child handleSelectionChange");
        const selectedIds = event.detail.selected; // Get the selected IDs from the child component
        const removedIds = event.detail.removed; // Get the removed IDs from the child component
        const selectedNames = event.detail.selectedNames; // Get the selected names from the child component
        const removedNames = event.detail.removedNames; // Get the removed names from the child component

        selectedIds.forEach(id => {
            if (!this.selectedTerritories.includes(id)) {
                this.selectedTerritories.push(id);
            }
        });

        selectedNames.forEach(name => {
            if (!this.selectedTerritoryNames.includes(name)) {
                this.selectedTerritoryNames.push(name);
            }
        });

        removedIds.forEach(id => {
            if (!this.removedTerritories.includes(id)) {
                this.removedTerritories.push(id);
            }
        });

        removedNames.forEach(name => {
            if (!this.removedTerritoryNames.includes(name)) {
                this.removedTerritoryNames.push(name);
            }
        });

        // Dispatch the selected IDs to the parent component
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { selected: this.selectedTerritories, removed: this.removedTerritories, selectedNames: this.selectedTerritoryNames, removedNames :this.removedTerritoryNames }, // Pass the merged selected IDs to the parent
            bubbles: true, // Allow the event to propagate further up
            composed: true // Cross shadow DOM boundary
        }));
    }
}