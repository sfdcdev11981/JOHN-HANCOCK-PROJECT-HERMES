@isTest
public class TestSettingsController {
    public static testMethod void SettingsControllerTest(){
        Test.startTest();
        Notification_Setting__c setting  = SettingsController.getNotificationSettings();
        System.assert(setting != null);
        System.assert(setting.Content_providers_and_their_EA_s__c == true);
        System.assert(setting.Approvers_and_their_EA_s__c == true);
        System.assert(setting.Managers__c == true);
        System.assert(setting.Reviewers_and_their_EA_s__c == true);
        System.assert(setting.Task_Owners__c == true);
        
        setting.Approvers_and_their_EA_s__c = false;
        setting.Content_providers_and_their_EA_s__c = false;
        setting.Managers__c = false;
        setting.Task_Owners__c = false;
        
        SettingsController.changeNotificationSetting(setting);
        setting  = SettingsController.getNotificationSettings();
        System.assert(setting != null);
        System.assert(setting.Content_providers_and_their_EA_s__c == false);
        System.assert(setting.Approvers_and_their_EA_s__c == false);
        System.assert(setting.Managers__c == false);
        System.assert(setting.Task_Owners__c == false);
        
        Test.stopTest();
    }
}