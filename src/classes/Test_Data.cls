//class to create test data
public class Test_Data {
    public static Task createTask(){
        Task tsk = new Task();
        tsk.Date_Required__c = System.now();
        tsk.Priority = 'Normal';
        tsk.Subject = 'test Subject';
        return tsk;
    }
    
    public static Event createEvent(){
        Event evt = new Event();
        evt.Subject = 'Test subject';
        evt.ActivityDateTime = System.now();
        evt.EndDateTime = System.now()+10;
        return evt;
    }
    
    public static Task_Action__c createTaskAction (String tskId,String evtId){
        Task_Action__c tskAction = new Task_Action__c();
        tskAction.Assignee__c = UserInfo.getUserId();
        tskAction.Date_Required__c = System.now();
        tskAction.Status__c = 'New';
        tskAction.Task_ID__c = tskId; 
        tskAction.Event_ID__c = evtId;
        tskAction.Type__c = 'Approver';
        return tskAction;
    }
    
    public static Activity_Relationship__c createActRelation(Id tskId,Id evtId){
        Activity_Relationship__c rel = new Activity_Relationship__c();
        rel.Event_ID__c = evtId;
        rel.Task_ID__c = tskId;
        return rel;
    }
    
    public static Notification__c createNotification(Id tskId,Id tskActionId){
        Notification__c notification = new Notification__c();
        notification.Status__c = 'Open';
        if(tskId != null)
        	notification.Task_Id__c = tskId;
        else if(tskActionId  != null)
            notification.Task_Action__c = tskActionId;
        return notification;
    }
    
    public static Notification_Setting__c createNotificationSetting(){
        Notification_Setting__c setting = new Notification_Setting__c();
        setting.Approvers_and_their_EA_s__c = false;
        setting.Content_providers_and_their_EA_s__c = false;
        setting.Managers__c = false;
        setting.Reviewers_and_their_EA_s__c = false;
        setting.Reviewers_and_their_EA_s__c = false;
        setting.Name = 'Default';
        insert setting;
        return setting;
    }
}