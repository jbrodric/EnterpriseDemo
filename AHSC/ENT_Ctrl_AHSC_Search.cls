/***************************************************************
Class   : ENT_Ctrl_AHSC_Search
Author  : Fred Rossmark
Date    : 08/11/2015
Details : This class provides controller functionality for the
          ENT_Ctrl_Community_AHSC VF Page and its Components  - TBD, need to change
          that are exposed to LIHTC Investor Community Users.
History : v1.0 - 08/11/2015 - Created (0% Code Coverage)
*****************************************************************/
global with sharing class ENT_Ctrl_AHSC_Search
{

    public List<SelectOption> getProjectTypes { get; set; }
    public List<SelectOption> getCapitalUses { get; set; }
    public List<SelectOption> getEntitled { get; set; }
    public List<SelectOption> getApplicationStatus { get; set; }
    public List<SelectOption> getProgramGrantRequest { get; set; }
    public List<SelectOption> getMatched { get; set; }
    public List<SelectOption> getUSState { get; set; }
    
    public String USState { get; set; }  
    public String[] ProjectType { get; set; }         
    public String[] CapitalUses { get; set; }  
    public String[] Entitled { get; set; }
    public String[] ApplicationStatus { get; set; }
    public String[] ProgramGrantRequest { get; set; }
    public String[] Matched { get; set; }
    public Double FundingNeededFrom { get; set; }
    public Double FundingNeededTo { get; set; }
    
    public String SearchQuery { get; set; }
        
    // Main function to intialize search data sets.
    public PageReference SearchInitialize() {       
       
        // set state to that of the current user
        USState = GetCurrentUserState();
        
        //Set Picklists
        getProjectTypes = getProjectTypes();
        getCapitalUses = getCapitalUses();
        getEntitled = getEntitled();
        getApplicationStatus = getApplicationStatus();
        getProgramGrantRequest = getProgramGrantRequest();

        getMatched = getMatched();
        getUSState = getUSState();
        
        //Default Application Status to Active
        String[] app_status_default = new List<String>();
        app_status_default.add('Active');
        ApplicationStatus = app_status_default;
        
        //load the search
       // BuildSearchQuery();
        
        return null;        
    }
    
    public String GetCurrentUserState() {
    
        // Get Current User
        Id CurrentUserID = UserInfo.getUserId();
        
        User cur_user = [SELECT Id, State FROM User WHERE Id = :CurrentUserID  ];
        
        return cur_user.State;
        
    }
    
    // function to clear search fields
    public PageReference ClearSearch() {       
        
        ProjectType = null;     
        CapitalUses = null;
        Entitled = null;
        ProgramGrantRequest = null;

        Matched = null;
        FundingNeededFrom = null;
        FundingNeededTo = null;
        
        //Default Application Status to Active
        String[] app_status_default = new List<String>();
        app_status_default.add('Active');
        ApplicationStatus = app_status_default;
        
        // set state to that of the current user
        USState = GetCurrentUserState();
        
        return null;        
    }
        

    // Data Source for USState Picklists, based on values in underlying AHSC_Project_Location object.
    public List<SelectOption> getUSState() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = ENT_AHSC_Project_Location__c.State__c.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
              
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }
    
    // Data Source for Project Type Picklists, based on values in underlying AHSC_Project object.
    public List<SelectOption> getProjectTypes() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = ENT_AHSC_Project__c.Project_Type__c.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
              
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }

    // Data Source for Capital Uses Picklists, based on values in underlying AHSC_Project object.
    public List<SelectOption> getCapitalUses() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = ENT_AHSC_Project__c.Capital_Uses__c.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }
    
    // Data Source for Entitled Picklists, based on values in underlying AHSC_Project object.
    public List<SelectOption> getEntitled() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = ENT_AHSC_Project__c.Entitled__c.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }

    // Data Source for Application Status Picklists, based on values in underlying AHSC_Project object.
    public List<SelectOption> getApplicationStatus() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = ENT_AHSC_Project__c.Application_Status__c.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }
    
    // Data Source for Program Grant Request  Picklists, based on values in underlying AHSC_Project object.
    public List<SelectOption> getProgramGrantRequest() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = ENT_AHSC_Project__c.Project_includes_Program_Grant_request__c.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }
    
    

    // Data Source for Matched Picklists, underlying AHSC_Project object value is a check box, return "Checked" and "Unchecked".
    public List<SelectOption> getMatched() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('Checked', 'Checked'));
        options.add(new SelectOption('Unchecked', 'Unchecked'));
        
        return options;
    }    
            
    private void BuildSearchQuery() {
    
        // Build Query
        String strSQL = 'SELECT Id, Name FROM ENT_AHSC_Project__c ';
        String strWHERE = '';
        String strList = '';
        
        // US State (START)           
        if (!String.IsBlank(USState)) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            strWHERE = strWHERE + 'USState__c = '+ '\'' + USState + '\'';
            
        }
        // US State (END)   
        
        // Project Type (START)        
        if (ProjectType.size() > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strList = '';
            
            strWHERE = strWHERE + 'Project_Type__c IN (';
            for (String pt : ProjectType) {
                
                // if list is empty add the first list item
                if (String.IsBlank(strList)) {
                    strList = strList + '\'' + pt + '\'';

                }
                // else if not empty, add a comma first and then the list item
                else {
                    strList = strList + ', \'' + pt + '\'';
                }
                
            }
            
            strWHERE = strWHERE + strList + ') ';
        }
        // Project Type (END)
         
        // Capital Uses (START)
        if (CapitalUses.size() > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strList = '';
            
            strWHERE = strWHERE + 'Capital_Uses__c IN (';
            for (String cu : CapitalUses) {
                
                // if list is empty add the first list item
                if (String.IsBlank(strList)) {
                    strList = strList + '\'' + cu + '\'';
                }
                // else if not empty, add a comma first and then the list item
                else {
                    strList = strList + ', \'' + cu + '\'';
                }
                
            }
            
            strWHERE = strWHERE + strList + ') ';
        }
        // Capital Uses (END)
                 
        // Entitled  (START)
        if (Entitled.size() > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strList = '';
            
            strWHERE = strWHERE + 'Entitled__c IN (';
            for (String e : Entitled) {
                
                // if list is empty add the first list item
                if (String.IsBlank(strList)) {
                    strList = strList + '\'' + e + '\'';
                }
                // else if not empty, add a comma first and then the list item
                else {
                    strList = strList + ', \'' + e + '\'';
                }
                
            }
            
            strWHERE = strWHERE + strList + ') ';
        }
        // Entitled (END)
        
        // Application Status (START)
        if (ApplicationStatus.size() > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strList = '';
            
            strWHERE = strWHERE + 'Application_Status__c IN (';
            for (String aps : ApplicationStatus) {
                
                // if list is empty add the first list item
                if (String.IsBlank(strList)) {
                    strList = strList + '\'' + aps + '\'';
                }
                // else if not empty, add a comma first and then the list item
                else {
                    strList = strList + ', \'' + aps + '\'';
                }
                
            }
            
            strWHERE = strWHERE + strList + ') ';
        }
        // Application Status (END)
                 
        // Matched (START)
        if (Matched.size() == 1) {
            // any size other than 1 equates to select everything, thus no need to filter
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strList = '';
            strWHERE = strWHERE + 'Matched__c = ';
            
            if (Matched[0] == 'Checked') {
                strList = 'true';
            }
            else {
                strList = 'false';
            }
            
            strWHERE = strWHERE + strList;
        }
        // Matched (END)
                         
        // Project includes Program Grant Request (START)
        if (ProgramGrantRequest.size() > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strList = '';
            
            strWHERE = strWHERE + 'Project_includes_Program_Grant_request__c IN (';
            for (String pgr : ProgramGrantRequest ) {
                
                // if list is empty add the first list item
                if (String.IsBlank(strList)) {
                    strList = strList + '\'' + pgr + '\'';
                }
                // else if not empty, add a comma first and then the list item
                else {
                    strList = strList + ', \'' + pgr + '\'';
                }
                
            }
            
            strWHERE = strWHERE + strList + ') ';
        }
        // Project includes Program Grant Request (END)
        
        
        
        // Project includes FundingNeededFrom  (START)
        if (FundingNeededFrom > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strWHERE = strWHERE + 'Approximate_Amount_of_Funding_Needed__c >= ' + FundingNeededFrom  ;
        }
        // Project includes FundingNeededFrom   (END)
        
        // Project includes FundingNeededTo  (START)
        if (FundingNeededTo  > 0) {
            if (String.IsBlank(strWHERE)) {
                strWHERE = strWHERE + 'WHERE ';
            }
            else {
                strWHERE = strWHERE + 'AND ';
            }
            
            strWHERE = strWHERE + 'Approximate_Amount_of_Funding_Needed__c <= ' + FundingNeededTo    ;
        }
        // Project includes FundingNeededTo (END)
                
        // set property
        SearchQuery = strSQL + strWHERE;
    }
                
    public PageReference Search() {

        // call BuildSearchQuery
        BuildSearchQuery(); 
        
        return null;
    }
    
    public String FindLatituteLongitude(String ZipCode) {

        string apiKey = '#$enterprise123'; 
        
        String url = 'https://maps.googleapis.com/maps/api/geocode/xml?'; 
        url += 'components=postal_code:' + ZipCode; 
        //url += '&key=' + apiKey; 
        
        Http h = new Http(); 
        HttpRequest req = new HttpRequest(); 
        req.setHeader('Content-type', 'application/x-www-form-urlencoded'); 
        req.setEndpoint(url); 
        req.setMethod('POST'); 
        
        String responseBody = ''; 
        HttpResponse res = h.send(req); 
        responseBody = res.getBody(); /*Response body will include Lan and Long*/ 
        
        return responseBody;
        //Then you can either use some parsing library or traverse it yourself
        
    }    
    
    @RemoteAction
    public static List<ENT_AHSC_Project_Location__c> GetAllLocations()
    {       	
        return ENT_AHSC_Util.GetAllLocations();
    }
    @RemoteAction
    public static string UpdateProjectGeolocation(string ProjectLocationIdString, Double lat, Double lng)
    {       	
        return ENT_AHSC_Util.UpdateProjectGeolocation(ProjectLocationIdString, lat, lng);
    }
	
}