public with sharing class WeatherCalloutService {
    public static final String ZONES_FORECAST_BASE_URL = 'https://api.weather.gov/zones/forecast/';

    public WeatherCalloutService() {}

    public static void updateStationData(List<Station__c> stations) {

        for (Station__c station : stations) {
            String endpoint = ZONES_FORECAST_BASE_URL + station.Zone_Id__c + '/forecast';
            HttpRequest forecastRequest = new HttpRequest();
            forecastRequest.setEndpoint(endpoint);
            forecastRequest.setHeader('Content-Type', 'application/json');
            forecastRequest.setMethod('GET');
            Http http = new Http();

            HttpResponse res = http.send(forecastRequest);
        }
    }

    public static StationResponse parseStationResponseData(HttpResponse res) {
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

        }
        return null;
    }

    public static Properties parseForecastData(HttpResponse res) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Object ob = (Object) responseMap.get('properties');
        String objectJSON = JSON.serialize(ob);
        Properties properties = (Properties) JSON.deserialize(objectJSON, Properties.class);

        return properties;
    }

    public class StationResponse {
        @AuraEnabled public String id;
        @AuraEnabled public Properties properties;
    }

    public class Properties {
        @AuraEnabled public String forecast;
        @AuraEnabled public String county;
        @AuraEnabled public String fireWeatherZone;
        @AuraEnabled public Decimal temperature;
        @AuraEnabled public List<ForecastPeriod> periods;
    }

    public class ForecastPeriod {
        @AuraEnabled public String name;
        @AuraEnabled public String detailedForecast;
    }
}
