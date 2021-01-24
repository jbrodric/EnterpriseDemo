/***************************************************************
Class   : ENT_All_CensusCalloutMockUnknown
Author  : John Brodrick
Date    : 06/24/2019
Details : Returns a mock census response of unknown format for testing
History : v1.0 - 06/24/2019 - Created
*****************************************************************/
@isTest(SeeAllData=false)
public class ENT_All_CensusCalloutMockUnknown implements HttpCalloutMock
{
    public HTTPResponse respond(HTTPRequest req) 
    {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/json; charset=utf-8');
        res.setBody('{ "unknown": "6801" }');
        res.setStatusCode(200);
        return res;
    }
}