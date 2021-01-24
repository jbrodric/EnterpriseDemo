/***************************************************************
Class   : ENT_All_CensusGeocodingServiceCallout
Author  : John brodrick
Date    : 6/13/2019
Details : Created to call census geocoding webservice to
          get metadata information like tract, block, state etc.
Test Class: TEST_ENT_ALL_CensusGeocodingUtils
History : v1.0 - 06/13/2019 - Created (xx% Code Coverage)
*****************************************************************/
public with sharing Class ENT_All_CensusGeocodingServiceCallout
{   
    private static final string META_QUERY_SELECT_FROM;

    static
    {
        META_QUERY_SELECT_FROM = 'SELECT Id, Block_Field_Name__c, Block_Group_Field_Name__c, Census_Geocoding_Date_Field_Name__c, Census_Geocoding_Result_Field_Name__c, Census_Geocoding_Status_Field_Name__c, County_Code_Field_Name__c, Object_Name__c, Query__c, Sequence__c, State_Code_Field_Name__c, Tract_Field_Name__c, Address_Field_Name__c, City_Field_Name__c, State_Field_Name__c, Zip_Code_Field_Name__c, Latitude_Y_Coord_Field_Name__c, Longitude_X_Coord_Field_Name__c, County_Field_Name__c FROM CensusGeocodingSetting__mdt ';
    }

    private static String formatAddressForURL(String streetLine1, String city, String state, String postalCode)
    {
        String retVal = '';
        
        if(String.isNotBlank(streetLine1))
            retVal += 'street=' + EncodingUtil.urlEncode(streetLine1, 'UTF-8');
        
        if(String.isNotBlank(city))
        {
            if(retVal != '')
                retVal += '&';
            
            retVal += 'city=' + EncodingUtil.urlEncode(city, 'UTF-8');          
        }
        
        if(String.isNotBlank(state))
        {
            if(retVal != '')
                retVal += '&';
            
            retVal += 'state=' + EncodingUtil.urlEncode(state, 'UTF-8');            
        }
        
        if(String.isNotBlank(postalCode))
        {
            if(retVal != '')
                retVal += '&';
            
            retVal += 'zip=' + EncodingUtil.urlEncode(postalCode, 'UTF-8');         
        }
        
        return  retVal;
    }
    
    public static ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse GeocodeAddress(string streetLine1, 
        string city, string state, string postalCode) 
    {       
        ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse retVal = new 
            ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse(streetLine1, city, state, postalCode);
        
        if(String.isNotBlank(streetLine1) && streetLine1.Length() <= 100 &&
            (String.isBlank(city) || city.Length() <= 40) && 
            (String.isBlank(state) || state.Length() <= 20) && 
            (String.isBlank(postalCode) || postalCode.Length() <= 10) &&
            ((String.isNotBlank(city) && String.isNotBlank(state)) || String.isNotBlank(postalCode))
        )
        {           
            HTTP http = new HTTP(); 
            HTTPRequest req = new HTTPRequest();
            HttpResponse response = new HttpResponse();
            String endpoint = 'https://geocoding.geo.census.gov/geocoder/geographies/address?' + 
                formatAddressForURL(streetLine1, city, state, postalCode) + 
                '&benchmark=Public_AR_Current&vintage=Current_Current&layers=12,86&format=json';
            
            req.setendpoint(endpoint);
            req.setmethod('GET');
            req.setHeader('Content-Type', 'text/json; charset=utf-8');
            req.setTimeout(120000);
                        
            response = http.send(req);
                             
            if(response.getStatusCode() < 300 && response.getStatusCode() > 199)
            { 
                if(response.getBody() != null && response.getBody() != '')
                {
                    Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    
                    if(root.containsKey('errors'))
                    {
                        retVal.isValid = false;
                        
                        for(String s : (List<String>)root.get('errors'))                
                            retVal.ErrorMessage += s + ';';
                    }
                    else if(root.containsKey('result'))
                    {
                        List<Object> lstAddressMatches = (List<Object>)((Map<String, Object>)
                            root.get('result')).get('addressMatches');
                        
                        if(lstAddressMatches.size() > 0)
                        {
                            List<Object> lstCensusBlocks = (List<Object>)(((Map<String, Object>)((Map<String, Object>)
                                lstAddressMatches[0]).get('geographies')).get('2010 Census Blocks'));

                            if(lstCensusBlocks.size() > 0)
                            {
                                Map<String, Object> censusBlock = (Map<String, Object>)lstCensusBlocks[0];
                                
                                retVal.isValid = true;
                                retVal.BlockGroup = (String)censusBlock.get('BLKGRP');
                                retVal.Block = (String)censusBlock.get('BLOCK');
                                retVal.Tract = (String)censusBlock.get('TRACT');
                                retVal.CountyCode = (String)censusBlock.get('COUNTY');
                                retVal.StateCode = (String)censusBlock.get('STATE');
                            }
                            else
                            {
                                retVal.isValid = false;
                                retVal.ErrorMessage = 'No census block data for address';                           
                            }

                            if(((Map<String, Object>)((Map<String, Object>)lstAddressMatches[0]).get('geographies')).containsKey('Counties'))
                            {
                            // System.debug('GbA: Has Counties');
                                List<Object> lstCounties = (List<Object>)(((Map<String, Object>)((Map<String, Object>)
                                    lstAddressMatches[0]).get('geographies')).get('Counties'));

                                if(lstCounties.size() >0)
                                {
                            // System.debug('GbA: Has County');
                                    Map<String, Object> county = (Map<String, Object>)lstCounties[0];

                            // System.debug('(String)county.get(NAME): ' + (String)county.get('NAME'));
                                    retVal.County = (String)county.get('NAME');
                                }
                            }
                        }
                        else
                        {
                            retVal.isValid = false;
                            retVal.ErrorMessage = 'Invalid address - Unable to find match';                         
                        }   
                    }
                    else
                    {
                        retVal.isValid = false;
                        retVal.ErrorMessage = 'Unknown Response Format';
                    }
                }
                else
                    throw new CensusResponseException('Census Response Body Empty');      
            }
            else
                throw new CensusResponseException('Did not receive successful response from Census Site. ' + 
                    'HTTP_Status_Code: ' + response.getStatusCode() + ', HTTP_Status: ' + response.getStatus());  
        }
        else
        {
            retVal.isValid = false;
            retVal.ErrorMessage = 'Specify street with city and state or street with zip.  Street address cannot be empty ' + 
                'and cannot exceed 100 characters.  City cannot exceed 40 characters, state cannot exceed 20 ' +
                'characters, and ZIP code cannot exceed 10 characters.';
        }
        
        return retVal;
    }

    public static ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse GeocodeByGeolocation(Decimal dLatYCoord, 
        Decimal dLonXCoord) 
    {
        ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse retVal = new 
            ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse(dLatYCoord, dLonXCoord);
        
        if(dLatYCoord != null && dLonXCoord != null)
        {           
            HTTP http = new HTTP(); 
            HTTPRequest req = new HTTPRequest();
            HttpResponse response = new HttpResponse();
            String endpoint = ' https://geocoding.geo.census.gov/geocoder/geographies/coordinates?' + 
                'x=' + dLonXCoord + '&y=' + dLatYCoord + 
                '&benchmark=Public_AR_Current&vintage=Current_Current&layers=12,86&format=json';
            // system.debug('## DEBUG :: '+endpoint);          
            
            req.setendpoint(endpoint);
            req.setmethod('GET');
            req.setHeader('Content-Type', 'text/json; charset=utf-8');
            req.setTimeout(120000);
                        
            response = http.send(req);
                             
            if(response.getStatusCode() < 300 && response.getStatusCode() > 199)
            { 
                if(response.getBody() != null && response.getBody() != '')
                {
                    // System.debug('Response: ' + response.getBody());
                
                    Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    
                    if(root.containsKey('errors'))
                    {
                        retVal.isValid = false;
                        
                        for(String s : (List<String>)root.get('errors'))                
                            retVal.ErrorMessage += s + ';';
                    }
                    else if(root.containsKey('result'))
                    {
                        List<Object> lstCensusBlocks = (List<Object>)(((Map<String, Object>)(
                            (Map<String, Object>)root.get('result')).get('geographies')).get('2010 Census Blocks'));
                        
                        if(lstCensusBlocks.size() > 0)
                        {
                            Map<String, Object> censusBlock = (Map<String, Object>)lstCensusBlocks[0];
                            
                            retVal.isValid = true;
                            retVal.BlockGroup = (String)censusBlock.get('BLKGRP');
                            retVal.Block = (String)censusBlock.get('BLOCK');
                            retVal.Tract = (String)censusBlock.get('TRACT');
                            retVal.CountyCode = (String)censusBlock.get('COUNTY');
                            retVal.StateCode = (String)censusBlock.get('STATE');
                        }
                        else
                        {
                            retVal.isValid = false;
                            retVal.ErrorMessage = 'No census block data for address';                           
                        }
                        
                        if(((Map<String, Object>)((Map<String, Object>)root.get('result')).get('geographies')).containsKey('Counties'))
                        {
                            // System.debug('GbG: Has Counties');
                            List<Object> lstCounties = (List<Object>)(((Map<String, Object>)(
                                (Map<String, Object>)root.get('result')).get('geographies')).get('Counties'));

                            if(lstCounties.size() >0)
                            {
                                // System.debug('GbG: Has County');
                                Map<String, Object> county = (Map<String, Object>)lstCounties[0];

                                // System.debug('GbG:(String)county.get(NAME): ' + (String)county.get('NAME'));
                                retVal.County = (String)county.get('NAME');
                            }
                        }
                    }
                    else
                    {
                        retVal.isValid = false;
                        retVal.ErrorMessage = 'Unknown Response Format';
                    }
                }
                else
                    throw new CensusResponseException('Census Response Body Empty');      
            }
            else
                throw new CensusResponseException('Did not receive successful response from Census Site. ' + 
                    'HTTP_Status_Code: ' + response.getStatusCode() + ', HTTP_Status: ' + response.getStatus());  
        }
        else
        {
            retVal.isValid = false;
            retVal.ErrorMessage = 'Lat and Lon can not be null';
        }
        
        return retVal;
    }
    
    // Future Methods
    // Can be called from triggers to handle on demand refresh.  Pass in the record ID you want to update and the 
    // CensusGeocodingSettingName which corresponds to the unique developername of the CensusGeocodingSetting__mdt 
    // record that specifies the object metadata
    // addFutureTag - Set to true if you want this method to append the string <FUTURE> to the Tract_Field_Name__c.  
    //                This way you can tell the tract was system generated (and subsequently strip off the tag) 
    //                and not entered by a user. Set to false if you do not want this appended (updates to just 
    //                plain census tract value) - most likely use case
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @future (callout=true)
    public static void GeocodeByGeolocationFuture(Decimal dLatYCoord, Decimal dLonXCoord, 
        Id RecordIdUpd, String CensusGeocodingSettingName, Boolean addFutureTag) 
    {   
        try
        {
            update ProcessCensusResponse(
                ENT_All_CensusGeocodingServiceCallout.GeocodeByGeolocation(dLatYCoord, dLonXCoord),
                RecordIdUpd, GetGeocodingObjectMetaByName(CensusGeocodingSettingName), addFutureTag);
        }
        catch (exception ex)
        {
            System.debug('Error in GeocodeByGeolocationFuture: ' + ex.getMessage() + '<br/>Line Number: ' + 
                ex.getLineNumber());
            System.debug('dLatYCoord: ' + dLatYCoord + ', dLonXCoord: ' + dLonXCoord + 
                ', RecordIdUpd: ' + RecordIdUpd + ',  CensusGeocodingSettingName: ' + 
                CensusGeocodingSettingName);
        }
    }
    
    @future (callout=true)
    public static void GeocodeAddressFuture(string streetLine1, string city, string state, string postalCode, 
        Id RecordIdUpd, String CensusGeocodingSettingName, Boolean addFutureTag) 
    {   
        try
        {            
            update ProcessCensusResponse(
                ENT_All_CensusGeocodingServiceCallout.GeocodeAddress(streetLine1,city, state, postalCode),
                RecordIdUpd, GetGeocodingObjectMetaByName(CensusGeocodingSettingName), addFutureTag);
        }
        catch (exception ex)
        {
            System.debug('Error in GeocodeAddressFuture: ' + ex.getMessage() + '<br/>Line Number: ' + 
                ex.getLineNumber());
            System.debug('streetLine1: ' + streetLine1 + ', city: ' + city + ', state: ' + state + ', postalCode: ' + 
                postalCode + ', RecordIdUpd: ' + RecordIdUpd + ',  CensusGeocodingSettingName: ' + 
                CensusGeocodingSettingName);
        }
    }

    public static CensusGeocodingSetting__mdt GetGeocodingObjectMetaByName(String CensusGeocodingSettingName)
    {
        String meta_query = META_QUERY_SELECT_FROM + ' WHERE DeveloperName = \'' + CensusGeocodingSettingName + '\' LIMIT 1';
        
        List<CensusGeocodingSetting__mdt> lstMeta =  Database.query(meta_query);
        
        if(lstMeta.size() == 0)
            throw new CensusException('CensusGeocodingSetting ' + CensusGeocodingSettingName + ' does not exist.');  
            
        return lstMeta[0];
    }

    public static CensusGeocodingSetting__mdt GetGeocodingObjectMetaBySeq(Integer customMetaDataSequence)
    {
        String meta_query = META_QUERY_SELECT_FROM + ' WHERE Sequence__c = ' + String.valueOf(customMetaDataSequence) + ' LIMIT 1';
        // System.debug('meta_query: ' + meta_query);
        List<CensusGeocodingSetting__mdt> lstMeta =  Database.query(meta_query);
        
        if(lstMeta.size() == 0)
            throw new CensusException('CensusGeocodingSetting specified by sequence: ' + String.valueOf(customMetaDataSequence) + ' does not exist.');  
            
        return lstMeta[0];
    }

    public static sObject ProcessCensusResponse(ENT_All_CensusGeocodingServiceCallout.CensusGeocodingResponse response, 
        Id RecordIdUpd, CensusGeocodingSetting__mdt MetaDataRec, Boolean addFuture)
    {
        String futureTag = addFuture ? '<FUTURE>' : '';       
        sObject sObj = Schema.getGlobalDescribe().get(MetaDataRec.Object_Name__c).newSObject();
        sObj.Id = (ID)RecordIdUpd;
        
        if(response.isValid)
        {
            sObj.put(MetaDataRec.Block_Group_Field_Name__c, response.BlockGroup);
            sObj.put(MetaDataRec.Block_Field_Name__c, response.Block);
            sObj.put(MetaDataRec.Tract_Field_Name__c, response.Tract + futureTag);
            sObj.put(MetaDataRec.County_Code_Field_Name__c, response.CountyCode);
            sObj.put(MetaDataRec.State_Code_Field_Name__c, response.StateCode);
            sObj.put(MetaDataRec.Census_Geocoding_Date_Field_Name__c, System.now());
            sObj.put(MetaDataRec.Census_Geocoding_Result_Field_Name__c, 'Geocoding Succeeded');
            sObj.put(MetaDataRec.Census_Geocoding_Status_Field_Name__c, 'Geocoding Succeeded');

            if(!String.isBlank(MetaDataRec.County_Field_Name__c))
                sObj.put(MetaDataRec.County_Field_Name__c, response.County);
        }
        else
        {
            sObj.put(MetaDataRec.Block_Group_Field_Name__c, '');
            sObj.put(MetaDataRec.Block_Field_Name__c, '');
            sObj.put(MetaDataRec.Tract_Field_Name__c, '' + futureTag);
            sObj.put(MetaDataRec.County_Code_Field_Name__c, '');
            sObj.put(MetaDataRec.State_Code_Field_Name__c, '');
            sObj.put(MetaDataRec.Census_Geocoding_Date_Field_Name__c, System.now());
            sObj.put(MetaDataRec.Census_Geocoding_Result_Field_Name__c, response.ErrorMessage);
            sObj.put(MetaDataRec.Census_Geocoding_Status_Field_Name__c, 'Geocoding Failure');           
        }
        
        return sObj;   
    }
    
    public class CensusGeocodingResponse
    {       
        public Boolean isValid;
        public String ErrorMessage{get; set;}
        
        // geocoding result
        public String BlockGroup { get; set; }
        public String Block { get; set; }
        public String Tract { get; set; }
        public String CountyCode { get; set; }
        public String StateCode { get; set; }   
        public String County {get;set;}
        
        // This is the address that the geocoding result is for
        public String StoredStreetLine1 { get; set; }
        public String StoredCity { get; set; }
        public String StoredState { get; set; }
        public String StoredPostalCode { get; set; }

        // These are the Lat (y) Lon (x) coordinates that the geocoding result is for
        public Decimal StoredLatYCoord {get; set;}
        public Decimal StoredLonXCoord {get; set;}
        
        public CensusGeocodingResponse(Decimal lat, Decimal lon)
        {
            InitFields();
            StoredLatYCoord = lat;
            StoredLonXCoord = lon;
        }

        public CensusGeocodingResponse(String streetLine1, String city, String state, String postalCode)
        {
            InitFields();
            StoredStreetLine1 = streetLine1;
            StoredCity = city;
            StoredState = state;
            StoredPostalCode = postalCode;
        }

        private void InitFields()
        {
            isValid = false;
            ErrorMessage = '';
            BlockGroup = '';
            Block = '';
            Tract = '';
            CountyCode = '';
            StateCode = '';
            County = '';
        }
    }
    
    public class CensusResponseException extends Exception{}
    public class CensusException extends Exception{}
}