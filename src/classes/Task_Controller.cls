public class Task_Controller {
	@auraEnabled
    public static List<Task> getTasks(){
        return [select id,Subject,Date_Required__c,Owner.Name,Who.Name from Task];
    }
}