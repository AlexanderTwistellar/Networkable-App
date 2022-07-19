public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    private static final String STAGE_CLOSED_WON = 'Closed Won';
    private static final String STAGE_CLOSED_LOST = 'Closed Lost';
    private static final String STAGE_NO_BID = 'No Bid';
    private static final Integer DEFAULT_INFLUENT_WEIGHT = 0;

    List<Opportunity> triggerRecordsList = (List<Opportunity>) Trigger.new;

    public void updateRelatedONR() {
        List<Community_Network__c> recordsListToUpsert = new List<Community_Network__c>();
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity op : triggerRecordsList) {
            if ((op.StageName == STAGE_CLOSED_WON || op.StageName == STAGE_CLOSED_LOST || op.StageName == STAGE_NO_BID) &&
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_CLOSED_WON) &&
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_CLOSED_LOST) &&
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_NO_BID) ) {
                oppIds.add(op.id);
            }
        }
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Id,(SELECT Id, Primary_Account__c, Primary_Account_Role__c, Community_Account__c, Community_Role__c FROM Community_Networks__r) FROM Opportunity WHERE Id IN :oppIds]);
        for (Opportunity opp : oppMap.values()) {
            List<Community_Network__c> comNetList = new List<Community_Network__c>(opp.Community_Networks__r);
            for (Community_Network__c comNet : opp.Community_Networks__r) {
                List<Community_Network__c> commNetRecList = new List<Community_Network__c>();
                for (Community_Network__c comN : comNetList) {
                    if (comNet.Primary_Account_Role__c != comN.Primary_Account_Role__c) {
                        commNetRecList.add(comN);
                    }
                }
                for (Integer i = 0; (i < commNetRecList.size()); i++) {
                    if (i == 0) {
                        comNet.Community_Account__c = commNetRecList[0].Primary_Account__c;
                        comNet.Community_Role__c = commNetRecList[0].Primary_Account_Role__c;
                        recordsListToUpsert.add(comNet);
                    } else {
                        Community_Network__c newONR = new Community_Network__c (
                            Primary_Account__c = comNet.Primary_Account__c,
                            Primary_Account_Role__c = comNet.Primary_Account_Role__c,
                            Opportunity__c = opp.Id,
                            Community_Account__c = commNetRecList[i].Primary_Account__c,
                            Community_Role__c = commNetRecList[i].Primary_Account_Role__c,
                            Primary_Account_Role_Influence_Weight__c = DEFAULT_INFLUENT_WEIGHT
                        );
                        recordsListToUpsert.add(newONR);
                    }
                }
            }
        }
        upsert recordsListToUpsert;
    }

    public override void afterInsert() {
        updateRelatedONR();
    }

    public override void afterUpdate() {
        updateRelatedONR();
    }

}
