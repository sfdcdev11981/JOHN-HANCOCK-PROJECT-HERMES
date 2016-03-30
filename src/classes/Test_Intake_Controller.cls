@isTest
public class Test_Intake_Controller {
    public static testMethod void Test_Intake_Controller_Test(){
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
        
        Related_Tasks__c recTypesNeeded = new Related_Tasks__c();
        recTypesNeeded.Order__c = 1;
        recTypesNeeded.Name = 'Branding Required';
        recTypesNeeded.Task_Subject__c = 'Branding Required';
        insert recTypesNeeded;
        System.assert(recTypesNeeded.id != null);
        
        Task langTask = Test_Data.createTask();
        Id translationRecordTypeId = [select id from RecordType where name = 'Translation'].Id;
        langTask.RecordTypeId = translationRecordTypeId;
        langTask.Assigned_To__c = UserInfo.getUserId();
        langTask.OwnerId = UserInfo.getUserId();
        langTask.Subject = 'Thai';
        
        System.assert(Intake_Controller.getTypeValues().size()>0);
        System.assert(Intake_Controller.getTaskRecordTypes(evt.Id).size()>0);
        //Intake_Controller.createEvent(evt, JSON.serialize(tsk));
        System.assert(Intake_Controller.getUsersWithGroup().size()>0);
        Intake_Controller.Intake_Data evtData = Intake_Controller.getIntakeData(evt.Id);
        Event evtNew = evtData.evt;
        List<String> taskOwners = evtData.taskOwners;
        List<String> eventTypes = evtData.eventTypes;
        List<Intake_Controller.EventActionWrapper> eventActions = evtData.eventActions;
        List<TaskWithRecordTypeNameWrapper> tasks = evtData.recordTypes;
        List<Task> oldLangTasks = evtData.translationTasks;
        List<Task> newLangTasks = evtData.translationTasks;
        String langSelected = 'French';
        newLangTasks.add(langTask);
        
        tasks[0].required = true;
        tasks[0].appDtTime = system.now();
        eventActions[0].ownerName = UserInfo.getUserId();
        System.debug(Intake_Controller.createEvent(evtNew, JSON.serialize(tasks), JSON.serialize(eventActions),JSON.Serialize(newLangTasks),langSelected,JSON.Serialize(oldLangTasks)));
        
        Test.stopTest();
    }
}