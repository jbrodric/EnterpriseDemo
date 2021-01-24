/***************************************************************
Class   : ENT_Batch_All_CensusGeocoding
Author  : John Brodrick
Date    : 06/14/2019
Details : Batch job to populate census geocoding data on all objects specified in CensusGeocodingSetting custom metadata
Test Class : TEST_ENT_ALL_CensusGeocodingUtils
History : v1.0 - 06/14/2019 - Created
*****************************************************************/
global class ENT_Batch_All_CensusGeocoding implements Database.batchable<sobject>, Database.AllowsCallouts, Database.Stateful, Schedulable 
{       
    global Integer customMetaDataSequence;
    global boolean processNextBatch;
    global CensusGeocodingSetting__mdt MetaDataRec;    
    global list<string> lstErrors = new list<string>();   

    // constructor
    public ENT_Batch_All_CensusGeocoding(Integer customMetaDataSequence, boolean processNextBatch)
    {
        this.processNextBatch = processNextBatch;
        this.customMetaDataSequence = customMetaDataSequence;
        MetaDataRec = null;
    }
    
    global ENT_Batch_All_CensusGeocoding()
    {        
        this.processNextBatch = true;
        this.customMetaDataSequence = 1;
        MetaDataRec = null;
    }

    global List<sObject> start(Database.BatchableContext BC)
    {
        List<sObject> retVal = new List<sObject>();
        
        try
        {
            MetaDataRec = ENT_All_CensusGeocodingServiceCallout.GetGeocodingObjectMetaBySeq(customMetaDataSequence);
            retVal = Database.query(MetaDataRec.Query__c);
        }
        catch(exception ex)
        {
            lstErrors.add('Method: start(Database.BatchableContext BC)<br/>Error: ' + ex.getMessage() + '<br/>Line Number: ' + ex.getLineNumber()); 
        }
        
        return retVal;
    }
    
    global void execute(SchedulableContext SC) 
    {
        try
        {            
            Database.executeBatch(new ENT_Batch_All_CensusGeocoding(), 1);
        }
        catch(exception ex)
        {
            lstErrors.add('Method: execute(SchedulableContext SC)<br/>Error: ' + ex.getMessage() + '<br/>Line Number: ' + ex.getLineNumber()); 
        }
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        String strCurrProperty;

        try
        {
            if(MetaDataRec != null)
            {
                list<sObject> lstRecUpdate = new list<sObject>();

                for(sObject s : scope)
                {
                    strCurrProperty = '';
                    ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse response;

                    if(!String.isBlank(MetaDataRec.Latitude_Y_Coord_Field_Name__c) &&
                        !String.isBlank(MetaDataRec.Longitude_X_Coord_Field_Name__c) &&
                        s.get(MetaDataRec.Latitude_Y_Coord_Field_Name__c) != null &&
                        s.get(MetaDataRec.Longitude_X_Coord_Field_Name__c) != null)
                    {
                        strCurrProperty = 'Object Name: ' + MetaDataRec.Object_Name__c + 'Id: ' + s.Id + 
                            '; Method: GeocodeByGeolocation; Latitude_Y_Coord_Field_Name__c: ' + 
                            ((Decimal)s.get(MetaDataRec.Latitude_Y_Coord_Field_Name__c)).format() + 
                            '; Longitude_X_Coord_Field_Name__c: ' + 
                            ((Decimal)s.get(MetaDataRec.Longitude_X_Coord_Field_Name__c)).format();

                        response = ENT_All_CensusGeocodingServiceCallout.GeocodeByGeolocation(
                            (Decimal)s.get(MetaDataRec.Latitude_Y_Coord_Field_Name__c),
                            (Decimal)s.get(MetaDataRec.Longitude_X_Coord_Field_Name__c));
                    }
                    else
                    {
                        strCurrProperty = 'Object Name: ' + MetaDataRec.Object_Name__c + 'Id: ' + s.Id + 
                            '; Method: GeocodeAddress; Address_Field_Name__c: ' + 
                            (string)s.get(MetaDataRec.Address_Field_Name__c) + 
                            '; City_Field_Name__c: ' + 
                            (string)s.get(MetaDataRec.City_Field_Name__c) + 
                            '; State_Field_Name__c: ' + 
                            (string)s.get(MetaDataRec.State_Field_Name__c) + 
                            '; Zip_Code_Field_Name__c: ' + 
                            (string)s.get(MetaDataRec.Zip_Code_Field_Name__c);

                        response = ENT_All_CensusGeocodingServiceCallout.GeocodeAddress(
                            (string)s.get(MetaDataRec.Address_Field_Name__c),(string)s.get(MetaDataRec.City_Field_Name__c),
                            (string)s.get(MetaDataRec.State_Field_Name__c),(string)s.get(MetaDataRec.Zip_Code_Field_Name__c));
                    }
                        
                    lstRecUpdate.add(ENT_All_CensusGeocodingServiceCallout.ProcessCensusResponse(response, s.Id, MetaDataRec, false));
                }
                
                if (!lstRecUpdate.isEmpty())
                    update lstRecUpdate;
            }
        }
        catch(exception ex)
        {
            lstErrors.add('Method: execute(Database.BatchableContext BC, List<sObject> scope)<br/>Error: ' +
                ex.getMessage() + '<br/>Line Number: ' + ex.getLineNumber() + '<br/>Current Property: ' + strCurrProperty); 
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
        try
        {
            if(lstErrors.size()>0 || test.isRunningTest())
            {
                String htmlBody = 'The job: ENT_Batch_All_CensusGeocoding has completed with errors.<br/><br/>';
                htmlBody += 'The following errors occured during processing:<br/><br/>';
                
                for(string s : lstErrors)
                    htmlBody += s + '<br/><br/>';
            
                htmlBody += 'This email is system generated, do not reply to this email.';
                
                // Create the message and send
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {'salesforceQueue@enterprisecommunity.com'};
                mail.setToAddresses(toAddresses);
                mail.setReplyTo('noreply@salesforce.com');
                mail.setSenderDisplayName('CensusGeocoding Batch Processing');
                mail.setSubject('CensusGeocoding Batch Job Completed with Errors');
                mail.setHtmlBody(htmlBody);
                
                if(!test.isRunningTest())
                {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }                   
            }
            else // no errrors then process the next object for geocoding
            {
                List<CensusGeocodingSetting__mdt> lstAllMetaDataRecs = [SELECT Id, Query__c FROM CensusGeocodingSetting__mdt];
                                                                        
                // updating batch number count 
                customMetaDataSequence = customMetaDataSequence + 1;
                
                // code to execute the next batch       
                if(lstAllMetaDataRecs != null   
                    && lstAllMetaDataRecs.size() >= customMetaDataSequence
                    && processNextBatch && !test.isRunningTest())
                {
                    database.executeBatch(new ENT_Batch_All_CensusGeocoding(customMetaDataSequence,true),1);
                }
            }
        }
        catch(exception ex)
        {        
            lstErrors.add('Method: finish(Database.BatchableContext BC).  Error: ' + ex.getMessage() 
                            + '.  Line Number: ' + ex.getLineNumber());
        }
        finally
        {   
            if(lstErrors.size()>0)
            {
                for(String s : lstErrors)
                    System.debug('Encountered Error Processing Batch: ' + s);
            }
        }
    }
}