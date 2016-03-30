public class SettingsController {
	@auraEnabled
    public static Notification_Setting__c getNotificationSettings(){
        // check if the setting already exist
        List<Notification_Setting__c> settingsList = [select id,Managers__c,Approvers_and_their_EA_s__c,Content_providers_and_their_EA_s__c,Reviewers_and_their_EA_s__c,Writers_and_their_EA_s__c,Task_Owners__c from Notification_Setting__c where name='Default'];
        if(settingsList != null && settingsList.size()>0){
            return settingsList[0];
        }
        else{ //otherwise create and return it
            Notification_Setting__c setting = new Notification_Setting__c();
            setting.Managers__c = true;
            setting.Approvers_and_their_EA_s__c = true;
            setting.Content_providers_and_their_EA_s__c = true;
            setting.Reviewers_and_their_EA_s__c = true;
            setting.Task_Owners__c = true;
            setting.Writers_and_their_EA_s__c = true;
            setting.Name = 'Default';
            insert setting;
            return setting;
        }
    }
    
    @auraEnabled
    public static String changeNotificationSetting(Notification_Setting__c notificationSetting){
        try{
            update notificationSetting;
            return 'SUCCESS';
        }
        catch(Exception e){
            return e.getMessage();
        }
    }
}