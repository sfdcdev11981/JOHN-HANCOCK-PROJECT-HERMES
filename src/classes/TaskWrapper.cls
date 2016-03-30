//wrapper class to hold the Tasks data
public class TaskWrapper {
    @auraEnabled
    public List<String> event_name{get;set;}
    @auraEnabled
    public List<String> event_id{get;set;}
    @auraEnabled
    public List<String> task_id{get;set;}
    @auraEnabled
    public String green_triangle{get;set;}
    @auraEnabled
    public List<String> deliverable{get;set;}
    @auraEnabled
    public List<String> task_owner{get;set;}
    @auraEnabled
    public List<String> due_date{get;set;}
    @auraEnabled
    public List<String> appr_date{get;set;}
    @auraEnabled
    public List<String> assigned_to{get;set;}
    @auraEnabled
    public String recTypeName{get;set;}
    
    public TaskWrapper(String recTypeName,List<String> event_name,List<String> event_id,List<String> task_id,String green_triangle,List<String> deliverable, List<String> task_owner,List<String> due_date,List<String> appr_date,List<String> assigned_to){
        this.event_name = event_name;
        this.event_id = event_id;
        this.task_id = task_id;
        this.green_triangle = green_triangle;
        this.task_owner = task_owner;
        this.deliverable = deliverable;
        this.due_date = due_date;
        this.appr_date = appr_date;
        this.assigned_to = assigned_to;
        this.recTypeName = recTypeName;
    }
}