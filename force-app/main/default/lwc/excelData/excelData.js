import { LightningElement, track } from 'lwc';
//import saveDataToSalesforce from '@salesforce/apex/ExcelDataController.saveDataToSalesforce';
import excelFileReader from "@salesforce/resourceUrl/SheetJS"; // Import xlsx.js library
import { loadScript } from "lightning/platformResourceLoader";

export default class ExcelFileProcessor extends LightningElement {
    @track excelData = [];

    connectedCallback() {
            Promise.all([loadScript(this, excelFileReader)])
                .then(() => {
                    XLS = window.XLSX;
                })
                .catch((error) => {
                    
                });
        }

    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const binaryStr = e.target.result;
                const workbook = XLSX.read(binaryStr, { type: 'array' });
                const sheetName = workbook.SheetNames[0]; // Assuming the first sheet contains the data
                const sheet = workbook.Sheets[sheetName];

                // Convert sheet data to JSON
                this.excelData = XLSX.utils.sheet_to_json(sheet);
                console.log('Extracted Data:', this.excelData);
            };
            reader.readAsArrayBuffer(file);
        }
    }

    handleSave() {
        saveDataToSalesforce({ records: this.excelData })
            .then(() => {
                alert('Data saved to Salesforce successfully!');
            })
            .catch((error) => {
                console.error('Error saving data:', error);
                alert('Failed to save data to Salesforce.');
            });
    }
}