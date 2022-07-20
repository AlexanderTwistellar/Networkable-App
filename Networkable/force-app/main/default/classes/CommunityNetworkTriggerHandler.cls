public with sharing class CommunityNetworkTriggerHandler extends TriggerHandler {

    List<Community_Network__c> triggerRecordsList = (List<Community_Network__c>) Trigger.new;
    List<Community_Network__c> triggerOldRecordList = (List<Community_Network__c>) Trigger.old;

    public void populateRecordFields() {
        List<Roles_Managment__mdt> roleManagmentList = Roles_Managment__mdt.getAll().values();
        Set<Id> oppIds = new Set<Id>();
        for (Community_Network__c comNet : triggerRecordsList) {
            oppIds.add(comNet.Opportunity__c);
        }
        List<Opportunity> oppList = [SELECT Id, Name, AccountId, End_Client__c, Winning_Specifier__c FROM Opportunity WHERE Id IN :oppIds];
        if (oppList.size() > 0) {
            for (Community_Network__c comNetRec : triggerRecordsList) {
                for (Opportunity opp : oppList) {
                    if (opp.Id == comNetRec.Opportunity__c) {
                        comNetRec.End_Client__c = opp.End_Client__c;
                        comNetRec.Winning_Specifier__c = opp.Winning_Specifier__c;
                    }
                }
                for (Roles_Managment__mdt mdt : roleManagmentList) {
                    if (mdt.Role__c == comNetRec.Primary_Account_Role__c) {
                        if (comNetRec.Primary_Account_Role_Influence_Weight__c == null) {
                            comNetRec.Primary_Account_Role_Influence_Weight__c = mdt.Role_Influence_Weight__c;
                        }
                    }
                }
            }
        }
    }

    public void makeCommunityNetworkRecordIsPrimary() {
        for (Community_Network__c comNet : triggerRecordsList) {
            if (comNet.Community_Account__c == null && comNet.Community_Role__c == null) {
                comNet.isPrimary__c = true;
            }
        }
    }

    public void updatePrimaryAccountsAfterCreateRecord() {
        Set<Id> accountIds = new Set<Id>();
        for (Community_Network__c comNet : triggerRecordsList) {
            accountIds.add(comNet.Primary_Account__c);
        }
        if (accountIds.size() > 0) {
            OpportunityTriggerHandler.updateAccountRollUpFields(accountIds);
        }
    }

    public void updatePrimaryAccountsAfterUpdateRecord() {
        Set<Id> accountIds = new Set<Id>();
        for (Community_Network__c comNet : triggerRecordsList) {
            if (
                (comNet.Opportunity__c != ((Community_Network__c)Trigger.oldMap.get(comNet.Id)).Opportunity__c) ||
                (comNet.Primary_Account__c != ((Community_Network__c)Trigger.oldMap.get(comNet.Id)).Primary_Account__c)
            ) {
                accountIds.add(comNet.Primary_Account__c);
            }
        }
        if (accountIds.size() > 0) {
            OpportunityTriggerHandler.updateAccountRollUpFields(accountIds);
        }
    }

    public void updatePrimaryAccountsAfterDeleteRecord() {
        Set<Id> accountIds = new Set<Id>();
        for (Community_Network__c comNet : triggerOldRecordList) {
            accountIds.add(comNet.Primary_Account__c);
        }
        if (accountIds.size() > 0) {
            OpportunityTriggerHandler.updateAccountRollUpFields(accountIds);
        }
    }

    public override void beforeInsert() {
        populateRecordFields();
        makeCommunityNetworkRecordIsPrimary();
    }

    public override void beforeUpdate() {
        populateRecordFields();
    }

    public override void afterInsert() {
        updatePrimaryAccountsAfterCreateRecord();
    }

    public override void afterUpdate() {
        updatePrimaryAccountsAfterUpdateRecord();
    }

    public override void afterDelete() {
        updatePrimaryAccountsAfterDeleteRecord();
    }

}
