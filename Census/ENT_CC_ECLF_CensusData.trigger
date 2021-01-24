/*********************************************************************
Class   : ENT_CC_ECLF_CensusData
Author  : Jbrodrick
Date    : 07/09/2019
Details : Handles trigger events for ENT_Census_Data__c. 
Test Class: TEST_TestCoverage_ECLF6
History : v1.0 - 07/09/2019 - Creation (100% Coverage)
**********************************************************************/
trigger ENT_CC_ECLF_CensusData on ENT_Census_Data__c (after insert) 
{
    if(Trigger.isAfter && !ENT_CC_ECLF_Hlpr_CensusData.HasRun_ENT_CC_ECLF_CensusData_AfterTrigger)
    {
        ENT_CC_ECLF_Hlpr_CensusData.HasRun_ENT_CC_ECLF_CensusData_AfterTrigger = true;
        
        if(Trigger.isInsert)
        {
            ENT_CC_ECLF_Hlpr_CensusData.OnAfterInsert(Trigger.new);         
        }
    }
}