/***************************************************************
Class   : ENT_All_CensusCalloutMock
Author  : John Brodrick
Date    : 06/24/2019
Details : Returns a mock census response for testing
History : v1.0 - 06/24/2019 - Created
*****************************************************************/
@isTest(SeeAllData=false)
public class ENT_All_CensusCalloutMock implements HttpCalloutMock
{
    public HTTPResponse respond(HTTPRequest req) 
    {
        if(req.getEndpoint().contains('https://geocoding.geo.census.gov/geocoder/geographies/address')) 
		{
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/json; charset=utf-8');
            res.setBody('{"result":{"input":{"benchmark":{"id":"4","benchmarkName":"Public_AR_Current","benchmarkDescription":"Public Address Ranges - Current Benchmark","isDefault":false},"vintage":{"id":"4","vintageName":"Current_Current","vintageDescription":"Current Vintage - Current Benchmark","isDefault":true},"address":{"street":"6821 Sanctuary Ct","city":"Elkridge","state":"MD","zip":"21075"}},"addressMatches":[{"matchedAddress":"6821 SANCTUARY CT, ELKRIDGE, MD, 21075","coordinates":{"x":-76.78814,"y":39.186043},"tigerLine":{"tigerLineId":"158941008","side":"L"},"addressComponents":{"fromAddress":"6801","toAddress":"6899","preQualifier":"","preDirection":"","preType":"","streetName":"SANCTUARY","suffixType":"CT","suffixDirection":"","suffixQualifier":"","city":"ELKRIDGE","state":"MD","zip":"21075"},"geographies":{"2010 Census Blocks":[{"SUFFIX":"","GEOID":"240276011072000","CENTLAT":"+39.1850075","BLOCK":"2000","AREAWATER":0,"STATE":"24","BASENAME":"2000","OID":210404017092858,"LSADC":"BK","FUNCSTAT":"S","INTPTLAT":"+39.1850075","NAME":"Block 2000","OBJECTID":9284096,"TRACT":"601107","CENTLON":"-076.7844073","BLKGRP":"2","AREALAND":335835,"INTPTLON":"-076.7844073","MTFCC":"G5040","LWBLKTYP":"L","COUNTY":"027"}],"Counties":[{"GEOID":"24027","CENTLAT":"+39.2507092","AREAWATER":6336142,"STATE":"24","BASENAME":"Howard","OID":27590157508842,"LSADC":"06","FUNCSTAT":"A","INTPTLAT":"+39.2522639","NAME":"Howard County","OBJECTID":1394,"CENTLON":"-076.9310877","COUNTYCC":"H1","COUNTYNS":"01709077","AREALAND":649952136,"INTPTLON":"-076.9244057","MTFCC":"G4020","COUNTY":"027"}]}}]}}');
            res.setStatusCode(200);
            return res;
        }
		else if(req.getEndpoint().contains('https://geocoding.geo.census.gov/geocoder/geographies/coordinates'))
		{
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'text/json; charset=utf-8');
			res.setBody('{"result":{"input":{"benchmark":{"id":"4","benchmarkName":"Public_AR_Current","benchmarkDescription":"Public Address Ranges - Current Benchmark","isDefault":false},"vintage":{"id":"4","vintageName":"Current_Current","vintageDescription":"Current Vintage - Current Benchmark","isDefault":true},"location":{"x":-76.78832,"y":39.187153}},"geographies":{"2010 Census Blocks":[{"SUFFIX":"","GEOID":"240276011072000","CENTLAT":"+39.1850075","BLOCK":"2000","AREAWATER":0,"STATE":"24","BASENAME":"2000","OID":210404017092858,"LSADC":"BK","FUNCSTAT":"S","INTPTLAT":"+39.1850075","NAME":"Block 2000","OBJECTID":9284096,"TRACT":"601107","CENTLON":"-076.7844073","BLKGRP":"2","AREALAND":335835,"INTPTLON":"-076.7844073","MTFCC":"G5040","LWBLKTYP":"L","COUNTY":"027"}],"Counties":[{"GEOID":"24027","CENTLAT":"+39.2507092","AREAWATER":6336142,"STATE":"24","BASENAME":"Howard","OID":27590157508842,"LSADC":"06","FUNCSTAT":"A","INTPTLAT":"+39.2522639","NAME":"Howard County","OBJECTID":1394,"CENTLON":"-076.9310877","COUNTYCC":"H1","COUNTYNS":"01709077","AREALAND":649952136,"INTPTLON":"-076.9244057","MTFCC":"G4020","COUNTY":"027"}]}}}');
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