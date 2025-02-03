import { LightningElement, track } from 'lwc';

export default class RightsExplorerHome extends LightningElement {
    @track showDockFilters = true;
    @track isDates = false;
    @track isExclusivity = false;
    @track isMedia = false;
    @track isTerritory = false;

    @track criteriaObj;

    connectedCallback() {
        this.criteriaObj = this.initiateCriteriaObj();
        console.log("Criteria", JSON.stringify(this.criteriaObj));
    }

    initiateCriteriaObj() {
        // Get current date
        const today = new Date();
        const currentDate = this.formatDate(today);

        // Get date 7 months later
        const futureDate = new Date(today);
        futureDate.setMonth(today.getMonth() + 7);
        const sevenMonthsLaterDate = this.formatDate(futureDate);

        return {
            Dates: {
                startDate: currentDate,
                endDate: sevenMonthsLaterDate,
                minumumWindowInDays: null,
                availabilityWindows: null
            },
            Exclusivity: "",
            Media: [],
            Territory: [],
            Titles: []
        };
    }

    formatDate(date) {
        // Format date to 'YYYY-MM-DD' format for easy use in input fields
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${month}/${day}/${year}`;
    }

    get exlusiveOptions() {
        return [
            { label: 'choose one...', value: '' },
            { label: 'Exclusive', value: 'Exclusive' },
            { label: 'Non-Exclusive', value: 'Non-Exclusive' }
        ];
    }

    handleOnClick(event) {
        const getSelected = event.target.dataset.name;
        if (getSelected == "Dates") {
            this.isDates = true;
            this.isExclusivity = false;
            this.isMedia = false;
            this.isTerritory = false;

        }
        else if (getSelected == "Exclusivity") {
            this.isDates = false;
            this.isExclusivity = true;
            this.isMedia = false;
            this.isTerritory = false;
        }
        else if (getSelected == "Media") {
            this.isDates = false;
            this.isExclusivity = false;
            this.isMedia = true;
            this.isTerritory = false;
        }
        else if (getSelected == "Territory") {
            this.isDates = false;
            this.isExclusivity = false;
            this.isMedia = false;
            this.isTerritory = true;
        }
    }
}