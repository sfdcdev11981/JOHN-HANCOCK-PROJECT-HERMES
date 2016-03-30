public class Utility {
    //get the Public group name as paramter and return all the users associate with that.
    @auraEnabled
    public static List<String> getGroupUsers(String groupName){
        List<String> users = new List<String>();
        List<Group> grps = [select id,name from Group where name=: groupName];
        if(grps != null && grps.size()>0){
            Id grpId = grps[0].Id;
            if(grpId != null ){
                List<String> usersIds =  GetUSerFromGroup(grpId);
                for(User usr : [select id,Name from User where Id IN : usersIds]){
                    users.add(usr.Name+'-'+usr.Id);
                }
            }
        }
        return users;
    }
    
    @auraEnabled
    public static List<String> GetUSerFromGroup(Id grpId){
        // store the results in a set so we don't get duplicates
        Set<String> result=new Set<String>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        
        // Loop through all group members in a group
        for (GroupMember m : [Select Id, UserOrGroupId From GroupMember Where GroupId =: grpId])
        {
            // If the user or group id is a user
            if (((String)m.UserOrGroupId).startsWith(userType))
            {
                result.add(m.UserOrGroupId);
            }
            // If the user or group id is a group
            else if (((String)m.UserOrGroupId).startsWith(groupType))
            {
                // Call this function again but pass in the group found within this group
                result.addAll(GetUSerFromGroup(m.UserOrGroupId));
            }
            
        }
        return new List<String>(result);
    }
    
    
    //return if logged in user is CEO or not
    @auraEnabled
    public static Boolean isCEO(){
        Boolean isCEO = false;
        String userRole = [select id,userRole.name from User where id=:UserInfo.getUserId()].userRole.Name;
        isCEO = userRole == 'CEO' ? true : false;
        return isCEO;
    }
   
    // return list of all groups the user belongs to via direct or indirect membership
    public static Set<String> getGroupsForUser(Id userId){
        Set<String> groupNames = new Set<String>();
        Set<Id> groupIds = getGroupsForIds(new Set<Id>{userId});
        for(Group groupDetail : [select Id , Name from Group where Id IN: groupIds]){
            groupNames.add(groupDetail.Name);
        }
        return groupNames;
    }
    
    // return all ids the user belongs to via direct or indirect membership
    public static Set<Id> getGroupsForIds(Set<Id> userOrGroupIds){
        
        Set<Id> output = new Set<Id>();
        
        Set<Id> nestedGroupIds = new Set<Id>();
        
        // only query actual groups and not roles and queues
        list<GroupMember> records = [
            select id
            , GroupId
            , UserOrGroupId
            from GroupMember
            where UserOrGroupId =: userOrGroupIds
            and UserOrGroupId != null
            and Group.Type = 'Regular'];
        
        for (GroupMember record:records){
            // found a group, remember for traversal
            if (!(record.UserOrGroupId + '').startsWith('005')){
                nestedGroupIds.add(record.UserOrGroupId);   
            }
            else{
                output.add(record.GroupId);
            }
        }
        
        // call self to get nested groups we found
        if (nestedGroupIds.size() > 0){
            output.addAll(getGroupsForIds(nestedGroupIds));
        }
        
        return output;
    }
}