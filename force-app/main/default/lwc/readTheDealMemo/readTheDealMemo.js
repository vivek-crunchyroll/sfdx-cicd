import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import excelFileReader from "@salesforce/resourceUrl/SheetJS";
import Quantity from "@salesforce/schema/Asset.Quantity";
import getFileContent from "@salesforce/apex/ReadTheDealMemoController.getFileContent";
import saveExtractData from "@salesforce/apex/ReadTheDealMemoController.saveExtractData";
import getRightsSetIdByCategory from "@salesforce/apex/ReadTheDealMemoController.getRightsSetIdByCategory";
import saveSelectedCategories from "@salesforce/apex/ReadTheDealMemoController.saveSelectedCategories";
import { CurrentPageReference } from 'lightning/navigation';
import DISTRIBUTION_CHANNEL_FIELD from '@salesforce/schema/Lead.Distribution_Channels__c';

let XLS = {};

export default class ReadTheDealMemo extends LightningElement {
    @api recordId;
    strAcceptedFormats = [".xls", ".xlsx"];
    strUploadFileName;
    objExcelToJSON;
    uploadedFile;
    rightsetId = '';
    isLoading = false;
    distributionChannel;


    @wire(getRecord, { recordId: '$recordId', fields: [DISTRIBUTION_CHANNEL_FIELD] })
    wiredLead({ error, data }) {
        if (data) {
            this.distributionChannel = getFieldValue(data, DISTRIBUTION_CHANNEL_FIELD);
        } else if (error) {
            console.error('Error retrieving lead:', error);
        }
    }




    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId || this.recordId;
        }
    }


    connectedCallback() {
        Promise.all([loadScript(this, excelFileReader)])
            .then(() => {
                XLS = window.XLSX;
                this.showToast("Success", "Excel file library loaded successfully.", "success");
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: "An error occurred while loading the Excel file library.",
                        variant: "error"
                    })
                );
            });
    }

    renderedCallback() {
        if (this.recordId) {
        } else {
            console.log('Rendered callback. Record ID is still undefined');
        }
    }



    //Extract Data

    handleExtractData() {
        this.isLoading = true;
        //if (this.uploadedFile) {
        getFileContent({ leadId: this.recordId })
            .then((base64FileContent) => {
                const fileData = this.base64ToArrayBuffer(base64FileContent);
                this.handleProcessExcelFile(fileData);
            })
            .catch((error) => {
                this.showToast("Error", `Error fetching file: ${error.body.message}`, "error");
                this.isLoading = false;
            });
    }

    base64ToArrayBuffer(base64) {
        const binaryString = atob(base64);
        const arrayBuffer = new ArrayBuffer(binaryString.length);
        const uint8Array = new Uint8Array(arrayBuffer);

        for (let i = 0; i < binaryString.length; i++) {
            uint8Array[i] = binaryString.charCodeAt(i);
        }

        return arrayBuffer;
    }


    checkCellData(cellData, targetCell) {
        return cellData[targetCell] != undefined && cellData[targetCell] != null && cellData[targetCell] != "";
    }
    // Function to convert percentage string to decimal
    parsePercentage(percentageString) {
        if (!percentageString) return null;
        // Remove the '%' sign and convert to decimal
        return parseFloat(percentageString.replace('%', ''));
    }

    // Function to convert date string to JavaScript Date object
    parseDateString(dateString) {
        return new Date(dateString);
    }

    excelToDateWithTime(serial) {
        var epochOffset = 25569;
        var date = new Date((serial - epochOffset) * 86400 * 1000);
        return date;
    }

    // Function to format date as MM/DD/YYYY
    formatDateToYYYYMMDD(date) {
        if (!date) return null;
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    // Function to format date as DD/MM/YYYY
    formatDateToDDMMYYYY(date) {
        if (!date) return null; 
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear(); 
        return `${day}/${month}/${year}`; 
    }


    handleProcessExcelFile(fileData) {
        //let file = this.uploadedFile;
        let objFileReader = new FileReader();
        objFileReader.onload = (event) => {
            let arrayBuffer = event.target.result;

            if (!fileData) {
                this.isLoading = false;
                this.showToast("Error", "No data read from the file.", "error");
                return;
            }


            let objFileWorkbook = XLS.read(arrayBuffer, { type: "array" });

            //For CategoryList Sheet
            this.processCategoryListSheet(objFileWorkbook);

            if (!objFileWorkbook.Sheets["Application Form"]) {
                this.isLoading = false;
                this.showToast("Error", "Sheet 'Application Form' not found in the workbook.", "error");
                return;
            }

            //Cell Data
            var cellData = objFileWorkbook.Sheets["Application Form"];

            const extractedData = {
                DistributionChannels: this.distributionChannel || '',
                ApplicationType: this.checkCellData(cellData, "C3") ? cellData["D3"].v : (this.checkCellData(cellData, "E3") ? cellData["F3"].v : (this.checkCellData(cellData, "H3") ? cellData["I3"].v : null)),
                ApplicationDate: this.checkCellData(cellData, "C2") ? this.excelToDateWithTime(cellData["C2"].v) : null,
                Applicant: this.checkCellData(cellData, "C5") ? cellData["C5"].v : null,
                Jurisdiction: this.checkCellData(cellData, "C6") ? cellData["C6"].v : null,
                ApplicantAddress: this.checkCellData(cellData, "C7") ? cellData["C7"].v : null,
                Telephone: this.checkCellData(cellData, "C8") ? cellData["C8"].v : null,
                VAT: this.checkCellData(cellData, "C9") ? cellData["C9"].v : null,
                ApplicantContact: this.checkCellData(cellData, "C10") ? cellData["C10"].v : null,
                ApplicantEmail: this.checkCellData(cellData, "G10") ? cellData["G10"].v : null,
                SignatoryContact: this.checkCellData(cellData, "C11") ? cellData["C11"].v : null,
                SignatoryEmail: this.checkCellData(cellData, "G11") ? cellData["G11"].v : null,
                AccountsPayableContact: this.checkCellData(cellData, "C12") ? cellData["C12"].v : null,
                AccountsPayableEmail: this.checkCellData(cellData, "G12") ? cellData["G12"].v : null,
                CreativeContact: this.checkCellData(cellData, "C13") ? cellData["C13"].v : null,
                CreativeContactEmail: this.checkCellData(cellData, "G13") ? cellData["G13"].v : null,
                SubmissionsContact: this.checkCellData(cellData, "C14") ? cellData["C14"].v : null,
                SubmissionsContactEmail: this.checkCellData(cellData, "G14") ? cellData["G14"].v : null,
                property: this.checkCellData(cellData, "C16") ? cellData["C16"].v : null,
                Territory: this.checkCellData(cellData, "C17") ? cellData["C17"].v : null,
                Exclusivity: this.checkCellData(cellData, "C18") ? cellData["D18"].v : this.checkCellData(cellData, "F18") ?  'Exclusive' : null,
                CountryofProduction: this.checkCellData(cellData, "C25") ? cellData["C25"].v : null,
                TargetDemographic: this.checkCellData(cellData, "C26") ? cellData["C26"].v : null,
                TermLengthStart: this.checkCellData(cellData, "D27") ? this.excelToDateWithTime(cellData["D27"].v) : null,
                TermLengthEnd: this.checkCellData(cellData, "F27") ? this.excelToDateWithTime(cellData["F27"].v) : null,
                MinimumGuarantee: this.checkCellData(cellData, "C28") ? cellData["C28"].v : null,
                Advance: this.checkCellData(cellData, "C30") ? cellData["C30"].v : null,
                MGPaymentSchedule: this.checkCellData(cellData, "C31") ? cellData["C31"].v : null,
                LATAM: this.checkCellData(cellData, "J28") ? cellData["J28"].v : null,
                NA: this.checkCellData(cellData, "F28") ? cellData["F28"].v : null,
                ANZ: this.checkCellData(cellData, "L28") ? cellData["L28"].v : null,
                EMEA: this.checkCellData(cellData, "H28") ? cellData["H28"].v : null,
                WholeSale: this.checkCellData(cellData, "C32") ? cellData["C32"].v : null,
                RetailDirectToConsumer: this.checkCellData(cellData, "C34") ? cellData["C34"].v : null,
                FOB: this.checkCellData(cellData, "C33") ? cellData["C33"].v : null,
                OtherRoyaltyRate: this.checkCellData(cellData, "C35") ? cellData["C35"].v : null,
                DistributionChannelsOther: this.checkCellData(cellData, "E24") ? cellData["E24"].v : null,



            };

            // Initialize an array to hold the distribution channel values
            let distributionChannels = [];

            // Check each relevant cell and push the value into the array if it exists
            if (this.checkCellData(cellData,"C19")) {
                distributionChannels.push(cellData["D19"].v);
            }
            if (this.checkCellData(cellData,"C20")) {
                distributionChannels.push(cellData["D20"].v);
            }
            if (this.checkCellData(cellData,"C21")) {
                distributionChannels.push(cellData["D21"].v);
            }
            if (this.checkCellData(cellData,"C22")) {
                distributionChannels.push(cellData["D22"].v);
            }
            if (this.checkCellData(cellData,"C23")) {
                distributionChannels.push(cellData["D23"].v);
            }
            if (this.checkCellData(cellData,"C24")) {
                distributionChannels.push('Other');
            }
            if (this.checkCellData(cellData,"F19")) {
                distributionChannels.push(cellData["G19"].v);
            }
            if (this.checkCellData(cellData,"F20")) {
                distributionChannels.push(cellData["G20"].v);
            }
            if (this.checkCellData(cellData,"F21")) {
                distributionChannels.push(cellData["G21"].v);
            }
            if (this.checkCellData(cellData,"F22")) {
                distributionChannels.push(cellData["G22"].v);
            }
            if (this.checkCellData(cellData,"F23")) {
                distributionChannels.push(cellData["G23"].v);
            }

            // Join the values into a single string for the multi-picklist field
            extractedData.DistributionChannels = distributionChannels.join(';');

            // Format TermLengthStart to MM/DD/YYYY
            extractedData.TermLengthStart = this.formatDateToYYYYMMDD(extractedData.TermLengthStart);
            extractedData.TermLengthEnd = this.formatDateToYYYYMMDD(extractedData.TermLengthEnd);
            extractedData.ApplicationDate = this.formatDateToYYYYMMDD(extractedData.ApplicationDate);

            //Call Apex method to save the extracted data
            saveExtractData({ leadId: this.recordId, jsonData: JSON.stringify(extractedData) })
                .then((response) => {
                    this.isLoading = false;
                    if (response.success) {
                   
                    this.showToast("Success", response.success, "success");
                    setTimeout(() => {
                        window.location.reload();
                    }, 5000);
                    }
                    if (response.warning) {
                        this.showToast('Warning', response.warning, 'warning');
                    }
                    if (response.noProductsWarning) {
                        this.showToast('Warning', response.noProductsWarning, 'warning');
                    }
                    if (response.error) {
                        this.showToast('Error', response.error, 'error');
                    }
                    if (response.leadUpdate) {
                        this.showToast('Success', response.leadUpdate, 'success');
                        setTimeout(() => {
                            window.location.reload();
                        }, 5000);
                    }
                    if (response.leadError) {
                        this.showToast('Error', response.leadError, 'error');
                    }
                    if (response.rightsUpdate) {
                        this.showToast('Success', response.rightsUpdate, 'success');
                    }
                    if (response.rightsError) {
                        this.showToast('Error', response.rightsError, 'error');
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    this.showToast("Error", `Error saving data: ${error.body.message}`, "error");

                });

            if (Object.values(extractedData).every((value) => value === null)) {
                this.isLoading = false;
                throw new Error("No valid data found in the uploaded file.");
            }

            if (extractedData) {
                //call apex method send the json string to apex method as parameter and in addition send lead record Id
                //JSON.stringify(extractedData);
                this.showToast(
                    "Success",
                    "Data extracted successfully from the uploaded file.",
                    "success"
                );

            } else {
                this.isLoading = false;
                this.showToast(
                    "Error",
                    "No valid data found in the uploaded file. Please check the file content.",
                    "error"
                );

            }
        };

        objFileReader.onerror = (error) => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error while reading the file",
                    message: error.message,
                    variant: "error"
                })
            );
        };
        //Read the file data as an ArrayBuffer
        objFileReader.readAsArrayBuffer(new Blob([fileData]));
    }
    //CategoryListSheet(Sheet2)
    processCategoryListSheet(objFileWorkbook) {
        if (!objFileWorkbook.Sheets["Category List"]) {
            this.isLoading = false;
            this.showToast("Error", "Sheet 'Category List' not found in the workbook.", "error");
            return;
        }

        var cellDataCategory = objFileWorkbook.Sheets["Category List"];
        let selectedCategories = [];

        // Loop through the rows in the "Category List" sheet
        for (let row = 2; row <= 500; row++) {
            let categoryCell = `A${row}`;
            let markCell = `B${row}`;

            if (cellDataCategory[markCell] && (cellDataCategory[markCell].v === true|| 
                (typeof cellDataCategory[markCell].v === 'string' && cellDataCategory[markCell].v.trim() !== '') ||(typeof cellDataCategory[markCell].v === 'symbol') )) {
                selectedCategories.push(cellDataCategory[categoryCell].v);
            }
        }


        // Call Apex method to save the selected categories
        if (selectedCategories.length > 0) {
            saveSelectedCategories({ leadId: this.recordId, categories: selectedCategories })
                .then(() => {
                    this.showToast("Success", "Categories saved successfully.", "success");
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error saving categories:', error);
                    this.showToast("Error", `Error saving categories: ${error.body.message}`, "error");
                });
        } else {
            this.showToast("Info", "No categories selected.", "info");
        }
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

    
    showWarningToast(message) {
    const evt = new ShowToastEvent({
        title: 'Warning',
        message: message,
        variant: 'warning',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);

    }
}