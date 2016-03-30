public class Dashoboard_Controller {
    //method to query Events and return the list
    @auraEnabled
    public static List<Event> getEvents(){
        String eventQuery = 'select Id,Subject,StartDateTime from Event';
        if(!Utility.isCEO())
            eventQuery += ' where ownerid= \''+UserInfo.getUserId()+'\'';
        return Database.query(eventQuery);
    }
}