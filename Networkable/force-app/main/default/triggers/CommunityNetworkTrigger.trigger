trigger CommunityNetworkTrigger on Community_Network__c (before insert, before update) {
    new CommunityNetworkTriggerHandler().run();
}