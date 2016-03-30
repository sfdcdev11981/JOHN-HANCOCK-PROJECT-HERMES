@isTest
public class TestSearchBarCompController {
    public static testMethod void searchBarCompControllerTest(){
        //create task
        Task tsk = Test_Data.createTask();
        tsk.Date_Required__c = System.now();
        tsk.Subject = '';
        tsk.Description = 'Test';
        insert tsk;
        System.assert(tsk.Id != null);
        
        Task tsk2 = Test_Data.createTask();
        tsk2.Date_Required__c = System.now();
        tsk2.Subject = 'Test';
        tsk2.Description = '';
        insert tsk2;
        System.assert(tsk2.Id != null);
        
        Event evt = Test_Data.createEvent();
        evt.Subject = 'Test Event1';
        evt.Trip_Location__c = 'Test';
        //evt.StartDateTime = System.Now();
        evt.type='Email';
        insert evt;
        System.assert(evt.Id != null);
        
        SearchBarCompController.getSuggestions('Test');
        SearchBarCompController.getSuggestions('Email');
        SearchBarCompController.getSearchResults('Test');
        
    }
}