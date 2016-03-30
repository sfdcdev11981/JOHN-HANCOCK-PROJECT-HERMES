@isTest
public class TestDashboardNotificationController {
    public static testMethod void notificationControllerTest(){
        Test.startTest();
        //create task
        Task tsk = Test_Data.createTask();
        insert tsk;
        System.assert(tsk.Id != null);
        
        //create task action
        Task_Action__c tskAction = Test_Data.createTaskAction(tsk.id,null);
        insert tskAction;
        System.assert(tskAction.Id != null);
        
        Notification__c notificationTask = Test_Data.createNotification(tsk.Id, null);
        insert notificationTask;
        System.assert(notificationTask.Id != null);
        
        Notification__c notificationTaskAction = Test_Data.createNotification(null, tskAction.Id);
        insert notificationTaskAction;
        System.assert(notificationTaskAction.Id != null);
        
        Notification_Setting__c setting  =  Test_Data.createNotificationSetting();
        System.assert(setting.Id != null);
        
        DashboardNotificationController.ResultWrapper result = DashboardNotificationController.getNotifications(false);
        
        DashboardNotificationController.dismissOrDeleteNotifications(notificationTask.Id);
        result = DashboardNotificationController.getNotifications(false);
        
        DateTime timelessThanOneHour = System.now();
        timelessThanOneHour  = timelessThanOneHour.addMinutes(25);
        tsk.Date_Required__c = timelessThanOneHour;
        update tsk;
        result = DashboardNotificationController.getNotifications(false);
        
    }
}