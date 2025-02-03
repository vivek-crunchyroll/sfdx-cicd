import { LightningElement, track, api, wire } from 'lwc';
import getTerritories from '@salesforce/apex/TerritoryAssignmentController.getTerritoryHierarchy';
import assignTerritories from '@salesforce/apex/TerritoryAssignmentController.assignTerritories';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class TerritoryAssignment extends LightningElement {
    @api recordId;
    @track territories = [];
    backupTerritories = [];
    @track selectedRows = [];

    selectedTerritories = [];
    removedTerritories = [];
    @track selectedTerritoryNames = [];

    isLoading = false;
    hasError = false;
    isRefreshing = false;
    message = "";
    refreshMessage = "";

    searchKey = "";


    connectedCallback() {
        this.fetchTerritories();
    }

    fetchTerritories() {
        this.isLoading = true;
        getTerritories({ "recordId": this.recordId })
            .then((data) => {
                console.log("Actual Data", JSON.stringify(data));
                this.territories = this.expandAncestors(JSON.parse(JSON.stringify(data)));
                this.backupTerritories = this.expandAncestors(JSON.parse(JSON.stringify(data)));
                console.log("Actual back up", JSON.stringify(this.backupTerritories));
                this.selectedTerritoryNames = this.getCheckedTerritories(JSON.parse(JSON.stringify(data)));
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error fetching file:', error);
                this.isLoading = false;
            });
    }

    expandAncestors(dataString) {
        var data = [...dataString];
        // Loop through each item in the array
        data.forEach(item => {
            // Ensure children exists and is an array
            if (Array.isArray(item.children) && item.children.some(child => child.isExpanded)) {
                // Set the current item to expanded
                item.isExpanded = true;
                item.iconName = "utility:chevrondown";
            }

            // Recursively call on children if they exist
            if (Array.isArray(item.children) && item.children.length > 0) {
                this.expandAncestors(item.children);
            }
        });
        return data;
    }

    getCheckedTerritories(dataString) {
        let checkedTerritories = [];
        var data = [...dataString];
        // Recursive function to check through the data and get territories where checked is true
        const findCheckedTerritories = (territoryList) => {
            territoryList.forEach(territory => {
                // If this territory is checked, add its name to the result array
                if (territory.checked) {
                    checkedTerritories.push(territory.name);
                }
                // If this territory has children, recursively check them
                if (territory.children && territory.children.length > 0) {
                    findCheckedTerritories(territory.children);
                }
            });
        };

        // Start the recursion
        findCheckedTerritories(data);
        return checkedTerritories;
    }


    handleSelectionChange(event) {
        console.log("In handleSelectionChange");
        const selectedIds = event.detail.selected; // Get the selected IDs from the child component
        const removedIds = event.detail.removed; // Get the removed IDs from the child component
        const selectedNames = event.detail.selectedNames; // Get the selected names from the child component
        const removedNames = event.detail.removedNames; // Get the selected names from the child component
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
            const index = this.selectedTerritories.indexOf(id);
            if (index > -1) {
                this.selectedTerritories.splice(index, 1);
            }
        });

        removedNames.forEach(name => {
            const index = this.selectedTerritoryNames.indexOf(name);
            if (index > -1) {
                this.selectedTerritoryNames.splice(index, 1);
            }
        });
    }

    handleAssignment() {
        this.isLoading = true;
        const button = this.template.querySelector('.assignmentButton');
        if (button) {
            button.disabled = true;
        }
        assignTerritories({ selectedTerritoryIds: this.selectedTerritories, removedTerritoryIds: this.removedTerritories, recordId: this.recordId })
            .then(result => {
                if (button) {
                    button.disabled = false;
                }
                this.isLoading = false;
                if (result == "SUCCESS") {
                    this.showToast("", "Territory assignment is successfully completed", "success");
                }
                else {
                    this.showToast("", result, "error");
                }
                setTimeout(() => {
                    this.isLoading = true;
                    this.showToast("", "Heirarchy is refreshing", "warning");
                    setTimeout(() => {
                        this.fetchTerritories();
                        this.isLoading = false;
                        this.showToast("", "Heirarchy refresh is completed", "success");
                    }, 1000);
                }, 1000);
            })
            .catch(error => {
                console.error('Error creating record:', error);
                console.error('Error creating record:', error.message);
                console.error('Error creating record:', error.stack);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    handleKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.searchKey = event.target.value;
            this.territories = this.searchTerritory(this.expandAncestors(JSON.parse(JSON.stringify(this.backupTerritories))), this.searchKey);
            console.log("filtered territories", JSON.stringify(this.searchTerritory(this.territories, this.searchKey)));
        }
    }

    handleOnClear() {
        const searchInput = this.template.querySelector('.searchKey');
        searchInput.value = "";
        this.searchKey = "";
        this.territories = this.backupTerritories;
        console.log("backed up", JSON.stringify(this.territories));
        const updateTerritories = (territoriesToUpdate) => {
            territoriesToUpdate.forEach(territory => {
                if (this.selectedTerritories.includes(territory.id)) {
                    territory.checked = true;
                    territory.isExpanded = true;
                    territory.iconName = "utility:chevrondown";
                }

                // If the territory has children, recurse into them
                if (territory.children && territory.children.length > 0) {
                    updateTerritories(territory.children);
                }
            });
        };

        updateTerritories(this.territories);
        console.log("result territories", JSON.stringify(this.territories));
        this.territories = this.expandAncestors(JSON.parse(JSON.stringify(this.territories)));
        console.log("rolled back", JSON.stringify(this.territories));
    }

    // Recursive function to find the territory and return only the part of the hierarchy containing it
    searchTerritory(territories, searchTerm) {
        let result = null;

        const search = (territoryList) => {
            for (let territory of territoryList) {
                // If we find the territory, return it and all its ancestors
                if (territory.name.toLowerCase() === searchTerm.toLowerCase()) {
                    territory.isExpanded = true;
                    territory.iconName = "utility:chevrondown";
                    result = territory;
                    return true; // Exit once we find the territory
                }

                // If the territory has children, recurse into them
                if (territory.children && territory.children.length > 0) {
                    const foundInChildren = search(territory.children);
                    if (foundInChildren) {
                        // If found in children, include the current territory in the result
                        if (!territory.children.some(child => child.name === searchTerm)) {
                            territory.children = [result]; // Only include the matched territory in its parent
                        }
                        territory.isExpanded = true;
                        territory.iconName = "utility:chevrondown";
                        result = territory;
                        return true;
                    }
                }
            }
            return false;
        };

        // Start searching
        search(territories);

        return result ? [result] : null; // Return the found territory along with its hierarchy
    }
}