//wrapper class to wrap task data with some attribute
// required will tell if it is selected on page or not
public class TaskWithRecordTypeNameWrapper {
    @AuraEnabled
    public String  tskDateClass{get;set;}
    
    @AuraEnabled
    public String tskrecordTypeName{get;set;}
    
    @auraEnabled
    public String tskRecordTypeId{get;set;}
    
    @auraEnabled
    public Boolean highPriority{get;set;}
    
    @auraEnabled
    public DateTime tskDtTime{get;set;}
    
    @auraEnabled
    public DateTime appDtTime{get;set;}
    
    @auraEnabled
    public String tskOwner{get;set;}
    
    @auraEnabled
    public Boolean required{get;set;}
    
    @auraEnabled
    public Task tsk{get;set;}
    
    
    public TaskWithRecordTypeNameWrapper(String tskDateClass,String tskrecordTypeName, String tskRecordTypeId,Boolean highPriority,  DateTime tskDtTime,String tskOwner,Boolean required,Task tsk){
        this.tskDateClass = tskDateClass;
        this.tskrecordTypeName = tskrecordTypeName;
        this.tskRecordTypeId = tskRecordTypeId;
        this.highPriority = highPriority;
        this.tskDtTime = tskDtTime;
        this.tskOwner = tskOwner;
        this.required = required;
        this.tsk = tsk;
    }
}