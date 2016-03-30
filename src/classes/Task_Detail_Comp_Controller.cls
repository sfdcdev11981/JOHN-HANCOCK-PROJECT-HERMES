public class Task_Detail_Comp_Controller {
    
    @auraEnabled
    public static List<Object> getTaskDetailData(String tskId){
        List<Object> taskDetailData = new List<Object>();
        List<Event_Detail_Comp_Controller.LabelValueWrapper> evtData= new List<Event_Detail_Comp_Controller.LabelValueWrapper>();
        List<Event_Detail_Comp_Controller.EventActionWrapper> CPData= new List<Event_Detail_Comp_Controller.EventActionWrapper>();
        List<Event_Detail_Comp_Controller.EventActionWrapper> reviewerData= new List<Event_Detail_Comp_Controller.EventActionWrapper>();
        List<Event_Detail_Comp_Controller.EventActionWrapper> approverData= new List<Event_Detail_Comp_Controller.EventActionWrapper>();
        List<Event_Detail_Comp_Controller.EventActionWrapper> writerData= new List<Event_Detail_Comp_Controller.EventActionWrapper>();
        
        Boolean isNotificationEnabledForTask = false;
        
        //query custom metadata and get fields to dispaly
        List<Config__mdt> config = [select id,Briefing_Note_Fields__c from Config__mdt where DeveloperName='Default' LIMIT 1];
        String fieldsToRetrieve = 'Id';
        String brief_fields = '';
        if(config != null && config.size() >0){
            brief_fields  = config[0].Briefing_Note_Fields__c;
        }
        
        fieldsToRetrieve += ','+brief_fields;
        String evtId = '';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType eventSchema = schemaMap.get('Event');
        Map<String, Schema.SObjectField> fieldMap = eventSchema.getDescribe().fields.getMap();
        //query activity relations to get Event id
        for(Activity_Relationship__c relation : [select id,Event_ID__c,Task_ID__c from Activity_Relationship__c where Task_ID__c =: tskId LIMIT 1]){
            evtId = relation.Event_ID__c;
        }
        
        if(evtId != null && evtId.length()>0){
            String query = 'Select '+ fieldsToRetrieve +' from Event where id = \''+evtId+'\' LIMIT 1';
            List<Event> evts = database.query(query);
            if(evts != null && evts.size() > 0){
                Event evt = evts[0];
                for(String field : brief_fields.split(',')){
                    String fldLabel = fieldMap.get(field).getDescribe().getLabel();
                    String fldType = String.valueOf(fieldMap.get(field).getDescribe().getType());
                    String event_text;
                    if(fldType == 'BOOLEAN'){
                        event_text = evt.get(field) == true ? 'Yes' : 'No';
                    }
                    else
                        event_text = String.valueOf(evt.get(field));
                    evtData.add(new Event_Detail_Comp_Controller.LabelValueWrapper(fldLabel,event_text));
                }
            }
        }
        
        Map<String,String> taskActionToNotifications = new Map<String,String>();
        for(Notification__c notification : [select id,Task_Id__c,Task_Action__c from notification__c ]){
            if(notification.Task_Id__c != null)
                taskActionToNotifications.put(notification.Task_Id__c,notification.Id);
            else if(notification.Task_Action__c != null)
                taskActionToNotifications.put(notification.Task_Action__c,notification.Id);
        }
        
        //query all the task action data, add them to list and add the list to wrapper
        for(Task_Action__c action : [select id,Assignee__r.Name,Date_Required__c,Event_ID__c,Status__c,Type__c,Assignee__c from Task_Action__c where Task_ID__c =: tskId]){
            Boolean haveNotification = taskActionToNotifications.containsKey(action.Id) ? true : false;
            if(action.Type__c == 'Content Providers') 
                CPData.add(new Event_Detail_Comp_Controller.EventActionWrapper(action.Type__c,action.Assignee__r.Name,String.valueOf(action.Date_Required__c),action.Status__c,action.Id,action.Assignee__c,haveNotification));
            else if(action.Type__c == 'Writers') 
                writerData.add(new Event_Detail_Comp_Controller.EventActionWrapper(action.Type__c,action.Assignee__r.Name,String.valueOf(action.Date_Required__c),action.Status__c,action.Id,action.Assignee__c,haveNotification));
            else if(action.Type__c == 'Reviewers') 
                reviewerData.add(new Event_Detail_Comp_Controller.EventActionWrapper(action.Type__c,action.Assignee__r.Name,String.valueOf(action.Date_Required__c),action.Status__c,action.Id,action.Assignee__c,haveNotification));
            else if(action.Type__c == 'Approvers') 
                approverData.add(new Event_Detail_Comp_Controller.EventActionWrapper(action.Type__c,action.Assignee__r.Name,String.valueOf(action.Date_Required__c),action.Status__c,action.Id,action.Assignee__c,haveNotification));
        } 
        
        if(taskActionToNotifications.containsKey(tskId))
            isNotificationEnabledForTask = true;
        
        taskDetailData.add(evtData);
        taskDetailData.add(CPData);
        taskDetailData.add(reviewerData);
        taskDetailData.add(approverData);
        taskDetailData.add(writerData);
        taskDetailData.add(Utility.getGroupUsers('Content providers'));
        taskDetailData.add(Utility.getGroupUsers('Writers'));
        taskDetailData.add(Utility.getGroupUsers('Reviewers'));
        taskDetailData.add(Utility.getGroupUsers('Approvers'));
        taskDetailData.add(evtId);
        taskDetailData.add(isNotificationEnabledForTask);
        return taskDetailData;
    }
    
    //return the detail of task 
    //task id is provided as parameter
    @auraEnabled
    public static List<Task_Action__c> getTaskData(String tskId){
        List<Task_Action__c> tskActions = [select id,Name,Assignee__r.Name,Date_Required__c,Status__c,Task_ID__c,Type__c from Task_Action__c where Task_ID__c =: tskId];
        return tskActions;
    }
    
    //get all the 4 groups members
    @auraEnabled
    public static List<String> getUsersWithGroup(){
        List<String> users = new List<String>();
        for(String usr : Utility.getGroupUsers('Content providers')){
            users.add('CP'+usr);
        }
        for(String usr : Utility.getGroupUsers('Writers')){
            users.add('WR'+usr);
        }
        for(String usr : Utility.getGroupUsers('Reviewers')){
            users.add('RE'+usr);
        }
        for(String usr : Utility.getGroupUsers('Approvers')){
            users.add('AP'+usr);
        }
        return users;
    }
    //update the task action
    @auraEnabled
    public Static String upsertTaskAction(sObject act,Boolean isUpdate){
        try{
            Task_Action__c action = (Task_Action__c)act;
            if(isUpdate){
                update action;
                
                List<Notification__c> notificationsToUpdate = new List<Notification__c>();
                for(Notification__c relatedNotification : [select Id,Status__c from Notification__c where Task_Action__c =: action.Id]){
                    if(action.Status__c == 'Completed')
                    	relatedNotification.Status__c = 'Dismissed';
                    else
                        relatedNotification.Status__c = 'Open';
                    notificationsToUpdate.add(relatedNotification);
                }
                update notificationsToUpdate;
                
            }
            else
                insert action;
            return 'Successfully updated';
        }
        catch(Exception e){
            return e.getMessage();
        }
        
    }
    
    //delete the task action
    @auraEnabled
    public Static String deleteAction(String actId){
        try{
            List<Notification__c> notificationRelated = [select Id from Notification__c where Task_Action__c =: actId];
            if(notificationRelated != null && notificationRelated.size()>0){
                delete notificationRelated;
            }
            
            Task_Action__c act = new Task_Action__c(Id = actId);
            delete act;
            return 'SuccessFully Deleted';
        }
        catch(Exception e){
            return e.getMessage();
        }
    }
    
    @auraEnabled
    public static void deleteTaskAndEvent(String evtId){
        Event evt = new Event(id=evtId);
        
        //query custom metadata and get fields to dispaly
        List<Config__mdt> config = [select id,Briefing_Note_Fields__c from Config__mdt where DeveloperName='Default' LIMIT 1];
        String brief_fields = '';
        if(config != null && config.size() >0){
            brief_fields  = config[0].Briefing_Note_Fields__c;
        }
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType eventSchema = schemaMap.get('Event');
        Map<String, Schema.SObjectField> fieldMap = eventSchema.getDescribe().fields.getMap();
        if(brief_fields != ''){
            for(String fld : brief_fields.split(',')){
                String fldType = String.valueOf(fieldMap.get(fld).getDescribe().getType());
                String event_text;
                if(fldType == 'BOOLEAN'){
                    evt.put(fld,false);
                }
                else
                    evt.put(fld,'');
            }
        }
        update evt;
        
        Set<Id> taskIds = new Set<Id>();
        List<Task> tsksToDelete = new List<Task>();
        List<Task> tskToDelete = new List<Task>();
        Map<String,Activity_Relationship__c> relationToTaskMap = new Map<String,Activity_Relationship__c>();
        for(Activity_Relationship__c relation: [select id,Event_ID__c,Task_ID__c from Activity_Relationship__c where Event_ID__c =: evtId]){
            taskIds.add(relation.Task_ID__c);
            relationToTaskMap.put(relation.Task_ID__c,relation);
        }
        
        if(taskIds != null && taskIds.size()>0){
            for(Task tsk : [select id,recordType.Name from Task where ID IN : taskIds]){
                if(tsk.RecordType.name == 'Briefing Notes Required'){
                    tsksToDelete.add(tsk);
                }
            }
        }
        
        if(tsksToDelete.size()>0){
            delete(relationToTaskMap.get(tsksToDelete[0].Id));
            delete tsksToDelete;
        }
        
    }
    
    
    /*
    * Method to add New Notifications for task or task actions
    * get a list of ids. In case of task, it will have only 1 item. In case of Task Action, there can be multiple items
    * 
    */
    @auraEnabled
    public static String addNewNotification(string taskOrActionIds,Boolean isTask){
        if(taskOrActionIds != null){
            Notification__c notification  = new Notification__c();
            notification.Enabled_By__c = UserInfo.getUserId();
            notification.Status__c = 'Open';
            if(isTask)    //if id is of task, enter task_Id__c
                notification.Task_Id__c = taskOrActionIds;
            else
                notification.Task_Action__c = taskOrActionIds;  //else enter Task_Action__c 
            
            try{
                insert notification;
                return 'SUCCESS';
            }
            catch(Exception e){
                return e.getMessage();
            }
        }
        return null;
    }
    
    /*
    * Method to Delete Notification
    * get notification id as parameter
    * Get the notification record Id and delete it
    */
    @auraEnabled
    public static String dismissOrDeleteNotifications(String taskOrActionIds){
        List<Notification__c> notifications = new List<Notification__c>();
        try{
            if(taskOrActionIds != null){
                notifications = [select id from Notification__c where Task_Id__c =: taskOrActionIds OR Task_Action__c =: taskOrActionIds];
                delete notifications;
            }
            return 'SUCCESS';
        }
        catch(Exception e){
            return e.getMessage();
        }
    }    
}