/*********************************************************************
Class   : ENT_CC_ECLF_Hlpr_PropertyCensusData
Author  : Jbrodrick
Date    : 07/09/2019
Details : Handles trigger logic for ENT_ECLFPropertyCensusData__c. 
Test Class: TEST_TestCoverage_ECLF6
History : v1.0 - 07/09/2019 - Creation (100% Coverage)
**********************************************************************/
public with sharing class ENT_CC_ECLF_Hlpr_PropertyCensusData 
{
    public static boolean HasRun_ENT_CC_ECLF_PropertyCensusData_AfterTrigger = false;
    
    public static void OnAfterInsert(List<ENT_ECLFPropertyCensusData__c> trigNew)
    {
        ENT_CC_ECLF_Hlpr_Property.RefreshAllCensusLookups(GetPropIdSet(trigNew));
    }
    
    public static void OnAfterUpdate(List<ENT_ECLFPropertyCensusData__c> trigNew, List<ENT_ECLFPropertyCensusData__c> trigOld)
    {       
        Set<Id> setPropIds = GetPropIdSet(trigNew);
        setPropIds.addAll(GetPropIdSet(trigOld));
        ENT_CC_ECLF_Hlpr_Property.RefreshAllCensusLookups(setPropIds);
    }
    
    public static void OnAfterDelete(List<ENT_ECLFPropertyCensusData__c> trigOld)
    {
        ENT_CC_ECLF_Hlpr_Property.RefreshAllCensusLookups(GetPropIdSet(trigOld));       
    }
    
    private static Set<Id> GetPropIdSet(List<ENT_ECLFPropertyCensusData__c> lstPropCensus)
    {
        Set<Id> ret = new Set<Id>();
        
        for(ENT_ECLFPropertyCensusData__c propCensus : lstPropCensus)
        {
            ret.add(propCensus.ECLF_Property__c);
        }
        
        return ret;
    }
}