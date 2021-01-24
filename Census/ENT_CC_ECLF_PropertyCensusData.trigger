/*********************************************************************
Class   : ENT_CC_ECLF_PropertyCensusData
Author  : Jbrodrick
Date    : 07/09/2019
Details : Handles trigger events for ENT_ECLFPropertyCensusData__c. 
Test Class: TEST_TestCoverage_ECLF6
History : v1.0 - 07/09/2019 - Creation (100% Coverage)
**********************************************************************/
trigger ENT_CC_ECLF_PropertyCensusData on ENT_ECLFPropertyCensusData__c (after insert, after update, after delete) 
{
    if(Trigger.isAfter && !ENT_CC_ECLF_Hlpr_PropertyCensusData.HasRun_ENT_CC_ECLF_PropertyCensusData_AfterTrigger)
    {
        ENT_CC_ECLF_Hlpr_PropertyCensusData.HasRun_ENT_CC_ECLF_PropertyCensusData_AfterTrigger = true;
        
        if(Trigger.isInsert)
        {
            ENT_CC_ECLF_Hlpr_PropertyCensusData.OnAfterInsert(Trigger.new);         
        }
        else if(Trigger.isUpdate)
        {
            ENT_CC_ECLF_Hlpr_PropertyCensusData.OnAfterUpdate(Trigger.new, Trigger.old);
        }
        else if(Trigger.isDelete)
        {
            ENT_CC_ECLF_Hlpr_PropertyCensusData.OnAfterDelete(Trigger.old); 
        }
    }
}