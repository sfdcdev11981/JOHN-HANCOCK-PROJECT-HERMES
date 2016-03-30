@isTest
public class Test_Task_Detail_Comp_Controller {
    public static testMethod void Task_Detail_Comp_Controller_Test(){
        Test.startTest();
        
        //create task
        Task tsk = Test_Data.createTask();
        insert tsk;
        System.assert(tsk.Id != null);
        
        //create event
        Event evt = Test_Data.createEvent();
        insert evt;
        System.assert(evt.Id != null);
        
        //create task action
        Task_Action__c tskAction = Test_Data.createTaskAction(tsk.id,null);
        insert tskAction;
        System.assert(tskAction.Id != null);
        
        Activity_Relationship__c relation = Test_Data.createActRelation(tsk.Id,evt.Id);
        insert relation;
        System.assert(relation.Id != null);
        
        List<Task_Action__c> tskActions = Task_Detail_Comp_Controller.getTaskData(tsk.id);
        System.assert(tskActions.size() == 1);
        
        List<String> usrs = Task_Detail_Comp_Controller.getUsersWithGroup();
        Task_Detail_Comp_Controller.getTaskDetailData(tsk.Id);
        tskAction.Status__c = 'Completed';
        Task_Detail_Comp_Controller.upsertTaskAction(tskAction,true);
        System.assert(tskAction.Status__c == 'Completed');
        
		Task_Detail_Comp_Controller.deleteAction(tskAction.id);   
        System.assert(Task_Controller.getTasks().size()>0);
        Task_Detail_Comp_Controller.deleteTaskAndEvent(evt.Id);
        
        Task_Detail_Comp_Controller.addNewNotification(tskAction.Id, false);
        Task_Detail_Comp_Controller.addNewNotification(tsk.Id, true);
        
        Task_Detail_Comp_Controller.dismissOrDeleteNotifications(tsk.Id);
        Task_Detail_Comp_Controller.dismissOrDeleteNotifications(tskAction.Id);
        Test.stopTest();
    }
}