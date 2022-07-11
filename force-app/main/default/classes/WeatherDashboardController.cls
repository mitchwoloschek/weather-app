public with sharing class WeatherDashboardController {
    public static final String stationWeatherParam = '/observations/latest';
    public static final String STATIONS_BASE_URL = 'https://api.weather.gov/stations';
    public static final String ZONES_BASE_URL = 'https://api.weather.gov/zones';
    public static final String ZONES_FORECAST_BASE_URL = 'https://api.weather.gov/zones/forecast/';

    @AuraEnabled
    public static List<Station__c> getWeather(String state, String city) {
        List<Station__c> existingStations = [SELECT Id, State__c, Station_Id__c, Zone__c FROM Station__c WHERE State__c = :state];

        if (existingStations.size() > 0) {
            return existingStations;
        }

        String endpoint = 'https://api.weather.gov/stations?state=FL';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        Http http = new Http();

        try {
            HttpResponse res = http.send(req);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> features = (List<Object>) responseMap.get('features');

            List<StationResponse> stationResponses = new List<StationResponse>();
            List<String> stationIds = new List<String>();
            for (Object ob : features) {
                String objectJSON = JSON.serialize(ob);
                StationResponse response = (StationResponse) JSON.deserialize(objectJSON, StationResponse.class);
                stationResponses.add(response);
                stationIds.add(response.id);
            }

            if (stationResponses.size() > 0) {
                List<Station__c> newStations = new List<Station__c>();

                List<Station__c> currentStations = [SELECT Id, Station_Id__c FROM Station__c WHERE Station_Id__c IN :stationIds];
                Set<String> currentStationIds = (Set<String>) pluckStrings(currentStations, Station__c.Station_Id__c);
                Datetime now = DateTime.now();

                for (StationResponse sr : stationResponses) {
                    if (!currentStationIds.contains(sr.id)) {
                        Station__c newStation = new Station__c(
                            Station_Id__c = sr.id, State__c = state, Zone__c = sr.properties.forecast,
                            County_Zone__c = sr.properties.county, Fire_Weather_Zone__c = sr.properties.fireWeatherZone
                        );
                        newStation.Zone_Id__c = newStation.Zone__c.remove(ZONES_FORECAST_BASE_URL).deleteWhitespace();
                        newStations.add(newStation);
                    }
                }

                if (newStations.size() > 0) {
                    insert newStations;
                }
            }

        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }

        return null;
    }

    public class StationResponse {
        @AuraEnabled public String id;
        @AuraEnabled public Properties properties;
    }

    public class Properties {
        @AuraEnabled public String forecast;
        @AuraEnabled public String county;
        @AuraEnabled public String fireWeatherZone;
    }

    // TODO: Pull method into its own CollectionUtils class.
    private static Set<String> pluckStrings(List<SObject> records, Schema.SObjectField stringField) {
        Set<String> strings = new Set<String>();

        for (SObject record : records) {
            String s = (String) record.get(stringField);

            if (s != null) {
                strings.add(s);
            }
        }

        return strings;
    }
}
