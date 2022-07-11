public with sharing class WeatherStationSchedule implements Schedulable {
    public WeatherStationSchedule() {}

    public void execute(SchedulableContext sc) {
        Database.executebatch(new WeatherStationBatch(), 10);
    }
}
