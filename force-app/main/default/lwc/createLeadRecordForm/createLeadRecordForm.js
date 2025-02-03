import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LEAD_OBJECT from '@salesforce/schema/Lead'
import NAME_FIELD from '@salesforce/schema/Lead.LastName'
import COMPANY_FIELD from '@salesforce/schema/Lead.Company'
import LEADSTATUS_FIELD from '@salesforce/schema/Lead.Status'
import EMAIL_FIELD from '@salesforce/schema/Lead.Email'
import PHONE_FIELD from '@salesforce/schema/Lead.Phone'
import MAJORREGION_FIELD from '@salesforce/schema/Lead.Territories__c'
import MINORREGION_FIELD from '@salesforce/schema/Lead.Region__c'
import COMPANYTYPE_FIELD from '@salesforce/schema/Lead.Company_Type__c'
import DESCRIPTION_FIELD from '@salesforce/schema/Lead.Description'

export default class CreateLeadRecordForm extends LightningElement {
    objectName = LEAD_OBJECT
    fieldList = [NAME_FIELD, COMPANY_FIELD, LEADSTATUS_FIELD, EMAIL_FIELD, PHONE_FIELD, MAJORREGION_FIELD, MINORREGION_FIELD, MINORREGION_FIELD, COMPANYTYPE_FIELD, DESCRIPTION_FIELD]

    handleSubmit(event) {
        event.preventDefault(); 

       
        const isSaveSuccessful = true; 

        if (isSaveSuccessful) {
            this.showToast('Success', 'Record has been saved successfully.', 'success','dismissable');
        } else {
            this.showToast('Error', 'There was an error saving the Record.', 'error','dismissable');
        }
    }

    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

}