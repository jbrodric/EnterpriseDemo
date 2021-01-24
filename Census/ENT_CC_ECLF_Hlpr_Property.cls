/***************************************************************
Class   : ENT_CC_ECLF_Hlpr_Property
Author  : John Brodrick
Date    : 06/20/2019
Details : Trigger helper for ECLF Property trigger
Test Class: TEST_TestCoverage_ECLF6
History : v1.0 - 06/20/2019 - Created (91% Coverage)
          v1.1 - 09/12/2019 - Census data manually/system verified (95% cvg)
*****************************************************************/
public with sharing Class ENT_CC_ECLF_Hlpr_Property
{
    public static boolean HasRun_ENT_CC_ECLF_Hlpr_Property_BeforeTrigger = false;
    public static boolean HasRun_ENT_CC_ECLF_Hlpr_Property_AfterTrigger = false;
        
    public static void OnAfterInsert(List<ENT_ECLF_Property__c> lstTrigNew)
    {
        UpdateCensusMetaInFuture(lstTrigNew);
        UpdateGeolocationInFuture(lstTrigNew);
        InsertPropertyCensusData(lstTrigNew);
    }
    
    public static void OnBeforeUpdate(List<ENT_ECLF_Property__c> lstTrigNew, Map<Id, ENT_ECLF_Property__c> mapOld)
    {
        Set<ENT_ECLF_Property__c> setUpdCensus = new Set<ENT_ECLF_Property__c>();
        Set<ENT_ECLF_Property__c> setUpdGeoloc = new Set<ENT_ECLF_Property__c>();

        for(ENT_ECLF_Property__c prop : lstTrigNew)
        {
            ENT_ECLF_Property__c oldProp = mapOld.get(prop.Id);
            
            if(prop.Street_Address_Line_1__c != oldProp.Street_Address_Line_1__c ||
                prop.City__c != oldProp.City__c || prop.State__c != oldProp.State__c ||
                prop.Zip_Code__c != oldProp.Zip_Code__c)
            {
                if(!String.isBlank(prop.Street_Address_Line_1__c) ||
                    !String.isBlank(prop.City__c) ||
                    !String.isBlank(prop.State__c) ||
                    !String.isBlank(prop.Zip_Code__c)
                )
                {
                    prop.GeoLocation__c = null;
                    setUpdCensus.add(prop);
                    setUpdGeoloc.add(prop);
                }
            }
            
            if(prop.GeoLocation__c != oldProp.GeoLocation__c)
            {
                // Updated by the future call in this trigger (when a user upd the property address)
                if(prop.GeoLocation__c != null && prop.GeoLocation__c.contains('<FUTURE>'))
                {
                    prop.GeoLocation__c = prop.GeoLocation__c.replace('<FUTURE>', '');
                    prop.Address_Verification_Type__c = 'System Verified';
                }
                // Updated by the batch job
                else if(UserInfo.getUserEmail() == 'salesforcequeue@enterprisecommunity.com')
                {
                    prop.Address_Verification_Type__c = 'System Verified';
                    setUpdCensus.add(prop);
                }            
                // if a power user blanks the geolocation    
                else if(String.isBlank(prop.GeoLocation__c))
                {
                    prop.Address_Verification_Type__c = null;    
                    prop.Address_Verification_Result__c = null;
                    prop.Address_Verification_Status__c = null;
                    prop.Address_Verification_Date__c = null;
                }
                // manual edit by a power user of geolocation field
                else
                {
                    prop.Address_Verification_Type__c = 'Manually Verified';    
                    prop.Address_Verification_Result__c = 'Verification Succeeded';
                    prop.Address_Verification_Status__c = 'Verification Succeeded';
                    prop.Address_Verification_Date__c = System.now(); 
                    setUpdCensus.add(prop);               
                }
            }

            if(prop.Block_Group__c != oldProp.Block_Group__c ||
                prop.Block__c != oldProp.Block__c ||
                prop.State_Code__c != oldProp.State_Code__c ||
                prop.County_Code__c != oldProp.County_Code__c || prop.Tract__c != oldProp.Tract__c)
            {
                // Updated by the future call in this trigger (when a user upd the property address)
                if(prop.Tract__c != null && prop.Tract__c.contains('<FUTURE>'))
                {
                    prop.Tract__c = prop.Tract__c.replace('<FUTURE>', '');
                    prop.Census_Verification_Type__c = 'System Verified';
                }
                // Updated by the batch job
                else if(UserInfo.getUserEmail() == 'salesforcequeue@enterprisecommunity.com')
                {
                    prop.Census_Verification_Type__c = 'System Verified';
                }            
                // if a power user blanks the census fields    
                else if(String.isBlank(prop.Block_Group__c) && String.isBlank(prop.Block__c) && 
                    String.isBlank(prop.State_Code__c) && String.isBlank(prop.County_Code__c) && 
                    String.isBlank(prop.Tract__c))
                {
                    prop.Census_Verification_Type__c = null;    
                    prop.Census_Geocoding_Result__c = null;
                    prop.Census_Geocoding_Status__c = null;
                    prop.Census_Geocoding_Date__c = null;
                }
                // manual edit by a power user of census fields
                else
                {
                    prop.Census_Verification_Type__c = 'Manually Verified';    
                    prop.Census_Geocoding_Result__c = 'Geocoding Succeeded';
                    prop.Census_Geocoding_Status__c = 'Geocoding Succeeded';
                    prop.Census_Geocoding_Date__c = System.now();                
                }
            }
        }
        
        if(setUpdCensus.size() > 0)
            UpdateCensusMetaInFuture(new List<ENT_ECLF_Property__c>(setUpdCensus));
        
        if(setUpdGeoloc.size() > 0)
            UpdateGeolocationInFuture(new List<ENT_ECLF_Property__c>(setUpdGeoloc));
    }
    
    public static void OnAfterUpdate(List<ENT_ECLF_Property__c> lstTrigNew, Map<Id, ENT_ECLF_Property__c> mapOld)
    {
        Map<Id, ENT_ECLF_Property__c> mapUpdPropertyCensus = new Map<Id, ENT_ECLF_Property__c>();
        
        for(ENT_ECLF_Property__c prop : lstTrigNew)
        {
            ENT_ECLF_Property__c oldProp = mapOld.get(prop.Id);
            
            if(prop.Census_Tract_ID__c != oldProp.Census_Tract_ID__c)
            {
                mapUpdPropertyCensus.put(prop.Id, prop);
            }
        }
        
        if(mapUpdPropertyCensus.size() > 0)
            UpdatePropertyCensusData(mapUpdPropertyCensus);
    }
    
    private static void UpdatePropertyCensusData(Map<Id, ENT_ECLF_Property__c> mapNewProps)
    {
        List<ENT_ECLFPropertyCensusData__c> lstUpd = new List<ENT_ECLFPropertyCensusData__c>();
        List<ENT_ECLFPropertyCensusData__c> lstDel = new List<ENT_ECLFPropertyCensusData__c>();
        
        for(ENT_ECLFPropertyCensusData__c propCensus : [SELECT Id, ECLF_Property__c, Census_Data__r.Census_Tract_ID__c, Active__c FROM ENT_ECLFPropertyCensusData__c WHERE ECLF_Property__c IN :mapNewProps.keySet()])
        {
            ENT_ECLF_Property__c prop = mapNewProps.get(propCensus.ECLF_Property__c);
            
            if(propCensus.Census_Data__r.Census_Tract_ID__c == prop.Census_Tract_ID__c)
                lstDel.add(propCensus);
            else if(propCensus.Active__c == true)
            {
                propCensus.Active__c = false;
                lstUpd.add(propCensus);
            }
        }
        
        ENT_CC_ECLF_Hlpr_PropertyCensusData.HasRun_ENT_CC_ECLF_PropertyCensusData_AfterTrigger = true; //disable trigger - we will do manually
        
        if(lstUpd.size()>0)
            update lstUpd;
        if(lstDel.size()>0)
            delete lstDel;
                
        InsertPropertyCensusData(mapNewProps.values());
        RefreshAllCensusLookups(mapNewProps.keySet());
    }
    
    private static void InsertPropertyCensusData(List<ENT_ECLF_Property__c> lstProps)
    {
        List<ENT_ECLFPropertyCensusData__c> lstPropCensusIns = new List<ENT_ECLFPropertyCensusData__c>();
        Map<String, List<ENT_ECLF_Property__c>> mapTractIdToProps = new Map<String, List<ENT_ECLF_Property__c>> ();
        
        for(ENT_ECLF_Property__c prop : lstProps)
        {
            if(prop.Census_Tract_ID__c != null)
            {
                if(!mapTractIdToProps.containskey(prop.Census_Tract_ID__c))
                    mapTractIdToProps.put(prop.Census_Tract_ID__c, new List<ENT_ECLF_Property__c>());
                
                mapTractIdToProps.get(prop.Census_Tract_ID__c).add(prop);
            }
        }
        
        for(ENT_Census_Data__c census : [SELECT Id, Census_Tract_ID__c FROM ENT_Census_Data__c WHERE Census_Tract_ID__c IN :mapTractIdToProps.keySet()])
        {
            for(ENT_ECLF_Property__c prop : mapTractIdToProps.get(census.Census_Tract_ID__c))
                lstPropCensusIns.add(new ENT_ECLFPropertyCensusData__c(ECLF_Property__c = prop.Id, Census_Data__c = census.Id, Active__c = true));
        }
        
        if(lstPropCensusIns.size() > 0)
            insert lstPropCensusIns;
    }
    
    private static void UpdateCensusMetaInFuture(List<ENT_ECLF_Property__c> lstProp)
    {
        for(ENT_ECLF_Property__c prop : lstProp)
        {
            if(prop.Geolocation__c != null)
            {
                List<String> lstLatLon = prop.Geolocation__c.replace('(','').replace(')','').replace(' ','').split(',');
                
                if(lstLatLon.size() == 2)
                {
                    ENT_All_CensusGeocodingServiceCallout.GeocodeByGeolocationFuture(
                        Decimal.valueOf(lstLatLon[0]), Decimal.valueOf(lstLatLon[1]), prop.Id, 'ECLF_Property', true);
                }
            }
            else
            {
                ENT_All_CensusGeocodingServiceCallout.GeocodeAddressFuture(
                    prop.Street_Address_Line_1__c, prop.City__c, prop.State__c, prop.Zip_Code__c, prop.Id, 'ECLF_Property', true);
            }
        }
    }
    
    private static void UpdateGeolocationInFuture(List<ENT_ECLF_Property__c> lstProp)
    {
        for(ENT_ECLF_Property__c prop : lstProp)
            ENT_AddGVerificationServiceCallout.ValidateAddressFuture(prop.Street_Address_Line_1__c, prop.City__c, 
                prop.State__c, prop.Zip_Code__c, prop.Id, 'ECLF_Property', true);
    }
        
    // Refreshes the lookups on the ECLF property for census data (Most_Recent_Census_Data__c, Origination_Census_Data__c)
    public static void RefreshAllCensusLookups(Set<Id> setPropIds)
    {
        Map<Id, ENT_ECLF_Property__c> mapPropIdToProp = new Map<Id, ENT_ECLF_Property__c>();
        Map<Id, Integer> mapPropIdToRecentYear = new Map<Id, Integer>();
        Map<Id, Integer> mapPropIdToCMFLendingProgram = new Map<Id, Integer>();
        
        for(Id propId : setPropIds)
        {
            mapPropIdToProp.put(propId, new ENT_ECLF_Property__c(Id = propId, Most_Recent_Census_Data__c = null));
            mapPropIdToRecentYear.put(propId, null);
            mapPropIdToCMFLendingProgram.put(propId, null);
        }
        
        // We only update the Origination_Census_Data__c on the property if it is null.  Once it is set it is only updated manually by the user.
        // So only query for and calculate the CMF value if the property's Origination_Census_Data__c is null
        for(ECLF_Loan_Property__c loanProp : [SELECT Id, ECLF_Property__c, ECLF_Loan__r.Lending_Program__c FROM ECLF_Loan_Property__c WHERE ECLF_Property__c IN :setPropIds AND ECLF_Property__r.Origination_Census_Data__c = null])
        {
            Integer currCMFLendingProgram = (mapPropIdToCMFLendingProgram.get(loanProp.ECLF_Property__c) != null ? mapPropIdToCMFLendingProgram.get(loanProp.ECLF_Property__c) : -1);
            Integer loanPropCMFYear = -1;
            
            if(String.isNotBlank(loanProp.ECLF_Loan__r.Lending_Program__c))
            {
                for(String strLendProg : loanProp.ECLF_Loan__r.Lending_Program__c.split(';'))
                {
                    if(strLendProg.contains('CMF'))
                    {
                        Integer cmfYear = Integer.valueOf(strLendProg.replace('CMF','').trim());
                        
                        if(cmfYear > loanPropCMFYear)
                            loanPropCMFYear = cmfYear;
                    }
                }
            }
            
            if(loanPropCMFYear > currCMFLendingProgram)
                mapPropIdToCMFLendingProgram.put(loanProp.ECLF_Property__c, loanPropCMFYear);
        }
        
        for(ENT_ECLFPropertyCensusData__c propCensus : [SELECT Id, ECLF_Property__c, Census_Data__c, Census_Data__r.Year__c, Active__c FROM ENT_ECLFPropertyCensusData__c WHERE ECLF_Property__c IN :setPropIds])
        {
            Integer currMostRecentYear = (mapPropIdToRecentYear.get(propCensus.ECLF_Property__c) != null ? mapPropIdToRecentYear.get(propCensus.ECLF_Property__c) : -1);
            Integer propCensusYear = (String.isNotBlank(propCensus.Census_Data__r.Year__c) ? Integer.valueOf(propCensus.Census_Data__r.Year__c) : -1);
            ENT_ECLF_Property__c prop = mapPropIdToProp.get(propCensus.ECLF_Property__c);
            
            if(propCensusYear > currMostRecentYear && propCensus.Active__c)
            {
                prop.Most_Recent_Census_Data__c = propCensus.Census_Data__c;
                mapPropIdToRecentYear.put(propCensus.ECLF_Property__c, propCensusYear);
            }
            
            if(mapPropIdToCMFLendingProgram.get(propCensus.ECLF_Property__c) != null && propCensusYear == mapPropIdToCMFLendingProgram.get(propCensus.ECLF_Property__c))
            {
                if(prop.Origination_Census_Data__c == null || propCensus.Active__c)
                    prop.Origination_Census_Data__c = propCensus.Census_Data__c;
            }
        }

        for(ENT_ECLF_Property__c dbProp : [SELECT id, Origination_Census_Data__c FROM ENT_ECLF_Property__c WHERE Id IN :setPropIds AND Origination_Census_Data__c = null])
        {
            ENT_ECLF_Property__c updProp = mapPropIdToProp.get(dbProp.id);

            if(updProp.Origination_Census_Data__c == null) // if we still don't have a value for origination census default it to match the most recent data
                updProp.Origination_Census_Data__c = updProp.Most_Recent_Census_Data__c;
        }
        
        if(mapPropIdToProp.values().size() > 0)
            update mapPropIdToProp.values();
    }
}