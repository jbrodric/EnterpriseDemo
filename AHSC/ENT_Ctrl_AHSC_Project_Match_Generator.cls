/***************************************************************
Class   : ENT_Ctrl_AHSC_Project_Match_Generator
Author  : John Brodrick
Date    : 05/06/2016
Details : This class provides controller functionality for the
          ENT_AHSC_Project_Match_Generator VF Page and its Components.
History : v1.0 - 05/03/2016 - Created (0% Code Coverage)
          v1.1 - 08/29/2016 - Updated the 'ENT_AHSC_Util.GetMyProjects' method call to reference the new name (John Sung, 84% code coverage)
*****************************************************************/
public with sharing class ENT_Ctrl_AHSC_Project_Match_Generator 
{
	/* Properties */
	public Integer numMyProjects
	{
		get
		{
			if(lstMyProjects == null)
				return 0;
			else
				return lstMyProjects.size();
		}			
	}
	
    public Integer numPossibleMatches
	{
		get
		{
			if(lstPossibleMatches == null)
				return 0;
			else
				return lstPossibleMatches.size();
		}			
	}
    
    public Decimal sumRequestAmount {get; set;}
    
	public Boolean bCreateMatch {get; set;}
	public String matchName {get; set;}	
	public String matchStatus {get; set;}
    
	public ENT_AHSC_Project__c selectedProject {get; set;}	
	public List<AHSCProjectWrapper> lstMyProjects {get; set;}
    
	public List<AHSCProjectWrapper> lstPossibleMatches {get; set;}
	public List<ENT_AHSC_Project__c> lstSelectedMatches {get; set;}
	
	/* Contructor */
	public ENT_Ctrl_AHSC_Project_Match_Generator ()
	{
		List<ENT_AHSC_Project__c> lstProjects = ENT_AHSC_Util.GetAllValidProjects(); // v1.1
		lstMyProjects = new List<AHSCProjectWrapper>();
		
		for(ENT_AHSC_Project__c p : lstProjects)
			lstMyProjects.add(new AHSCProjectWrapper(p, false));
		
		Initialize();
	}
	
	/* Event Handling Methods */
	public PageReference SelectProject()
	{
		for(AHSCProjectWrapper p : lstMyProjects)
			if(p.selected == true)
				selectedProject = p.project;
		
		if(selectedProject == null)
			ApexPages.addMessages(new AHSCProjectMatchException('Please select a project to continue.'));
		else
		{
			List<ENT_AHSC_Project__c> lstTempPossibleMatches = ENT_AHSC_Util.GetPossibleMatches(selectedProject);
			
			for(ENT_AHSC_Project__c p : lstTempPossibleMatches)
				lstPossibleMatches.add(new AHSCProjectWrapper(p, false));
		}
			
		return null;
	}
	
	public PageReference Save()
	{				
		PageReference retPR = null;
		
		if(matchName != null && matchName != '')
		{       
			Savepoint sp;
			     
            try
            {
                AHSC_Match__c match = new AHSC_Match__c(name = matchName, status__c = matchStatus);
                List<AHSC_Match_Projects__c> lstAHSCMatchProjects = new List<AHSC_Match_Projects__c>();
                
                sp = Database.setSavepoint();
                
                insert match;
                                
                Id matchId = match.Id;
                
                for(ENT_AHSC_Project__c p : lstSelectedMatches)
                    lstAHSCMatchProjects.add(new AHSC_Match_Projects__c(AHSC_Match__c = matchId, Project__c = p.Id));
                    
                lstAHSCMatchProjects.add(new AHSC_Match_Projects__c(AHSC_Match__c = matchId, Project__c = selectedProject.Id));
                
                insert lstAHSCMatchProjects;
               
                retPR = new PageReference('/' + matchId);
            }    
            catch(Exception e)
            {
            	Database.rollback(sp);
            	ApexPages.addMessages(e);
            }    
		}
		else
			ApexPages.addMessages(new AHSCProjectMatchException('Please enter a match name to continue.'));			
			
		return retPR;
	}
	
	public PageReference Back()
	{
		bCreateMatch = false;
		
		return null;
	}
	
	public PageReference Cancel()
	{
		Initialize();	
		return null;		
	}
	
	public PageReference CreateMatch()
	{		
		lstSelectedMatches = new List<ENT_AHSC_Project__c>();
		
		for(AHSCProjectWrapper wrappedProject : lstPossibleMatches)
        {
			if(wrappedProject.selected == true)
            {
				lstSelectedMatches.add(wrappedProject.project);
                sumRequestAmount += wrappedProject.project.Approx_AHSC_Request_Amount__c;
            }
        }
        
        sumRequestAmount += selectedProject.Approx_AHSC_Request_Amount__c;

		if(lstSelectedMatches.size() == 0)
			ApexPages.addMessages(new AHSCProjectMatchException('Please select at least one match.'));
        else
            bCreateMatch = true;
		
		return null;		
	}
    
    /* Remote Actions */
    @RemoteAction
    public static List<ENT_AHSC_Project_Location__c> GetPossibleMatchingLocations(Id selectedProjectId)
    {
        return ENT_AHSC_Util.GetPossibleMatchingLocations(selectedProjectId);
    }
    @RemoteAction
    public static string UpdateProjectGeolocation(string ProjectLocationIdString, Double lat, Double lng)
    {       	
        return ENT_AHSC_Util.UpdateProjectGeolocation(ProjectLocationIdString, lat, lng);
    }
	
	/* Helper Methods */	
	private void Initialize()
	{		
		selectedProject = null;
		
		for(AHSCProjectWrapper p : lstMyProjects)
			p.selected = false;
			
		lstPossibleMatches = new List<AHSCProjectWrapper>();
		lstSelectedMatches = new List<ENT_AHSC_Project__c>();
		bCreateMatch = false;
		matchName = '';		
        sumRequestAmount = 0;
	}
	
	/* Helper Classes */
	public class AHSCProjectWrapper
	{
		
		public ENT_AHSC_Project__c project {get; set;}
		public Boolean selected {get; set;}
		
		public AHSCProjectWrapper(ENT_AHSC_Project__c p, Boolean bIsSelected)
        {
            project = p;
            selected = bIsSelected;
        }
        
	}
	
	/* Custom Exceptions */
	public class AHSCProjectMatchException extends Exception {}
}