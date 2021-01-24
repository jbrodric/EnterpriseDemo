/************************************************************************
Class   : TEST_ENT_ALL_CensusGeocodingUtils
Author  : Jbrodrick
Date    : 06/25/2019
Details : This class provides test coverage for Census API Utilities
          Classes Covered:
              - ENT_Batch_All_CensusGeocoding (77% Coverage)
              - ENT_All_CensusGeocodingServiceCallout (90% Coverage)
History : v1.0 - 06/25/2019 - Created
*************************************************************************/
@isTest(SeeAllData = False)
public class TEST_ENT_ALL_CensusGeocodingUtils
{   
    @testSetup static void setup()
    {
        ENT_ECLF_Project__c newProject = new ENT_ECLF_Project__c(Name='Test Project 2');
        insert newProject;

        Test_ENT_ECLF_Utility.DisableECLFTriggers();
        List<ENT_ECLF_Property__c> lstProps = new List<ENT_ECLF_Property__c>();

        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            Street_Address_Line_1__c = 'Test', City__c = 'Test', State__c = 'MD', Zip_Code__c = '21075'));
        
        insert lstProps;
        Test_ENT_ECLF_Utility.EnableECLFTriggers();
    }

    public static testmethod void ENT_Batch_All_CensusGeocoding_TestBatch_Valid()
    {  
        ENT_ECLF_Project__c newProject = [SELECT id, name FROM ENT_ECLF_Project__c WHERE Name='Test Project 2' LIMIT 1]; 

        Test_ENT_ECLF_Utility.DisableECLFTriggers();
        List<ENT_ECLF_Property__c> lstProps = new List<ENT_ECLF_Property__c>();

        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property 2', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            Street_Address_Line_1__c = 'Test 2', City__c = 'Test 2', State__c = 'MD', Zip_Code__c = '21075', State_Code__c ='24', County_Code__c='027', Tract__c='601107'));
        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property 3', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            GeoLocation__c = '(39.2120567,-76.86588019999999)'));
        
        insert lstProps;
        Test_ENT_ECLF_Utility.EnableECLFTriggers();

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ENT_All_CensusCalloutMock());
        
        ENT_Batch_All_CensusGeocoding batch = new ENT_Batch_All_CensusGeocoding(1,false); 
        Database.executeBatch(batch);
    
        test.stopTest();
    }
    
    public static testmethod void ENT_Batch_All_CensusGeocoding_TestBatch_Invalid()
    {
        ENT_ECLF_Project__c newProject = [SELECT id, name FROM ENT_ECLF_Project__c WHERE Name='Test Project 2' LIMIT 1]; 
             
        Test_ENT_ECLF_Utility.DisableECLFTriggers();
        List<ENT_ECLF_Property__c> lstProps = new List<ENT_ECLF_Property__c>();

        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property 2', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            Street_Address_Line_1__c = 'Test 2', City__c = 'Test 2', State__c = 'MD', Zip_Code__c = '21075', State_Code__c ='24', County_Code__c='027', Tract__c='601107'));
        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property 3', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            GeoLocation__c = '(39.2120567,-76.86588019999999)'));
        
        insert lstProps;
        Test_ENT_ECLF_Utility.EnableECLFTriggers();

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ENT_All_CensusCalloutMockInvalid());
        
        ENT_Batch_All_CensusGeocoding batch = new ENT_Batch_All_CensusGeocoding(1,false); 
        Database.executeBatch(batch);
    
        test.stopTest();
    }
    
    public static testmethod void ENT_Batch_All_CensusGeocoding_TestBatch_Unknown()
    {
        ENT_ECLF_Project__c newProject = [SELECT id, name FROM ENT_ECLF_Project__c WHERE Name='Test Project 2' LIMIT 1]; 
             
        Test_ENT_ECLF_Utility.DisableECLFTriggers();
        List<ENT_ECLF_Property__c> lstProps = new List<ENT_ECLF_Property__c>();

        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property 2', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            Street_Address_Line_1__c = 'Test 2', City__c = 'Test 2', State__c = 'MD', Zip_Code__c = '21075', State_Code__c ='24', County_Code__c='027', Tract__c='601107'));
        lstProps.add(new ENT_ECLF_Property__c(Name='Test Property 3', ECLF_Project__c = newProject.Id, Development_Stage__c = 'Predevelopment',
            GeoLocation__c = '(39.2120567,-76.86588019999999)'));
        
        insert lstProps;
        Test_ENT_ECLF_Utility.EnableECLFTriggers();

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ENT_All_CensusCalloutMockUnknown());
        
        ENT_Batch_All_CensusGeocoding batch = new ENT_Batch_All_CensusGeocoding(1,false); 
        Database.executeBatch(batch);
    
        test.stopTest();
    }
    
    public static testmethod void ENT_Batch_All_CensusGeocoding_TestScheduleBatch()
    {
        test.startTest();
                
        ENT_Batch_All_CensusGeocoding scheduledProcess = new ENT_Batch_All_CensusGeocoding(1,false); 
        String scheduledTime = '0 0 8 13 2 ?';
        String jobId = system.schedule('One Time Pro', scheduledTime, scheduledProcess);        
        
        test.stopTest();
    }
}