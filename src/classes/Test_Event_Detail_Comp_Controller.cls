@isTest
public class Test_Event_Detail_Comp_Controller {
    public static testMethod void Event_Detail_Comp_Controller_Test(){
        Test.startTest();
        
        //create task
        Task tsk = Test_Data.createTask();
        insert tsk;
        System.assert(tsk.Id != null);
         
        Event evt = Test_Data.createEvent();
        insert evt;
        System.assert(evt.Id != null);
        
        Activity_Relationship__c rel = Test_Data.createActRelation(tsk.Id,evt.id);
        insert rel;
        System.assert(rel.Id != null);
        
        Task_Action__c evtAction = Test_Data.createTaskAction(null, evt.Id);
        insert evtAction;
        System.assert(evtAction.Id != null);
        
        List<List<Object>> wrpItem = Event_Detail_Comp_Controller.getEventDetails(evt.Id);
        System.assert(wrpItem != null);
        
        tsk.Subject = 'New Subject';
        //Event_Detail_Comp_Controller.updateEvent(tsk);
        
        System.assert(Task_Controller_Comp.getTasks().size()>0);
        System.assert(Dashoboard_Controller.getEvents().size()>0);
        
        
        Test.stopTest();
    }
}