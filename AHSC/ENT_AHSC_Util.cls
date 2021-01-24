global with sharing class ENT_AHSC_Util 
{
    global ENT_AHSC_Util() { }

    global static List<ENT_AHSC_Project__c> GetPossibleMatches(ENT_AHSC_Project__c selectedProject)
    {
        String strEscSelProjectProjType = (selectedProject.project_type__c == null ? 
            null : '\'' + String.escapeSingleQuotes(selectedProject.project_type__c) + '\'');
        String strEscSelProjectAppYear = (selectedProject.application_year__c == null ? 
            null : '\'' + String.escapeSingleQuotes(selectedProject.application_year__c) + '\'');
        String strEscSelProjectId = (selectedProject.Id == null ? 
            null : '\'' + String.escapeSingleQuotes(selectedProject.Id) + '\'');
            
        String sSOQL = 
            'SELECT ' + 
                'id, name, developer__c, Application_Year__c, ' + 
                'Project_City__c, USState__c, Project_Type__c, ' + 
                'Capital_Uses__c, Complementary_Capital_Uses__c, ' + 
                'Approx_AHSC_Request_Amount__c, ' + 
                'Project_includes_Program_Grant_request__c, Project_County__c ' + 
            'FROM ENT_AHSC_Project__c ' + 
            'WHERE ' +
                'project_type__c = ' + strEscSelProjectProjType + ' ' +
                'AND Application_Status__c <> \'Inactive\' ' + 
                'AND USState__c = \'CA\' ' + 
                'AND Id <> ' + strEscSelProjectId + ' ';
        
        // if sel proj's app year has value then filter results by app year as well
        if(selectedProject.application_year__c != null &&
            selectedProject.application_year__c.toLowerCase() != 'unsure')
        {
            sSOQL +=  
                ' AND (' + 
                    'application_year__c = ' + strEscSelProjectAppYear + ' ' +  
                    'OR application_year__c = \'unsure\' ' +
                    'OR application_year__c = null ' + 
                ') ';
        }
        
        String strSelProjCapUses = selectedProject.Capital_Uses__c;
        
        if(strSelProjCapUses != null)
        {
            if(strSelProjCapUses.contains('Housing-Related Infrastructure') || strSelProjCapUses.contains('Affordable Housing Developments'))
            {
                sSOQL +=  
                    ' AND Capital_Uses__c excludes (\'Housing-Related Infrastructure\') ';
                sSOQL +=  
                    ' AND Capital_Uses__c excludes (\'Affordable Housing Developments\') ';
            }
        }
        
        sSOQL += ' ORDER BY Project_City__c, name ';
                
        return Database.query(sSOQL);
    }

    global static List<ENT_AHSC_Project_Location__c> GetPossibleMatchingLocations(Id selectedProjectId)
    {
        ENT_AHSC_Project__c selectedProject = [
            SELECT id, project_type__c, application_year__c, Capital_Uses__c
            FROM ENT_AHSC_Project__c 
            where id = :selectedProjectId];
        
        String strEscSelProjectProjType = (selectedProject.project_type__c == null ? 
            null : '\'' + String.escapeSingleQuotes(selectedProject.project_type__c) + '\'');
        String strEscSelProjectAppYear = (selectedProject.application_year__c == null ? 
            null : '\'' + String.escapeSingleQuotes(selectedProject.application_year__c) + '\'');
        String strEscSelProjectId = (selectedProject.Id == null ? 
            null : '\'' + String.escapeSingleQuotes(selectedProject.Id) + '\'');
        
        String sSOQL = 
            'SELECT ' + 
                'AHSC_Project__r.id, AHSC_Project__r.name, AHSC_Project__r.developer__c, AHSC_Project__r.Application_Year__c, ' + 
                'AHSC_Project__r.Project_City__c, AHSC_Project__r.USState__c, AHSC_Project__r.Project_Type__c, ' + 
                'AHSC_Project__r.Capital_Uses__c, AHSC_Project__r.Complementary_Capital_Uses__c, ' +
                'AHSC_Project__c, Address__c, City__c, Name, Description__c, Existing_Infrastructure__c, GeoCode__c, LocationType__c, State__c, Zip_Code__c, ' + 
                '(SELECT Coordinates__c, Geolocation_Order__c FROM AHSC_Project_Geolocations__r ORDER BY geolocation_order__c) ' + 
            'FROM ENT_AHSC_Project_Location__c ' + 
            'WHERE ' +
                'AHSC_Project__r.project_type__c = ' + strEscSelProjectProjType + ' ' +
                'AND AHSC_Project__r.Application_Status__c <> \'Inactive\' ' + 
                'AND AHSC_Project__r.USState__c = \'CA\' ';
        
        // if sel proj's app year has value then filter results by app year as well
        if(selectedProject.application_year__c != null &&
            selectedProject.application_year__c.toLowerCase() != 'unsure')
        {
            sSOQL +=  
                ' AND (' + 
                    'AHSC_Project__r.application_year__c = ' + strEscSelProjectAppYear + ' ' +  
                    'OR AHSC_Project__r.application_year__c = \'unsure\' ' +
                    'OR AHSC_Project__r.application_year__c = null ' + 
                ') ';
        }
        
        String strSelProjCapUses = selectedProject.Capital_Uses__c;
                
        if(strSelProjCapUses != null)
        {
            if(strSelProjCapUses.contains('Housing-Related Infrastructure') || strSelProjCapUses.contains('Affordable Housing Developments'))
            {
                sSOQL +=  
                    ' AND (AHSC_Project__r.Id = ' + strEscSelProjectId + ' OR AHSC_Project__r.Capital_Uses__c excludes (\'Housing-Related Infrastructure\')) ';
                sSOQL +=  
                    ' AND (AHSC_Project__r.Id = ' + strEscSelProjectId + ' OR AHSC_Project__r.Capital_Uses__c excludes (\'Affordable Housing Developments\')) ';
            }
        }
        
        return Database.query(sSOQL);
    }

    global static List<ENT_AHSC_Project_Location__c> GetAllLocations()
    {
        return [
            SELECT 
                AHSC_Project__r.id, AHSC_Project__r.name, AHSC_Project__r.developer__c, AHSC_Project__r.Application_Year__c,  
                AHSC_Project__r.Project_City__c, AHSC_Project__r.USState__c, AHSC_Project__r.Project_Type__c, 
                AHSC_Project__r.Capital_Uses__c, AHSC_Project__r.Complementary_Capital_Uses__c,
                AHSC_Project__c, Address__c, City__c, Name, Description__c, GeoCode__c, LocationType__c, State__c, Zip_Code__c, 
                (SELECT Coordinates__c, Geolocation_Order__c FROM AHSC_Project_Geolocations__r ORDER BY geolocation_order__c) 
            FROM ENT_AHSC_Project_Location__c 
            WHERE AHSC_Project__r.Application_Status__c <> 'Inactive'];
    }

    global static List<AHSCProjectLocationWithMatches> GetAllMatchingLocations(Id projectId)
    {
        List<ENT_AHSC_Project_Location__c> lstPossibleMatchingLocations = GetPossibleMatchingLocations(projectId);
        List<AHSC_Match__c> lstMatches = [
            SELECT id, name, status__c,
                (SELECT Project__c FROM AHSC_Match_Projects__r)
            FROM AHSC_Match__c
            WHERE 
                id in (
                    SELECT AHSC_Match__c
                    FROM AHSC_Match_Projects__c
                    WHERE Project__c = :projectId)
                AND Overall_Match_Valid_Bool__c = true
            ORDER BY status__c DESC
        ];
        Map<Id, Set<AHSC_Match__c>> mapProjIdToAHSCMatches = new Map<Id, Set<AHSC_Match__c>>();
        List<AHSCProjectLocationWithMatches> retVal = new List<AHSCProjectLocationWithMatches>();
        
        for(AHSC_Match__c match : lstMatches)
        {
            for(AHSC_Match_Projects__c mp : match.AHSC_Match_Projects__r)
            {
                if(!mapProjIdToAHSCMatches.containsKey(mp.Project__c))
                    mapProjIdToAHSCMatches.put(mp.Project__c, new Set<AHSC_Match__c>());
                
                mapProjIdToAHSCMatches.get(mp.Project__c).add(match);
            }                
        }
        
        for(ENT_AHSC_Project_Location__c loc : lstPossibleMatchingLocations)
            retVal.add(new AHSCProjectLocationWithMatches(loc, mapProjIdToAHSCMatches.get(loc.AHSC_Project__c)));
        
        return retVal;
    }

    global static List<ENT_AHSC_Project__c> GetAllValidProjects()
    {
        return [
                SELECT 
                    id, name, developer__c, Application_Year__c, 
                    Project_City__c, USState__c, Project_Type__c,
                    Capital_Uses__c, Complementary_Capital_Uses__c,
                    Approx_AHSC_Request_Amount__c, 
                    Project_includes_Program_Grant_request__c,
                    Project_County__c
                FROM ENT_AHSC_Project__c
                WHERE 
                    Application_Status__c <> 'Inactive'
                    AND USState__c = 'CA'
                ORDER BY Project_City__c, name ];
    }
	
    global static list<ENT_AHSC_Project__c> GetMyProjects(Id uID, Id cID)
    {
        boolean isInternal = null;
        list<string> lstRegions = new list<string>();
        string query =
            'SELECT Id, Name, Project_Type__c, Project_Description__c, Capital_Uses__c, USState__c, Developer__c, Entitled__c, ' +
            'Approximate_Amount_of_Funding_Needed__c, Approx_Amount_of_Committed_Financing__c, Application_Status__c, ' +
            'Anticipated_Date_of_Entitlement__c, MatchedText__c, Participating_Entities__c, Approx_AHSC_Request_Amount__c, ' +
            'Project_includes_Program_Grant_request__c, Project_City__c, Application_Year__c ' +
            'FROM ENT_AHSC_Project__c';
        
        isInternal = ENT_AHSC_Util.GetAHSCPermMembership(uID).contains('AHSC_Enterprise_User');
		lstRegions = ENT_AHSC_Util.GetPartnerRegions(uID);
        
        if(!isInternal)
        {
            query += ' WHERE Application_Contact__c =: cID';
            if(lstRegions != null)
            {
                query += ' OR Project_Region__c IN : lstRegions';
            }
        }
		
        return database.query(query);
    }
    
    global static string UpdateProjectGeolocation(string ProjectLocationIdString, Double lat, Double lng)
    {       
        string retval = '';
        
        if(ProjectLocationIdString != null && ProjectLocationIdString != '')
        {
            try
            {
                Id ProjectLocationId = (Id)ProjectLocationIdString;
            
                ENT_AHSC_Project_Location__c pLocation = new ENT_AHSC_Project_Location__c(
                    id = ProjectLocationId, GeoCode__latitude__s = lat, GeoCode__longitude__s = lng);
                    
                update pLocation;
            }
            catch (exception ex)
            {
                return ex.getMessage();
            }
        }
        else
            retval = 'Project Location ID is NULL';
        
        return retval;
    }
    
    global static Set<String> GetAHSCPermMembership(Id userId)
    {
        Set<String> setRet = new Set<String>();
        List<PermissionSetAssignment> lstPerm = [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment 
            WHERE 
                AssigneeId= :userId 
                AND (PermissionSet.Name = 'AHSC_Enterprise_User'
                    OR PermissionSet.Name = 'AHSC_Community_User'
                    )];
        
        for(PermissionSetAssignment psa : lstPerm)
            setRet.add(psa.PermissionSet.Name);
        
        return setRet;        
    }
    
    global static set<string> GetAHSCPublicGroupMembership(Id userId)
    {
        set<string> setRet = new set<string>();
        list<GroupMember> lstPG =
        [
            SELECT Group.Name
            FROM GroupMember
            WHERE UserOrGroupId = :userId AND Group.Name like '%AHSC%'
        ];
        
        for(GroupMember GM : lstPG)
            setRet.add(GM.Group.Name);
        
        return setRet;
    }
    
    // set of project Ids that an external user's projects are matched to
    global static Set<Id> GetMatchedProjectIdsForExtUser(Id UserContactId)
    {
        Set<Id> setProjIds = new Set<Id>();
        Set<Id> setMatchIds = new Set<Id>();
        List<AHSC_Match_Projects__c> lstMatches = [
            SELECT AHSC_Match__c
            FROM AHSC_Match_Projects__c
            WHERE Project__r.Application_Contact__c = :UserContactId
        ];
        
        for(AHSC_Match_Projects__c amp : lstMatches)
            setMatchIds.add(amp.AHSC_Match__c);
        
        List<AHSC_Match_Projects__c> lstMatchProj = [
            SELECT Project__c
            FROM AHSC_Match_Projects__c
            WHERE
                Project__r.Application_Contact__c <> :UserContactId
                AND AHSC_Match__c in :setMatchIds
                AND AHSC_Match__r.status__c <> 'Rejected'
                AND AHSC_Match__r.Overall_Match_Valid_Bool__c = true
        ];
        
        for(AHSC_Match_Projects__c amp : lstMatchProj)
            setProjIds.add(amp.Project__c);
        
        return setProjIds;
    }
    
    global static list<string> GetPartnerRegions(Id uID)
    {
        set<string> setPG = new set<string>();
        list<string> lstRegions = new list<string>();
		
        setPG = ENT_AHSC_Util.GetAHSCPublicGroupMembership(uID);
        if(setPG != null)
        {
            for(string r : setPG)
            {
                if(r == 'AHSC - Central California Region (Ext)')
                {
                    lstRegions.add('Central California');
                }
                else if(r == 'AHSC - Northern California Region (Ext)')
                {
                    lstRegions.add('Northern California');
                }
                else if(r == 'AHSC - Southern California Region (Ext)')
                {
                    lstRegions.add('Southern California');
                }
            }
        }
		
        return lstRegions;
    }
    
    global static string ProjectDataValidation(ENT_AHSC_Project__c p)
    {
        string errorCodes = '';
        
        if(p.Application_Year__c == '' || p.Application_Year__c == null)
        {
            errorCodes = '[AY1]';
            
            apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'Application Year: You must enter a value'));
        }
        
        if(p.Application_Year__c != '' && p.Application_Year__c != null && p.Application_Year__c != 'Unsure' && (p.Application_Year__c.isNumeric() || !p.Application_Year__c.left(4).isNumeric() || p.Application_Year__c.mid(4, 1) != '/' || !p.Application_Year__c.mid(5, 2).isNumeric()))
        {
            errorCodes += '[AY2]';
            
            apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'Application Year: Must be in "YYYY/YY" format or equal to \'Unsure\' (case sensitive). Please choose from the available options.'));
        }
        
        if(p.Urban_Greening__c != null && p.Urban_Greening__c != '' && !string.valueOf(p.Urban_Greening__c).contains(';'))
        {
            errorCodes += '[UG1]';
            
            apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'Urban Greening: Applicants MUST select at least two options.'));
            p.Urban_Greening__c.addError('Applicants MUST select at least two options.');
        }
        
        return errorCodes;
    }
    
    /* Helper Classes */
    global class AHSCProjectLocationWithMatches
    {
        global ENT_AHSC_Project_Location__c projectLocation {get; set;}
        global Set<AHSC_Match__c> setMatches {get; set;}
        
        global AHSCProjectLocationWithMatches(ENT_AHSC_Project_Location__c pl, Set<AHSC_Match__c> matches)
        {
            projectLocation = pl;
            setMatches = matches;
        }
    }
}