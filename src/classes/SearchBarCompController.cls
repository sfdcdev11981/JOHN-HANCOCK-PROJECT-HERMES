public class SearchBarCompController {
    
    //get the keyword, search it in task and event, get the results , make the Set and return it for suggestion in header search bar
    @auraEnabled
    public static List<String> getSuggestions(String searchTerm){
        Set<String> suggestions = new Set<String>();
        //loop through all the events , if its subject, type or date matches search string, add it to results
        for(Event evt : [select id,Subject,StartDateTime,type,Trip_Location__c from Event ]){
            if(evt.Subject !=null && evt.Subject.containsIgnoreCase(searchTerm))
                suggestions.add(evt.Subject);
            if(evt.type != null && evt.type.containsIgnoreCase(searchTerm))
                suggestions.add(evt.type);
            if(evt.Trip_Location__c != null && evt.Trip_Location__c.containsIgnoreCase(searchTerm))
                suggestions.add(evt.Trip_Location__c);
            if(evt.StartDateTime != null && String.valueOf(evt.StartDateTime).containsIgnoreCase(searchTerm))
                suggestions.add(String.valueOf(evt.StartDateTime.Date()));
        }
        //loop through all the tasks , if its record type name or date matches search string, add it to results
        for(Task tsk : [select id,RecordType.Name,Date_Required__c from Task ]){
            if(tsk.RecordType.Name.containsIgnoreCase(searchTerm))
                suggestions.add(tsk.RecordType.Name);
            if(tsk.Date_Required__c != null && String.valueOf(tsk.Date_Required__c).containsIgnoreCase(searchTerm))
                suggestions.add(String.valueOf(tsk.Date_Required__c.Date()));
        }
        //return result
        return new List<String>(suggestions);
    }
    //get the keyword to to seach, query , make the wrapper date from result and return it
    @auraEnabled
    public static SearchResultWithDetailsWrapper getSearchResults(String searchKeyword){
        List<searchResultsWrapper> results = new List<searchResultsWrapper>();
        //query all the tasks with matching string,
        //add to results
        // Not using SOSL here for perfect result and also cant filter SOSL on dates
        //all the fields common in task and events
        String taskEventCommonFields = 'Subject,AddToFeed__c,Additional_Information__c,Agenda__c,Approval_Date__c,Assigned_To__c,Audience__c,Briefing_Date__c,City__c,ContactEmail__c,ContactName__c';
        taskEventCommonFields += ','+'ContactPhone__c,ContactTitle__c,Deliverable__c,Dress_Code__c,Event_Background__c,Introduced_by__c,Languages__c,Priority__c,RelatedLink__c,Review_Date__c';
        taskEventCommonFields += ','+ 'Room_Setup__c,Suggested_Topic__c,Table_Seating__c,Time_of_Remarks__c,Trip_Date__c,Trip_Location__c,Venue__c,When_do_you_speak__c,Date_Required__c';
        
        //events fields to compare
        String eventFields = 'type,Location,EndDateTime,StartDateTime,Description';
        String eventQueryString = 'select id,'+taskEventCommonFields+','+eventFields+' from Event LIMIT 20';
        Set<String> evtsAddedIds = new Set<String>();
        
        Integer recordLimit = Label.Total_No_Of_Records_To_Display != null && Label.Total_No_Of_Records_To_Display !='' ? Integer.valueOf(Label.Total_No_Of_Records_To_Display): 100;
        //query all the events and compare fields with search string
        //if matches, add the event to List of results
        //evtsAddedIds to make sure no event is added 2 times
        for(Event evt : Database.query(eventQueryString)){
            for(String commonField : taskEventCommonFields.split(',')){
                if(!evtsAddedIds.contains(evt.Id) && evtsAddedIds.size()<recordLimit && evt.get(commonField) != null && String.valueOf(evt.get(commonField)).containsIgnoreCase(searchKeyword)){
                    evtsAddedIds.add(evt.Id);
                    results.add(new searchResultsWrapper(evt.Subject,evt.StartDateTime,false,evt.Type,evt.Id));
                }
                
            }
            for(String evtField : eventFields.split(',')){
                if(!evtsAddedIds.contains(evt.Id) && evt.get(evtField) != null && String.valueOf(evt.get(evtField)).containsIgnoreCase(searchKeyword)){
                    evtsAddedIds.add(evt.Id);
                    results.add(new searchResultsWrapper(evt.Subject,evt.StartDateTime,false,evt.Type,evt.Id));
                }
                
            }
        }
        
        //query all the tasks and compare fields with search string
        //if matches, add the task to List of results
        //tskAddedIds to make sure no task is added 2 times
        String taskFields = 'ActivityDate,Status,Priority,Description';
        String taskQueryString = 'select id,RecordType.Name,'+taskEventCommonFields+','+taskFields+' from Task';
        Set<String> tskAddedIds = new Set<String>();
        for(Task tsk : Database.query(taskQueryString)){
            for(String commonField : taskEventCommonFields.split(',')){
                if(!tskAddedIds.contains(tsk.Id) && tsk.get(commonField) != null && tskAddedIds.size()<recordLimit && String.valueOf(tsk.get(commonField)).containsIgnoreCase(searchKeyword)){
                    tskAddedIds.add(tsk.Id);
                    results.add(new searchResultsWrapper(tsk.RecordType.Name,tsk.date_Required__c,true,tsk.RecordType.Name,tsk.Id));
                }
                
            }
            for(String tskField : taskFields.split(',')){
                if(!tskAddedIds.contains(tsk.Id) && tsk.get(tskField) != null && String.valueOf(tsk.get(tskField)).containsIgnoreCase(searchKeyword)){
                    tskAddedIds.add(tsk.Id);
                    results.add(new searchResultsWrapper(tsk.RecordType.Name,tsk.date_Required__c,true,tsk.RecordType.Name,tsk.Id));
                }
                
            }
            //compare with task record type also
            if(!tskAddedIds.contains(tsk.Id) && tsk.RecordType.Name.containsIgnoreCase(searchKeyword))
                results.add(new searchResultsWrapper(tsk.RecordType.Name,tsk.date_Required__c,true,tsk.RecordType.Name,tsk.Id));
        }
        
        //get pagination size and label to display on search result page from custom label. 
        //if custom label is blank, set pagination size to 5
        String pageLabel = Label.Component_label != null && Label.Component_label != '' ? Label.Component_label : 'Search Results';
        String paginationSize = Label.Pagination_Size != null && Label.Pagination_Size != '' ? Label.Pagination_Size : '5';
        SearchResultWithDetailsWrapper resultsWithDetails = new SearchResultWithDetailsWrapper(results,pageLabel,paginationSize); 
        System.debug(resultsWithDetails);
        return resultsWithDetails;
    }
    
    //wrapper class to hold task and event fields
    public class SearchResultsWrapper{
        @auraEnabled 
        public String taskOrEventName{get;set;}
        @auraEnabled
        public DateTime taskOrEventDate{get;set;}
        @auraEnabled
        public String taskOrEventType{get;set;}
        @auraEnabled
        public boolean isTask{get;set;}
        @auraEnabled
        public String taskOrEventId{get;set;}
        
        
        public SearchResultsWrapper(String taskOrEventName,DateTime taskOrEventDate,Boolean isTask,String taskOrEventType, Id taskOrEventId){
            this.taskOrEventName = taskOrEventName;
            this.taskOrEventDate = taskOrEventDate;
            this.taskOrEventType = taskOrEventType;
            this.taskOrEventId = taskOrEventId;
            this.isTask = isTask;
        }        
    }
    
    //wrapper class to add some more details to task and events
    //like pagination size and search result page label 
    public class SearchResultWithDetailsWrapper{
        @auraEnabled 
        public List<searchResultsWrapper> resultWrapper{get;set;}
        @auraEnabled 
        public String compLabel{get;set;}
        @auraEnabled 
        public String pageSize{get;set;}
        
        public SearchResultWithDetailsWrapper(List<searchResultsWrapper> resultWrapper,String compLabel,String pageSize){
            this.resultWrapper = resultWrapper;
            this.compLabel = compLabel;
            this.pageSize = pageSize;
        }
    }
}