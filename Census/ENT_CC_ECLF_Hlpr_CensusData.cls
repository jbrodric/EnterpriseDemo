/*********************************************************************
Class   : ENT_CC_ECLF_Hlpr_CensusData
Author  : Jbrodrick
Date    : 07/09/2019
Details : Handles trigger logic for ENT_Census_Data__c. 
Test Class: TEST_TestCoverage_ECLF6
History : v1.0 - 07/09/2019 - Creation (100% Coverage)
**********************************************************************/
public with sharing class ENT_CC_ECLF_Hlpr_CensusData 
{
    public static boolean HasRun_ENT_CC_ECLF_CensusData_AfterTrigger = false;
    
    public static void OnAfterInsert(List<ENT_Census_Data__c> trigNew)
    {
        List<ENT_ECLFPropertyCensusData__c> lstPropCensusIns = new List<ENT_ECLFPropertyCensusData__c>();
        Map<String, List<ENT_Census_Data__c>> mapTractIdToData = new Map<String, List<ENT_Census_Data__c>>();
        
        for(ENT_Census_Data__c census : trigNew)
        {
            if(census.Census_Tract_ID__c != null)
            {
                if(!mapTractIdToData.containskey(census.Census_Tract_ID__c))
                    mapTractIdToData.put(census.Census_Tract_ID__c, new List<ENT_Census_Data__c>());
                
                mapTractIdToData.get(census.Census_Tract_ID__c).add(census);
            }
        }
        
        for(ENT_ECLF_Property__c prop : [SELECT Id, Census_Tract_ID__c FROM ENT_ECLF_Property__c WHERE Census_Tract_ID__c IN :mapTractIdToData.keySet()])
        {
            for(ENT_Census_Data__c census : mapTractIdToData.get(prop.Census_Tract_ID__c))
                lstPropCensusIns.add(new ENT_ECLFPropertyCensusData__c(ECLF_Property__c = prop.Id, Census_Data__c = census.Id, Active__c = true));
        }
        
        if(lstPropCensusIns.size() > 0)
            insert lstPropCensusIns;
    }
}