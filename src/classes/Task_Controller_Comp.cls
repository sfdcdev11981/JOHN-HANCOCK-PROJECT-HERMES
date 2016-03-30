public class Task_Controller_Comp {
    
    //Query the tasks and return the list
    @auraEnabled
    public static List<TaskWrapper> getTasks(){
        List<TaskWrapper> tskWrapper = new List<TaskWrapper>();
        Boolean isCEO = Utility.isCEO();
        Id currentUserId = Userinfo.getUserId();
        
        Map<Id,Task> tsks ;
        //if CEO the query all tasks otherwise query tasks only assigned to that user
        if(isCEO)
        	tsks = new Map<Id,Task>([select id,owner.Name,Priority,Subject,Date_Required__c,Deliverable__c,Assigned_To__r.Name,Approval_Date__c,recordType.Name from Task]);
        else
            tsks = new Map<Id,Task>([select id,owner.Name,Priority,Subject,Date_Required__c,Deliverable__c,Assigned_To__r.Name,Approval_Date__c,recordType.Name from Task where ownerId =: currentUserId]);
        
        //if tasks are there, query activity relations to get the event id and name for those tasks
        if(tsks != null && tsks.size()>0){
            Map<String,List<Id>> recTypeToTaskIdMap = new Map<String,List<Id>>();
            for(Task tsk : tsks.values()){
                List<Id> sameTypeTasks = recTypeToTaskIdMap.get(tsk.recordType.Name);
                if(sameTypeTasks == null)
                    sameTypeTasks = new List<Id>();
                sameTypeTasks.add(tsk.Id);
                recTypeToTaskIdMap.put(tsk.recordType.Name,sameTypeTasks);
            }
            
            Map<Id,Activity_Relationship__c> relations = new Map<Id,Activity_Relationship__c>([select id,Task_ID__c,Event_ID__c from Activity_Relationship__c where Task_ID__c IN : tsks.keySet()]);
            Map<Id,List<Id>> eventTaskMap = new Map<Id,List<Id>>();
            if(relations != null && relations.size()>0){
                List<Id> evtIds = new List<Id>();
                for(Activity_Relationship__c rel : relations.values()){
                    evtIds.add(rel.Event_ID__c);
                }
                Map<Id,Event> evts = new Map<Id,Event>([select id,subject,Priority__c from Event where ID IN : evtIds]);
                Map<Id,Id> taskToEventMap = new Map<Id,Id>();
                for(Activity_Relationship__c rel : relations.values()){
                    taskToEventMap.put(rel.Task_ID__c,rel.Event_ID__c);
                }
                
                for(String tskType : recTypeToTaskIdMap.keyset()){
                    List<String> evtNames = new List<String>();
                    List<String> eventIds = new List<String>();
                    List<String> taskIds = new List<String>();
                    List<String> tskPriorities = new List<String>();
                    List<String> tskOwners = new List<String>();
                    List<String> deliverable = new List<String>();
                    List<String> due_date = new List<String>();
                    List<String> appr_date = new List<String>();
                    List<String> assigned_to = new List<String>();
                    String tskPriority = 'false';
                    for(Id tskId : recTypeToTaskIdMap.get(tskType)){
                        Task tsk = tsks.get(tskId);
                        String evtName ='';
                        if(taskToEventMap.containsKey(tsk.Id))
                            evtName = evts.get(taskToEventMap.get(tsk.Id)).Subject;
                        evtNames.add(evtName);
                        eventIds.add(evts.get(taskToEventMap.get(tsk.Id)).Id);
                        taskIds.add(tsk.Id);
                        String isHighPriority = tsk.Priority == 'High' ? 'true' : 'false';
                        if(tsk.Priority == 'High')
                            tskPriority = 'true';
                        tskPriorities.add(isHighPriority);
                        tskOwners.add(tsk.owner.Name);
                        deliverable.add(tsk.Deliverable__c);
                        due_date.add(String.valueOf(tsk.Date_Required__c));
                        appr_date.add(String.valueOf(tsk.Approval_Date__c));
                        assigned_to.add(tsk.Assigned_To__r.Name);
                        
                    }
                    tskWrapper.add(new TaskWrapper(tskType,evtNames,eventIds,taskIds,tskPriority,deliverable,tskOwners,due_date,appr_date,assigned_to));
                }
                
            }
        }
        //return the wrapper list
        return tskWrapper;
    }
}