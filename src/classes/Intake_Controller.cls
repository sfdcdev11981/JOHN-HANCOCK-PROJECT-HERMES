public class Intake_Controller {
    
    //get the picklist values of event subject field and retrun the list
    @auraEnabled
    public static List<String> getTypeValues(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Event.Type.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(f.getValue());
        }    
        return options;
    }
    
    //accepts event and tasks as paramter and create them
    //was getting internat server error if passing task as object so passed as string
    @auraEnabled
    public static msgWrapper createEvent(SObject newEvent,string tasksAsString,String evtActionsAsString,String langTransTasks,String langSelected,String oldLangsTransTasks){
        try{
            Event evt = (Event)newEvent;
            upsert evt;
            List<Task> tskToInsert = new List<Task>();
            List<Task> tskToDelete = new List<Task>();
            List<Id> tskToDeleteId = new List<Id>();
            Set<Id> taskIdToDismissNotification = new Set<Id>();
            Set<Id> taskIdToOpenNotification = new Set<Id>();
            Boolean isBrieingRequired = false;
            Object[] tasksAsObj = (Object[])System.JSON.deserializeUntyped(tasksAsString);
            Object[] langAsObj = (Object[])System.JSON.deserializeUntyped(langTransTasks);
            Object[] oldLangAsObj = (Object[])System.JSON.deserializeUntyped(oldLangsTransTasks);
            Object[] evtActionAsObj = (Object[])System.JSON.deserializeUntyped(evtActionsAsString);
            
            // Go through all the tasks
            for(Object  tsk : tasksAsObj){
                Map<String,Object> mapTasks = (Map<String,Object>)tsk;
                Map<String,Object> tastDetail = (Map<String,Object>)mapTasks.get('tsk');
                String oldTaskId = (String) tastDetail.get('Id');
                //if task is required, add it to tasks to create list
                if((Boolean)mapTasks.get('required')){
                    Task newTsk = new Task();
                    // if task  is already existing, add it to list to upsert
                    if(oldTaskId != null)
                        newTsk.id = oldTaskId;
                    newTsk.recordTypeId = (String)mapTasks.get('tskRecordTypeId');
                    newTsk.Assigned_To__c = (String)mapTasks.get('Assigned_To__c');
                    if((String)mapTasks.get('ownerId') != null && (String)mapTasks.get('ownerId') != '')
                        newTsk.OwnerId = (String)mapTasks.get('ownerId'); 
                    else                                  
                        newTsk.OwnerId = UserInfo.getUserId();
                    newTsk.Subject = (String)mapTasks.get('tskrecordTypeName');
                    if(newTsk.Subject == 'Briefing Notes Required')
                        isBrieingRequired = true;
                    newTsk.Status = ((String)mapTasks.get('status') != null && (String)mapTasks.get('status') != '') ? (String)mapTasks.get('status') : 'Not Started';
                    System.debug('++++'+newTsk.Status);
                    if(newTsk.Status == 'Completed' && oldTaskId != null)
                    	taskIdToDismissNotification.add(newTsk.Id);
                    else if(oldTaskId != null)
                        taskIdToOpenNotification.add(newTsk.Id);
                    newTsk.Deliverable__c = (String)mapTasks.get('delivery');
                    newTsk.Priority = (Boolean)(mapTasks.get('highPriority')) ? 'High' : 'Normal';
                    newTsk.Date_Required__c = convertDate((String)mapTasks.get('tskDtTime'));
                    newTsk.Approval_Date__c = convertDate((String)mapTasks.get('appDtTime'));
                    tskToInsert.add(newTsk);
                }
                else{  //if not required, delete it
                    if(oldTaskId != null){
                        tskToDelete.add(new Task (id = oldTaskId));
                        tskToDeleteId.add(oldTaskId);
                    }
                    
                }
            }
            if(!isBrieingRequired){   // If briefing task is not seleted, empty briefing fields
                evt.Additional_Information__c = '';
                evt.Suggested_Topic__c = '';
                evt.Audience__c = '';
                evt.Time_of_Remarks__c = null;
                evt.Introduced_by__c = '';
                evt.Agenda__c = '';
                evt.Venue__c = '';
                evt.Briefing_Date__c = null;
                evt.Dress_Code__c = '';
                evt.Room_Setup__c = '';
                evt.Table_Seating__c = '';
                evt.Event_Background__c = '';
                update evt;
            }
            List<String> actionToDeleteIds = new List<String>();
            List<Task_Action__c> actionToDelete = new List<Task_Action__c>();
            List<Task_Action__c> actionToUpsert = new List<Task_Action__c>();
            //loop throug all the event actions and insert or delete them
            for(Object  evtAction : evtActionAsObj){
                Map<String,Object> mapactions = (Map<String,Object>)evtAction;
                String oldActionId = (String) mapactions.get('actionId');
                if((Boolean)mapactions.get('isRequired')){
                    Task_Action__c action = new Task_Action__c();
                    if(oldActionId != null && oldActionId.length()>0)
                        action.Id = oldActionId;
                    String evtdt = (String)mapactions.get('dateRequired');
                    action.Date_Required__c = convertDate(evtdt);
                    action.Assignee__c = (String)mapactions.get('ownerName'); 
                    action.Status__c = (String)mapactions.get('status');
                    action.Type__c = (String)mapactions.get('label');
                    action.Event_ID__c = newEvent.id;
                    actionToUpsert.add(action);
                }
                else{
                    if(oldActionId != null)
                        actionToDelete.add(new Task_Action__c(id=oldActionId));
                }
                
            }
            if(actionToUpsert != null && actionToUpsert.size()>0){
                upsert actionToUpsert;
            }
            if(actionToDelete != null && actionToDelete.size()>0){
                delete actionToDelete;
            }
            //if there are some task, insert them
            if(tskToInsert != null && tskToInsert.size()>0)
                upsert tskToInsert;
            
            List<Activity_Relationship__c> relationToDelete = [select id from Activity_Relationship__c where Task_ID__c IN : tskToDeleteId];
            
            if(relationToDelete != null && relationToDelete.size()>0){
                delete relationToDelete;
                upsert tskToDelete;
            }
            
            
            //insert activity relation for every task against the event
            List<Activity_Relationship__c> activityRel = new List<Activity_Relationship__c>();
            for(Task tsk : tskToInsert){
                Activity_Relationship__c relation = new Activity_Relationship__c();
                relation.Event_ID__c = evt.Id;
                relation.Event_Start_Date_Time__c = evt.StartDateTime;
                relation.Event_Subject__c = evt.Subject;
                relation.Event_Type__c = evt.Type;
                relation.Task_ID__c = tsk.Id;
                relation.Task_Subject__c = tsk.Subject;
                relation.Task_Type__c = tsk.type;
                activityRel.add(relation);
            }
            
            Id transRecTypeId = [select id from RecordType where name = 'Translation'].Id;
            Set<String> evtLanguages = new Set<String>();
            
            if(langSelected != null && langSelected != ''){
                evtLanguages = new Set<String>(langSelected.split(';'));
            }
            List<Task> langToInsert = new LIst<Task>();
            List<Task> langToUpdate = new LIst<Task>();
            Set<String> langToUpdateIds = new Set<String>();
            List<Task> langTodelete = new List<Task>();
            Set<String> langTodeleteId = new Set<String>();
            //loop through all the translation tasks
            //if task is existing , update it
            //otherwise create it
            for(Object  tsk : langAsObj){
                Map<String,Object> mapTasks = (Map<String,Object>)tsk;
                Task newTask = new Task();
                newTask.Date_Required__c = convertDate((String)mapTasks.get('activityDate'));
                newTask.Assigned_To__c = (String)mapTasks.get('Assigned_To__c');
                newTask.RecordTypeId = transRecTypeId;
                newTask.Subject = (String)mapTasks.get('Subject');
                if(mapTasks.containsKey('Id')) {
                    newTask.Id = (String)mapTasks.get('Id');
                    if(!evtLanguages.contains(newTask.Subject)){
                        langTodelete.add(newTask);
                        langTodeleteId.add(newTask.Id);
                    }
                    else{
                        langToUpdate.add(newTask);
                        langToUpdateIds.add(newTask.Id);
                    }
                }
                else if(evtLanguages.contains(newTask.Subject))
                    langToInsert.add(newTask);
                
            }
            //if translation task was there before, but not now, delete it
            for(Object  tsk : oldLangAsObj){
                Map<String,Object> mapTasks = (Map<String,Object>)tsk;
                Task newTask = new Task();
                newTask.Id = (String)mapTasks.get('Id');
                if(!langToUpdateIds.contains(newTask.Id) && !langTodeleteId.contains(newTask.Id))    {
                    langTodeleteId.add(newTask.Id);
                    langTodelete.add(newTask);
                }
                    
            }
            
            insert langToInsert;
            update langToUpdate;
            //create Activity relation for all the new translation tasks
            for(Task tsk : langToInsert){
                Activity_Relationship__c relation = new Activity_Relationship__c();
                relation.Event_ID__c = evt.Id;
                relation.Task_ID__c = tsk.Id;
                activityRel.add(relation);
            }
            insert activityRel;
            // remove activity relations for deleting tasks
            if(langTodeleteId != null && langTodeleteId.size() > 0){
                delete ([select id from Activity_Relationship__c where Task_ID__c IN : langTodeleteId]);
                delete langTodelete;
            } 
            
            List<Notification__c> notificationToUpdate = new List<Notification__c>();
            System.debug(taskIdToDismissNotification);
            System.debug(taskIdToOpenNotification);
            //dismiss the notifications for completed tasks
            if((taskIdToDismissNotification != null && taskIdToDismissNotification.size()>0) ||(taskIdToOpenNotification != null && taskIdToOpenNotification.size()>0)){
                for(Notification__c notification : [select id,status__c,Task_Id__c from notification__c where Task_Id__c IN : taskIdToDismissNotification OR Task_Id__c IN : taskIdToOpenNotification]){
                    if(taskIdToDismissNotification.contains(notification.Task_Id__c))
                    	notification.status__c = 'Dismissed';
                    else if(taskIdToOpenNotification.contains(notification.Task_Id__c))
                    	notification.status__c = 'Open';
                    notificationToUpdate.add(notification);
                }
            }
            System.debug(notificationToUpdate);
            update notificationToUpdate;
            msgWrapper result= new msgWrapper(newEvent.Id,'','SUCCESS'); 
            return result; 
            
        }
        catch(Exception e){
            msgWrapper result = new msgWrapper(newEvent.Id,e.getMessage(),'FAIL');
            return result; 
        } 
        
    }
    
    public static DateTime convertDate(String dateString){
        return DateTime.valueOfGmt(dateString.split('T')[0]+' '+(dateString.split('T')[1]).split('\\.')[0]);
    }
    
    // wrapper class to hold the result
    // if exception comes , msgcode will be failed
    // else success
    public class msgWrapper{
        @auraEnabled
        public String recId{get;set;}
        @auraEnabled
        public String msg{get;set;}
        @auraEnabled
        public String msgCode{get;set;}
        
        public msgWrapper(String recId,String msg,String msgCode){
            this.recId = recId;
            this.msg = msg;
            this.msgCode = msgCode;
        }
    }
    
    // query all record types of Task object
    // get all those specified in custom setting
    // make them in sequence
    // return the wrapper list
    @auraEnabled
    public static List<TaskWithRecordTypeNameWrapper> getTaskRecordTypes(String evtId){ 
        Schema.DescribeSObjectResult sobjectResult = Schema.getGlobalDescribe().get('Task').getDescribe();
        List<Schema.RecordTypeInfo> recordTypeInfo = sobjectResult.getRecordTypeInfos();
        Map<String,TaskWithRecordTypeNameWrapper> lstTaskWrapper = new Map<String,TaskWithRecordTypeNameWrapper>();
        Map<String,Task> eventTask = getEventTasks(evtId);      
        Integer tskNo = 0;
        for(Schema.RecordTypeInfo info : recordTypeInfo){
            if(eventTask.containsKey(info.getName())){
                Task tsk = eventTask.get(info.getName());
                Boolean isHighPriority = tsk.Priority == 'High' ? true : false;
                lstTaskWrapper.put(info.getName(),new TaskWithRecordTypeNameWrapper('tskDate'+tskNo,info.getName(),info.getRecordTypeId(),isHighPriority,tsk.Date_Required__c,tsk.Owner.Name,true,tsk));
                tskNo++;
            }
            else{
                Task tsk = new Task();
                lstTaskWrapper.put(info.getName(),new TaskWithRecordTypeNameWrapper('tskDate'+tskNo,info.getName(),info.getRecordTypeId(),false,System.now(),'',false,tsk));
                tskNo++;
            }
            
        }
        List<Related_Tasks__c> nameRecords = [select id,name,Task_Subject__c,Order__c from Related_Tasks__c order by Order__c];
        List<TaskWithRecordTypeNameWrapper> lstTaskWrapperSeq = new List<TaskWithRecordTypeNameWrapper>();
        
        if(nameRecords != null && nameRecords.size()>0){
            for(Related_Tasks__c rel : nameRecords){
                lstTaskWrapperSeq.add(lstTaskWrapper.get(rel.Task_Subject__c));
            }
            lstTaskWrapperSeq.add(lstTaskWrapper.get('Branding Required'));
            lstTaskWrapperSeq.add(lstTaskWrapper.get('Outline Required'));
            return lstTaskWrapperSeq; 
        }
        else{
            return lstTaskWrapper.values();
        }
        
    }
    
    // get all the tasks related to event
    //first query the activity relations , get the task ids then query tasks
    @auraEnabled 
    public static Map<String,Task> getEventTasks(String evtId){
        Map<String,Task> eventTasks = new Map<String,Task>();
        List<Id> tskIds = new List<Id>();
        for(Activity_Relationship__c relation : [select id,Event_ID__c,Task_ID__c from Activity_Relationship__c where Event_ID__c =: evtId]){
            tskIds.add(relation.Task_ID__c);
        }
        if(tskIds != null && tskIds.size()>0){
            for(Task tsk : [select id,Subject,recordType.Name,Date_Required__c,Owner.Name,Owner.Id,Status,Priority,Deliverable__c,Assigned_To__c,Assigned_To__r.Name,Approval_Date__c from Task where ID IN : tskIds]){
                eventTasks.put(tsk.recordType.Name,tsk);
            }
        }
        return eventTasks;
    }
    
    // metod to return Intake page data
    // it will get all  the tasks, event actions and event details and make the wrapper and return it
    @auraEnabled
    public static Intake_Data getIntakeData(String evtId){
        Event evt ;
        if(evtid == ''){
            evt = new Event(Subject = 'test evt');
        }
        else{
            evt = [select id,Subject,Type,Audience__c,Suggested_Topic__c,Time_of_Remarks__c,Introduced_by__c,Agenda__c,Venue__c,Dress_Code__c,Briefing_Date__c,Room_Setup__c,Table_Seating__c,Event_Background__c,Additional_Information__c,StartDateTime,EndDateTime,OwnerId,Owner.Id,Owner.Name,Trip_Details_Required__c,Trip_Location__c,Trip_Date__c,Approval_Date__c,Review_Date__c,Translation_Required__c,Languages__c from Event where id=: evtId];
        }
        List<EventActionWrapper> eventActions = new List<EventActionWrapper>();
        Integer index= 0;
        Set<String> actionTypes = new Set<String>{'Content Providers','Writers','Reviewers','Approvers'};
            if(evtId != ''){
                for(Task_Action__c action : [select id,Assignee__r.Name,Date_Required__c,Status__c,Type__c from Task_Action__c where Event_ID__c =:evtId]){
                    EventActionWrapper actionWrapper = new EventActionWrapper(true,action.Assignee__r.Name,action.Date_Required__c,action.Status__c,action.id,action.Type__c,'action'+index);
                    if(actionTypes.contains(action.Type__c))
                        actionTypes.remove(action.Type__c);
                    eventActions.add(actionWrapper);
                    index++;
                } 
            }
        if(actionTypes.size() != 0){
            for(String actionType : actionTypes){
                eventActions.add(new EventActionWrapper(false,null,null,null,null,actionType,'action'+index));
                index++;
            }
        }
        List<String> eventTypes = getTypeValues();
        List<String> taskOwners = getUsersWithGroup();
        List<TaskWithRecordTypeNameWrapper> recordTypes = getTaskRecordTypes(evtId);
        
        List<Task> translationTasks = new List<Task>();
        List<Id> tskIds = new List<Id>();
        for(Activity_Relationship__c relation : [select id,Event_ID__c,Task_ID__c from Activity_Relationship__c where Event_ID__c =: evtId]){
            tskIds.add(relation.Task_ID__c);
        }
        for(Task tsk : [select id,Subject,Owner.Name,Date_Required__c,Assigned_To__r.Name,Status from Task where recordType.Name = 'Translation' AND ID IN : tskIds]){
            translationTasks.add(tsk);
        }
        
        return new Intake_Data(evt,taskOwners,eventTypes,recordTypes,eventActions,translationTasks);
    }
    
    //get the list of owners of task owners group
    @auraEnabled
    public static List<String> getUsersWithGroup(){
        return Utility.getGroupUsers('Task owners');
    }
    //wrapper class to return Intake page data
    public class Intake_Data{
        @auraEnabled
        public Event evt{get;set;}
        @auraEnabled
        public List<String> taskOwners{get;set;}
        @auraEnabled
        public List<String> eventTypes{get;set;}
        @auraEnabled
        public List<TaskWithRecordTypeNameWrapper> recordTypes{get;set;}
        @auraEnabled
        public List<EventActionWrapper> eventActions = new List<EventActionWrapper>();
        @auraEnabled 
        public List<Task> translationTasks{get;set;}
        
        public Intake_Data (Event evt,List<String> taskOwners,List<String> eventTypes,List<TaskWithRecordTypeNameWrapper> recordTypes,List<EventActionWrapper> eventActions,List<Task> translationTasks){
            this.evt = evt;
            this.taskOwners = taskOwners;
            this.eventTypes = eventTypes;
            this.recordTypes = recordTypes;
            this.eventActions = eventActions;
            this.translationTasks = translationTasks;
        }
    }
    
    public class EventActionWrapper{
        @auraEnabled
        public Boolean isRequired{get;set;}
        @auraEnabled
        public String ownerName{get;set;}
        @auraEnabled
        public DateTime dateRequired{get;set;}
        @auraEnabled
        public String status{get;set;}
        @auraEnabled
        public String actionId{get;set;}
        @auraEnabled
        public String label{get;set;}
        @auraEnabled
        public String actionClass{get;set;}
        
        public EventActionWrapper(Boolean isRequired,String ownerName,DateTime dateRequired,String status,String actionId,String label,String actionClass){
            this.isRequired = isRequired;
            this.ownerName = ownerName;
            this.dateRequired = dateRequired;
            this.status = status;
            this.actionId = actionId;
            this.label = label;
            this.actionClass = actionClass;
        }
    }
}