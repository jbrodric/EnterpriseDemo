import { LightningElement, api, track, wire } from 'lwc';
import {getPicklistValues,getObjectInfo} from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class MultiSelPicklistDatatable extends LightningElement {
    @api objectName = '';
    @api fieldName = '';
    @api recordID;
    @api recordTypeId;
    @api selectedValues = '';
    @api isRequired = false;
    @api tableLabel;
    @api tableIcon;
    @api showInlineHelpText;
    @api tableHeight;
    @api tableBorder;
    @track options;
    @track columns;
    @track vals = [];
    @track isInvalid = false;
    @track helpText = '';
    @track borderClass;
    apiFieldName;
    recId;

    get requiredSymbol() {
        return this.isRequired ? '*' : '';
    }

    get formElementClass() {
        return this.isInvalid ? 'slds-form-element slds-has-error' : 'slds-form-element';
    }

    get hasIcon() {
        return (this.tableIcon && this.tableIcon.length > 0);
    }

    get hasTableLabel() {
        return (this.tableLabel && this.tableLabel.length > 0);
    }

    get formattedTableLabel() {
        return  this.hasTableLabel? '<h2>&nbsp;'+this.tableLabel+'</h2>' : '';
    }

    get hasHelpText() {
        return (this.helpText && this.helpText.length > 0 && this.showInlineHelpText);
    }

    @wire(getObjectInfo, { objectApiName: '$objectName' })
    getObjectData({ error, data }) {
        if (data) {
            if (this.recordTypeId == null)
                this.recordTypeId = data.defaultRecordTypeId;
            this.apiFieldName = this.objectName + '.' + this.fieldName;
            this.columns  = [
                {label: data.fields[this.fieldName].label, fieldName: 'label', type: 'text'}
            ];
            this.helpText = data.fields[this.fieldName].inlineHelpText;
        } else if (error) {
            // Handle error
            console.log('==============getObjectDataError  ');
            console.log(error);
            console.log('objectName: '+ this.objectName);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {            
            // Map picklist values
            this.options = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            this.recId = this.recordID; // kick off getRecord now that we have picvals to select
        } else if (error) {
            // Handle error
            console.log('==============getPicklistValuesError  ' + error);
            console.log(error);
            console.log('recordTypeId: ' + this.recordTypeId);
            console.log('apiFieldName: ' + this.apiFieldName);
        }
    }
    
    @wire(getRecord, {recordId: '$recId', fields: '$apiFieldName'})
    wiredRecord({error, data}){
        if(data){
            let sVals = data.fields[this.fieldName].value;
            if(sVals){
                this.selectedValues = sVals;
                this.vals = sVals.split(";");
            } else {
                this.selectedValues = "";
                this.vals = [];
            }
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedValues', this.selectedValues));            
        } else if (error) {
            // Handle error
            console.log('==============wiredRecord  ' + error);
            console.log(error);
            console.log('recId: ' + this.recId);
            console.log('apiFieldName: ' + this.apiFieldName);
        }
    }

    connectedCallback() {
        this.tableHeight = 'height:' + this.tableHeight;
        this.borderClass = (this.tableBorder != false) ? 'slds-box' : '';
    }

    handleRowSelection(event) {
        let currentSelectedRows = event.detail.selectedRows;
        let sdata = '';
        currentSelectedRows.forEach(srow => {
            if(sdata == '')
                sdata = srow['value'];
            else
                sdata = sdata + ';' + srow['value'];
        });
        this.selectedValues = sdata; // Set output attribute values
        this.setIsInvalidFlag(false);
        if(this.isRequired && !this.selectedValues) {
            this.setIsInvalidFlag(true);
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedValues', this.selectedValues));
    }

    @api
    validate() {
        // Validation logic to pass back to the Flow
        if(!this.isRequired || this.selectedValues) { 
            this.setIsInvalidFlag(false);
            return { isValid: true }; 
        } 
        else { 
            // If the component is invalid, return the isValid parameter 
            // as false and return an error message. 
            this.setIsInvalidFlag(true);
            return { 
                isValid: false, 
                errorMessage: 'This is a required entry.  At least 1 row must be selected.' 
            }; 
        }
    }

    setIsInvalidFlag(value) {
        this.isInvalid = value;
    }
}