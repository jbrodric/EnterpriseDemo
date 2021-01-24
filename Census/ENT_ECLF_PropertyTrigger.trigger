/*********************************************************************
Class   : ENT_ECLF_PropertyTrigger
Author  : SHadavale
Details : Trigger will validate single primary property per Project and roll up
          required fields from primary Property to Project. 
History : v1.0 - 08/28/2014 - Creation (100% Coverage)
          v1.1 - 12/11/2014 - Blank street case handled (89% Coverage)
          v1.2 - 10/20/2015 - Updated to move CIIS X and Y Coordinates of primary property to Project for CIIS reporting. (91% Coverage)
          v1.3 - 10/09/2017 - AKohakade - ECLF-933 Added exception handling while Property updation at line 76, shows custom error message came form ENT_ECLF_ProjectTrigger. 
          v1.4 - 02/14/2018 - RMorada - Added functionaltiy to populate Development Stage Description based on Development Stage value. (ECLF-978)
          v1.5 - 06/20/2019 - Jbrodrick - Adding functionality to update census metadata when addr changes (CREAT-1505)
**********************************************************************/
trigger ENT_ECLF_PropertyTrigger on ENT_ECLF_Property__c (before insert, before update, after insert, after update)
{
    // v1.5 start
    if(Trigger.isBefore && !ENT_CC_ECLF_Hlpr_Property.HasRun_ENT_CC_ECLF_Hlpr_Property_BeforeTrigger)
    {
        ENT_CC_ECLF_Hlpr_Property.HasRun_ENT_CC_ECLF_Hlpr_Property_BeforeTrigger = true;
        
        if(Trigger.isUpdate)
        {
            ENT_CC_ECLF_Hlpr_Property.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    else if(Trigger.isAfter && !ENT_CC_ECLF_Hlpr_Property.HasRun_ENT_CC_ECLF_Hlpr_Property_AfterTrigger)
    {
        ENT_CC_ECLF_Hlpr_Property.HasRun_ENT_CC_ECLF_Hlpr_Property_AfterTrigger = true;
        
        if(Trigger.isInsert)
        {
            ENT_CC_ECLF_Hlpr_Property.OnAfterInsert(Trigger.new);
        }   
        else if(Trigger.isUpdate)
        {
            ENT_CC_ECLF_Hlpr_Property.OnAfterUpdate(Trigger.new, Trigger.oldMap);        
        } 
    }
    // v1.5 end - I left the the code below as is, but it should be moved into the helper and called using the format above
    
    Profile integrationProfile = ENT_ConstantHelper.IntegrationProfile;
    
    if(integrationProfile != null && userinfo.getProfileID() != integrationProfile.Id)
    {
        Set<ID> setProjectIds = new Set<ID>();
        Map<ID, ENT_ECLF_Project__c> mapPropertyProject;
        List<ENT_ECLF_Project__c> lstProjects = new List<ENT_ECLF_Project__c>();
        List<ECLF_Picklist_Description__c> picklistDescriptionList; //v1.4
        Map<String, String> picklistDescriptionMap = new Map<String,String>(); //v1.4
        //RecordType crmTaskRecordType = [SELECT Id, Name FROM RecordType WHERE Name ='CRM Task' LIMIT 1];//v1.4
        //List<Task> newTaskList = new List<Task>();//v1.4

        for(ENT_ECLF_Property__c eclfProperty : Trigger.new)
        {
            setProjectIds.add(eclfProperty.ECLF_Project__c);
        }
        
        mapPropertyProject = new map<ID, ENT_ECLF_Project__c>([SELECT Id, name, (SELECT Id, Primary__c FROM ECLF_Properties__r) FROM ENT_ECLF_Project__c WHERE Id IN: setProjectIds]); 
        //v1.4 Start
        picklistDescriptionList = [SELECT Id, Picklist_Value__c, Picklist_Value_Description__c FROM ECLF_Picklist_Description__c WHERE Object__c = 'Property' AND Picklist_Name__c = 'Development Stage']; 
        
        if(picklistDescriptionList.size() > 0)
        {
            for(ECLF_Picklist_Description__c picklistDescription : picklistDescriptionList)
            {
                picklistDescriptionMap.put(picklistDescription.Picklist_Value__c, picklistDescription.Picklist_Value_Description__c);
            }
        }//v1.4 End
        
        for(ENT_ECLF_Property__c eclfProperty : Trigger.new)
        {
            ENT_ECLF_Project__c project = mapPropertyProject.get(eclfProperty.ECLF_Project__c);
    
            //v1.4 Start
            if(Trigger.isBefore && eclfProperty.Development_Stage__c != null)
            {
                if(!picklistDescriptionMap.isEmpty())
                {
                    eclfProperty.Development_Stage_Description__c = picklistDescriptionMap.get(eclfProperty.Development_Stage__c);
                }
                //if(Trigger.isUpdate)
                //{
                //    if(Trigger.oldMap.get(eclfProperty.Id).Development_Stage_Due_Date__c != eclfProperty.Development_Stage_Due_Date__c && eclfProperty.Development_Stage_Due_Date__c != null)
                //    {
                //        Task newPropertyTask = new Task(RecordTypeId = crmTaskRecordType.Id, ActivityDate = eclfProperty.Development_Stage_Due_Date__c, WhatId = eclfProperty.Id, Subject = 'Property Due Date Reminder: ' + eclfProperty.Name);
                //        newTaskList.add(newPropertyTask);
                //    }
                //}
                //if(Trigger.isInsert && eclfProperty.Development_Stage_Due_Date__c != null)
                //{
                //    Task newPropertyTask = new Task(RecordTypeId = crmTaskRecordType.Id, ActivityDate = eclfProperty.Development_Stage_Due_Date__c, WhatId = eclfProperty.Id, Subject = 'Property Due Date Reminder: ' + eclfProperty.Name);
                //    newTaskList.add(newPropertyTask);
                //}
            }
            else if(Trigger.isBefore && eclfProperty.Development_Stage__c == null)
            {
                eclfProperty.Development_Stage_Description__c = '';
            }//v1.4 End

            if(Trigger.isBefore && eclfProperty.Primary__c == true)
            {
                for(ENT_ECLF_Property__c propertyForPrimaryCheck : Project.ECLF_Properties__r)
                {
                    if(propertyForPrimaryCheck.Id != eclfProperty.Id && propertyForPrimaryCheck.Primary__c == true)
                    {
                        eclfProperty.addError('You already have primary property for ' + project.Name + ' project.');
                        break;
                    }
                }
            }

            if(Trigger.isAfter && eclfProperty.Primary__c == true)
            {
                if(String.isBlank(eclfProperty.Street_Address_Line_1__c) && !String.isBlank(eclfProperty.Street_Address_Line_2__c))
                {
                    project.Street__c = eclfProperty.Street_Address_Line_2__c;
                }
                else if(String.isBlank(eclfProperty.Street_Address_Line_2__c) && !String.isBlank(eclfProperty.Street_Address_Line_1__c))
                {
                    project.Street__c = eclfProperty.Street_Address_Line_1__c;
                }
                else if(!String.isBlank(eclfProperty.Street_Address_Line_2__c) && !String.isBlank(eclfProperty.Street_Address_Line_1__c))
                {
                    project.Street__c = eclfProperty.Street_Address_Line_1__c + ' ' + eclfProperty.Street_Address_Line_2__c;
                }
                else if(String.isBlank(eclfProperty.Street_Address_Line_2__c) && String.isBlank(eclfProperty.Street_Address_Line_1__c))
                {
                    project.Street__c = '';
                }
              
                project.City__c = eclfProperty.City__c;
                project.State__c = eclfProperty.State__c;
                project.Zip_Code__c = eclfProperty.Zip_Code__c;
                project.County__c = eclfProperty.County__c;
                project.CIIS_Project_X_Coordinates__c = eclfProperty.CIIS_Project_X_Coordinates__c; // v1.2
                project.CIIS_Project_Y_Coordinates__c = eclfProperty.CIIS_Project_Y_Coordinates__c; // v1.2
                lstProjects.add(project);
            }
        }
        //v1.3 Start
        try{
            if(!lstProjects.isEmpty())
            {
                UPDATE lstProjects;
            }
        }catch(DMLException e){
            Trigger.new[0].addError(e.getDmlMessage(0),FALSE);
        }
        //v1.3 Ends

        //Start v1.4
        //try
        //{
        //    if(!newTaskList.isEmpty())
        //    {
        //        insert newTaskList;
        //    }
        //}
        //catch(DMLException e)
        //{
        //    System.debug(e.getMessage());
        //}//End v1.4
    }
}