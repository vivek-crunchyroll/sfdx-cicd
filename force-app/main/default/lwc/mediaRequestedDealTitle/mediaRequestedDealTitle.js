import { LightningElement, wire,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
//import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import OPPORTUNITYLineItem_OBJECT from '@salesforce/schema/OpportunityLineItem';
import {getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import OBJECT_FIELD from '@salesforce/schema/OpportunityLineItem.Media__c';
//import DealTitle_Media from '@salesforce/schema/OpportunityLineItem.DealTitle_Media__c';
import Id_Field from '@salesforce/schema/OpportunityLineItem.Id';
import Text_Field from '@salesforce/schema/OpportunityLineItem.Requested_Media__c';
export default class MediaRequestedDealTitle extends LightningElement {

@wire(getObjectInfo, {objectApiName: OPPORTUNITYLineItem_OBJECT})
opportunityInfoLineItem;

@api recordId;
@track selected = []; // Selected values
@track selectedAll = []; // Selected values array with label and value
@track options = [];
@track remainingAvailable = [];

@wire(getRecord, { recordId: '$recordId', fields: [Id_Field,Text_Field] })
wiredRecordData({ error, data }) {
    console.log('Data:---->'+JSON.stringify(data));
if (data) {
this.selected = data.fields[Text_Field.fieldApiName].value
? data.fields[Text_Field.fieldApiName].value.split(' | ')
: [];
} else if (error) {
console.error(error);
}
}
@wire(getPicklistValues, {
//recordTypeId: '$opportunityInfoLineItem.data.defaultRecordTypeId',
//recordTypeId: '$OPPORTUNITY_OBJECT.data.defaultRecordTypeId',

recordTypeId: '012000000000000AAA',
fieldApiName: OBJECT_FIELD
})

wiredPicklistValues({ error, data }) {
if (data && data.values){
this.options = data.values.map((option) => ({
label: option.label,
value: option.value
}));
console.log('this.options===>'+this.options);
this.filter()
} else if (error) {
console.error(error);
}
}
filter(event) {
let filter = event? 
new RegExp(this.template.querySelector('lightning-input').value, 'ig'):
{ test: function() { return true }}
const selected = new Set(this.selected)
console.log('this.selected===>'+this.selected);

this.selectedAll = this.options.filter(option => (selected.has(option.value)));
this.remainingAvailable = this.options.filter(option => (!selected.has(option.value)))
console.log('this.selectedAll===>'+this.selectedAll);
console.log('this.remainingAvailable===>'+this.remainingAvailable);

}
handleChange(event) {
//Selected values
this.selected = event.detail.value;
this.selectedAll = [];
//Maintain selected values array with label and value
this.options.forEach((element) => {
this.selected.forEach((selectedValue) => {
    if (element.value === selectedValue && this.selectedAll.filter(e => e.value === selectedValue).length === 0) {
        this.selectedAll.push(element);
    }
});
});
//Maintain non-selected values array
this.remainingAvailable = [];
this.options.forEach((element) => {
if (this.selectedAll.filter(e => e.value === element.value).length === 0) {
    this.remainingAvailable.push(element);
}
});
}

originalOptions = [];
handleAvailableSearch(event) {
const searchValue = event.detail.value.toLowerCase();
if (this.originalOptions.length === 0) {
this.originalOptions = [...this.options];
}
if (searchValue) {
const filteredOptions = this.originalOptions.filter((element) =>
element.label.toLowerCase().includes(searchValue)
);
this.options = [...filteredOptions, ...this.selectedAll];
} else {
this.options = [...this.originalOptions, ...this.selectedAll];
}
}
handleSave() {

const recordId = this.recordId;
const fields = {};

fields[Id_Field.fieldApiName] = recordId;

fields[Text_Field.fieldApiName] = this.selected.join(' | ');
fields[OBJECT_FIELD.fieldApiName] = this.selected.join(';');

const recordInput = { fields };
console.log('recordInput-->'+recordInput);
updateRecord(recordInput)

.then((result) => {

// Handle success

console.log('Record updated successfully');

this.showToastMessage('Success', 'Record updated successfully', 'success');
// Update the component's state with the newly selected values

this.selectedAll = this.options.filter((option) =>

    this.selected.includes(option.value)

);

this.remainingAvailable = this.options.filter(

    (option) => !this.selected.includes(option.value)

);

})

.catch((error) => {

// Handle error

console.error('Error updating record:', error);

this.showToastMessage('Error', error.body.output.fieldErrors.Licensor_Approved__c[0].
message, 'error');

});

}
showToastMessage(title, message, variant) {
const toastEvent = new ShowToastEvent({
title: title,
message: message,
variant: variant
});
this.dispatchEvent(toastEvent);
}
}