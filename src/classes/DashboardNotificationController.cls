public class DashboardNotificationController {
    @auraEnabled
    public static ResultWrapper getNotifications(Boolean showTodays){
        
        //return the list of Notification Wrapper
        List<NotificationWrapper> notifications = new List<NotificationWrapper>();
        //if notification is for Task,add to this list
        Set<String> taskIds = new Set<String>();
        Map<String,Notification__c> taskNotificationIdMap = new Map<String,Notification__c>();
        
        Id managerId = [select id,ManagerId from User where ID =: UserInfo.getUserId()].ManagerId;
        
        Set<String> currentUserGroups = Utility.getGroupsForUser(UserInfo.getUserId());
        Set<String> currentUsersManagerGroups;
        if(managerId != null)
        	currentUsersManagerGroups = Utility.getGroupsForUser(ManagerId); 
        else
            currentUsersManagerGroups = new Set<String>();
        
        //determine from which group user belongs
        Boolean isCommunicationManager = currentUserGroups.contains('Communication Manager');
        Boolean isTaskOwner = currentUserGroups.contains('Task owners'); 
        Boolean isContentProvider = currentUserGroups.contains('Content providers') || currentUsersManagerGroups.contains('Content providers');  
        Boolean isApprover = currentUserGroups.contains('Approvers') || currentUsersManagerGroups.contains('Approvers'); 
        Boolean isReviewer = currentUserGroups.contains('Reviewers') || currentUsersManagerGroups.contains('Reviewers');
        Boolean isWriter = currentUserGroups.contains('Writers') || currentUsersManagerGroups.contains('Writers');
        
        //find out notifications are visible to current user or not 
        Boolean isVisibleToTaskOwners = true;
        Boolean isVisibleToContentProvider = true;
        Boolean isVisibleToApprover = true;
        Boolean isVisibleToReviewer = true;
        Boolean isVisibleToWriter = true;
        
        //From the custom setting, get the default settings for Notifications
        Notification_Setting__c setting = Notification_Setting__c.getValues('Default');
        
        if(setting != null){
            isVisibleToTaskOwners = setting.Task_Owners__c;
            isVisibleToContentProvider = setting.Content_providers_and_their_EA_s__c;
            isVisibleToApprover = setting.Approvers_and_their_EA_s__c;
            isVisibleToReviewer = setting.Reviewers_and_their_EA_s__c;
            isVisibleToWriter = setting.Writers_and_their_EA_s__c;
        }
        
        //create list and add user and manager id to that
        List<Id> userIdsOfOwnerAndManager = new List<Id>();
        userIdsOfOwnerAndManager.add(UserInfo.getUserId());
        if(managerId != null)
            userIdsOfOwnerAndManager.add(managerId);
        
        for(Notification__c notification : [select id,Name,Task_Id__c,Enabled_By__c,Status__c,Task_Action__c,Task_Action__r.Type__c,Task_Action__r.Date_Required__c,Task_Action__r.Task_ID__c,Task_Action__r.Status__c,Task_Action__r.Assignee__r.Name,Task_Action__r.Assignee__c from Notification__c]){ 
            //if task action is not null for notification, add this to notifications
            if (notification.Task_Action__c != null ){
                //showTodays true means Header notification is calling this method. So show only those tasks which are registered for notificaiton
                //and also have date required as today
                if(((showTodays && notification.Task_Action__r.Date_Required__c.Date() == System.today() && notification.Status__c == 'open') || (!showTodays && notification.Task_Action__r.Status__c != 'Completed')) && (Notification.Task_Action__r.Assignee__c == UserInfo.getUserId() || (managerId != null && Notification.Task_Action__r.Assignee__c == managerId))){
                    if((notification.Task_Action__r.Type__c == 'Content Providers' && isContentProvider && isVisibleToContentProvider) || (notification.Task_Action__r.Type__c == 'Writers' && isWriter && isVisibleToWriter) || (notification.Task_Action__r.Type__c == 'Reviewers' && isReviewer && isVisibleToReviewer) || (notification.Task_Action__r.Type__c == 'Approvers' && isApprover && isVisibleToApprover) || isCommunicationManager)
                    	notifications.add(new NotificationWrapper(notification.Task_Action__r.Task_Id__c,notification.Id,notification.Task_Action__r.Type__c,getHoursDetail(notification.Task_Action__r.Date_Required__c),notification.Task_Action__r.Assignee__r.Name,notification.Task_Action__r.Status__c));
                }
            }
            else if(notification.Task_Id__c != null && notification.Task_Id__c != '') {  //else add the task id to list for query tasks
                taskNotificationIdMap.put(notification.Task_Id__c,notification);
                taskIds.add(notification.Task_Id__c);
            }
            
        }
        
        //if TaskIds list is not empty, query the tasks and add to notifications
        if(taskIds != null && taskIds.size()>0){
            for(Task tsk : [select id,Subject,Date_Required__c,Owner.Name,Status,Assigned_To__c from task where ID IN : taskIds AND (OwnerId IN : userIdsOfOwnerAndManager OR Assigned_To__c IN : userIdsOfOwnerAndManager)]){
                if(((showTodays && tsk.Date_Required__c.Date() == System.today() && taskNotificationIdMap.get(tsk.Id).Status__c == 'open' ) || (!showTodays && tsk.Status != 'Completed')) && ((isTaskOwner && isVisibleToTaskOwners) || isCommunicationManager))
                    notifications.add(new NotificationWrapper(tsk.Id,taskNotificationIdMap.get(tsk.Id).Id,tsk.Subject,getHoursDetail(tsk.Date_Required__c),tsk.Owner.Name,tsk.Status));
            }
        } 
        
        
        ResultWrapper results = new ResultWrapper(notifications,isCommunicationManager);
        return results;
    }
    
    //function to get how many hours are left or due
    public static String getHoursDetail(DateTime dateRequired){
        String dateString ; 
        if(dateRequired != null){
            Decimal dateDiff;
            //if date is less than current time, its due
            if(dateRequired > System.now()){
               return 'Due in '+calculateDateDiff(System.now(),dateRequired);
            }
            //else its overdue
            else{
                return 'Overdue By '+calculateDateDiff(dateRequired,System.now());
            }
        }
        return dateString;
    }
    
    public static String calculateDateDiff(DateTime startDate,DateTime endDate){
        String dateDiff = '';
        decimal noOfDays;
        decimal noOfHours;
        decimal noOfMinutes = ((endDate.getTime())/1000/60) - ((startDate.getTime())/1000/60); 
        if(noOfMinutes > 60) {
            noOfHours = noOfMinutes/60;
            noOfMinutes = Math.mod(Integer.ValueOf(noOfMinutes), 60);
        }
        if(noOfHours > 24) {
            noOfDays = noOfHours/24;
            noOfHours = Math.mod(Integer.ValueOf(noOfHours), 24);
        }
        
        if(noOfDays != null && noOfDays >= 0 ){
            Integer intNoOfDays = Integer.valueOf(noOfDays);
            dateDiff += intNoOfDays;
            dateDiff += intNoOfDays > 1 ? ' Days ' : ' Day ';
        }
        if(noOfHours != null && noOfHours >= 0){
            Integer intNoOfHours = Integer.valueOf(noOfHours);
            dateDiff += intNoOfHours;
            dateDiff += intNoOfHours > 1 ? ' Hours ' : ' Hour ';
        }
        if(noOfMinutes != null && noOfMinutes >= 0){
            Integer intNoOfMinutes = Integer.valueOf(noOfMinutes);
            dateDiff += intNoOfMinutes;
            dateDiff += intNoOfMinutes > 1 ? ' Minutes ' : ' Minute ';
        }
        return dateDiff;
    }
    /*
    * Method to dismiss Notification
    * get notification id as parameter
    * Get the notification record and set status as Dismissed
    */
    @auraEnabled
    public static String dismissOrDeleteNotifications(String notificationId){
        try{
            Notification__c notification = new Notification__c(Id = notificationId);
            notification.Status__c = 'Dismissed';
            update notification;
            return 'SUCCESS';
        }
        catch(Exception e){
            return e.getMessage();
        }
    }
    
    
    //wrapper class to wrap the Notification Details
    public class NotificationWrapper{
        @auraEnabled
        public String taskId{get;set;}
        @auraEnabled
        public String notificationId{get;set;}
        @auraEnabled
        public String notificationtext{get;set;}
        @auraEnabled
        public String notificationtime{get;set;}
        @auraEnabled
        public String notificationtaskowner{get;set;}
        @auraEnabled
        public String notificationstatus{get;set;}
        
        public NotificationWrapper(String taskId,String notificationId,String notificationtext,String notificationtime,String notificationtaskowner,String notificationstatus){
            this.taskId = taskId;
            this.notificationId = notificationId;
            this.notificationtext = notificationtext;
            this.notificationtime = notificationtime;
            this.notificationtaskowner = notificationtaskowner;
            this.notificationstatus = notificationstatus;
        }
    }
    
    //wrapper class to wrap the final results from notifications and group users
    public class ResultWrapper{
        @auraEnabled 
        public List<NotificationWrapper> notifications{get;set;}
        @auraEnabled
        public Boolean isCommunicationManager{get;set;}
        
        public resultWrapper(List<NotificationWrapper> notifications,Boolean isCommunicationManager){
            this.notifications = notifications;
            this.isCommunicationManager = isCommunicationManager;
        }
    }
}