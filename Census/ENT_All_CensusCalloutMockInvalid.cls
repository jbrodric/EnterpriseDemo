/***************************************************************
Class   : ENT_All_CensusCalloutMockInvalid
Author  : John Brodrick
Date    : 06/24/2019
Details : Returns a mock census response with an invalid address message for testing
History : v1.0 - 06/24/2019 - Created
*****************************************************************/
@isTest(SeeAllData=false)
public class ENT_All_CensusCalloutMockInvalid implements HttpCalloutMock
{
    public HTTPResponse respond(HTTPRequest req) 
    {
        if(req.getEndpoint().contains('https://geocoding.geo.census.gov/geocoder/geographies/address')) 
		{
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/json; charset=utf-8');
            res.setBody('{"result":{"input":{"benchmark":{"id":"4","benchmarkName":"Public_AR_Current","benchmarkDescription":"Public Address Ranges - Current Benchmark","isDefault":false},"vintage":{"id":"4","vintageName":"Current_Current","vintageDescription":"Current Vintage - Current Benchmark","isDefault":true},"address":{"street":"kjl","city":"","state":"","zip":"jkl"}},"addressMatches":[]}}');
            res.setStatusCode(200);
            return res;
        } 
		else if(req.getEndpoint().contains('https://geocoding.geo.census.gov/geocoder/geographies/coordinates'))
		{
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'text/json; charset=utf-8');
			res.setBody('{"result":{"input":{"benchmark":{"id":"4","benchmarkName":"Public_AR_Current","benchmarkDescription":"Public Address Ranges - Current Benchmark","isDefault":false},"vintage":{"id":"4","vintageName":"Current_Current","vintageDescription":"Current Vintage - Current Benchmark","isDefault":true},"location":{"x":-1.0,"y":1.0}},"geographies":{"2010 Census Blocks":[]}}}');
			res.setStatusCode(200);
			return res;
		}        
		else 
		{
			System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
			return null;
		}
    }
}