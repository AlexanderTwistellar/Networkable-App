public with sharing class CommunityNetworkTriggerHandler extends TriggerHandler {

    List<Community_Network__c> triggerRecordsList = (List<Community_Network__c>) Trigger.new;

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

    public override void beforeInsert() {
        populateRecordFields();
    }

    public override void beforeUpdate() {
        populateRecordFields();
    }

}
