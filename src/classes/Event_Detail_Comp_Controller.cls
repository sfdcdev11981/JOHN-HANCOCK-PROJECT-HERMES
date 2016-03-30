public class Event_Detail_Comp_Controller {
    //on event detail page, dynamically load all the filed that need to display from custom metadata
    @auraEnabled
    public static List<List<Object>> getEventDetails(String evtId){
        List<LabelValueWrapper> eventDetails = new List<LabelValueWrapper>();
        List<LabelValueWrapper> eventBriefingDetails = new List<LabelValueWrapper>();
        List<taskWrapper> taskDetails = new List<taskWrapper>();
        List<EventActionWrapper> actionsWrapper = new List<EventActionWrapper>();
        
        //query custom metadata and get fields to dispaly
        List<Config__mdt> config = [select id,Briefing_Note_Fields__c,Event_Details_Fields__c from Config__mdt where DeveloperName='Default' LIMIT 1];
        String fieldsToRetrieve = 'Id';
        String detail_fields = '';
        String brief_fields = '';
        if(config != null && config.size() >0){
            detail_fields = config[0].Event_Details_Fields__c;
            brief_fields  = config[0].Briefing_Note_Fields__c;
        }
        
        fieldsToRetrieve += ','+detail_fields;
        fieldsToRetrieve += ','+brief_fields;
        
        String query = 'Select '+ fieldsToRetrieve +' from Event where id = \''+evtId+'\' LIMIT 1';
        List<Event> evts = database.query(query);
        Event evt;
        if(evts != null && evts.size()>0)
            evt = evts[0];
        
        List<Id> tskIds = new List<Id>();
        //query activity relations to get task id
        for(Activity_Relationship__c relation : [select id,Event_ID__c,Task_ID__c from Activity_Relationship__c where Event_ID__c =: evtId]){
            tskIds.add(relation.Task_ID__c);
        }
        List<Task> tsks = new List<Task>();
        Task briefingTsk  ;
        //query the tasks
        if(tskIds != null && tskIds.size()>0){
            String taskQuery = 'select id,Subject,Owner.Name,Date_Required__c,recordType.Name from Task where Id IN : tskIds';
            tsks = Database.query(taskQuery);
            for(Task tsk : tsks){
                taskDetails.add(new taskWrapper(tsk.recordType.Name,tsk.Owner.Name,String.valueOf(tsk.Date_Required__c.Date()),String.valueOf(tsk.Date_Required__c.Time()),tsk.Id));
            }
            
        }
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType eventSchema = schemaMap.get('Event');
        Map<String, Schema.SObjectField> fieldMap = eventSchema.getDescribe().fields.getMap();
        //Get the fields, query them and add to the wrapper
        for(String field : detail_fields.split(',')){
            String fldLabel = fieldMap.get(field).getDescribe().getLabel();
            String fldType = String.valueOf(fieldMap.get(field).getDescribe().getType());
            String event_text;
            if(fldType == 'BOOLEAN'){
                event_text = evt.get(field) == true ? 'Yes' : 'No';
            }
            else
                event_text = String.valueOf(evt.get(field));
            eventDetails.add(new LabelValueWrapper(fldLabel,event_text));
        }
        for(String field : brief_fields.split(',')){
            String fldLabel = fieldMap.get(field).getDescribe().getLabel();
            String fldType = String.valueOf(fieldMap.get(field).getDescribe().getType());
            String event_text;
            if(fldType == 'BOOLEAN'){
                event_text = evt.get(field) == true ? 'Yes' : 'No';
            }
            else
                event_text = String.valueOf(evt.get(field));
            eventBriefingDetails.add(new LabelValueWrapper(fldLabel,event_text));
        }
        
        for(Task_Action__c action : [select id,Assignee__r.Name,Date_Required__c,Event_ID__c,Status__c,Type__c from Task_Action__c where Event_ID__c =: evtId]){
            actionsWrapper.add(new EventActionWrapper(action.Type__c,action.Assignee__r.Name,String.valueOf(action.Date_Required__c.Date()),action.Status__c,null,null,false));
        } 
        
        List<List<Object>> detailsToReturn = new List<List<Object>>();
        detailsToReturn.add(eventDetails);
        detailsToReturn.add(eventBriefingDetails);
        detailsToReturn.add(taskDetails);
        detailsToReturn.add(actionsWrapper);
        
        return detailsToReturn;
    }
    
    //Wrapper class to hold task data
    public class LabelValueWrapper{
        @auraEnabled
        public String event_name {get;set;}
        @auraEnabled
        public String event_text{get;set;}
        
        public LabelValueWrapper(String label,String value){
            event_name = label;
            event_text = value;
        }
        
    }
    
    public class taskWrapper{
        @auraEnabled
        public String task_type {get;set;}
        @auraEnabled
        public String task_owner{get;set;}
        @auraEnabled
        public String task_due_date{get;set;}
        @auraEnabled
        public String task_due_time{get;set;}
        @auraEnabled
        public String task_id{get;set;}
        
        public taskWrapper(String task_type,String task_owner,String task_due_date,String task_due_time,String task_id){
            this.task_type = task_type;
            this.task_owner = task_owner;
            this.task_due_date = task_due_date;
            this.task_due_time = task_due_time;
            this.task_id = task_id;
        }
        
    }
    
    public class EventActionWrapper{
        @auraEnabled
        public String action_type {get;set;}
        @auraEnabled
        public String action_id {get;set;}
        @auraEnabled
        public String owner_id {get;set;}
        @auraEnabled
        public String action_owner{get;set;}
        @auraEnabled
        public String action_due_date{get;set;}
        @auraEnabled
        public String action_status{get;set;}
        @auraEnabled
        public Boolean haveNotification{get;set;}
        
        public EventActionWrapper(String action_type,String action_owner,String action_due_date,String action_status,String action_id,String owner_id,Boolean haveNotification){
            this.action_type = action_type;
            this.action_owner = action_owner;
            this.action_due_date = action_due_date;
            this.action_status = action_status;
            this.action_id = action_id;
            this.owner_id = owner_id;
            this.haveNotification = haveNotification;
        }
        
    }
}