trigger CommunityNetworkTrigger on Community_Network__c (before insert, before update, after delete, after insert, after update) {
    new CommunityNetworkTriggerHandler().run();
}