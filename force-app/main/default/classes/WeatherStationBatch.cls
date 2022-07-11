public with sharing class WeatherStationBatch implements Database.Batchable<SObject> {
    public WeatherStationBatch() {}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Zone__c, Zone_Id__c FROM Station__c');
    }

    public void execute(Database.BatchableContext bc, List<Station__c> scope) {
        WeatherCalloutService.updateStationData(scope);
    }

    public void finish(Database.BatchableContext bc) {}
}
