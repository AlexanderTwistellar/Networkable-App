public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    private static final String STAGE_CLOSED_WON = 'Closed Won';
    private static final String STAGE_CLOSED_LOST = 'Closed Lost';
    private static final String STAGE_NO_BID = 'No Bid';
    private static final Integer DEFAULT_INFLUENT_WEIGHT = 0;
    private static final Integer ZERO = 0;

    List<Opportunity> triggerRecordsList = (List<Opportunity>) Trigger.new;

    public void updateRelatedONR() {
        List<Community_Network__c> recordsListToUpsert = new List<Community_Network__c>();
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity op : triggerRecordsList) {
            if ((op.StageName == STAGE_CLOSED_WON || op.StageName == STAGE_CLOSED_LOST || op.StageName == STAGE_NO_BID) &&
            ((((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_CLOSED_WON) &&
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_CLOSED_LOST) &&
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_NO_BID))) {
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
                            Primary_Account_Role_Influence_Weight__c = DEFAULT_INFLUENT_WEIGHT,
                            isPrimary__c = false
                        );
                        recordsListToUpsert.add(newONR);
                    }
                }
            }
        }
        if(recordsListToUpsert.size() > 0) {
            upsert recordsListToUpsert;
        }
    }

    public void deleteNotPrimaryCommNetRecordsWhenOppReopen() {
        List<Community_Network__c> recordsListToDelete = new List<Community_Network__c>();
        List<Community_Network__c> comRecListToUpdate = new List<Community_Network__c>();
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity op : triggerRecordsList) {
            if ((op.StageName != STAGE_CLOSED_WON && op.StageName != STAGE_CLOSED_LOST && op.StageName != STAGE_NO_BID) &&
            ((((Opportunity)Trigger.oldMap.get(op.Id)).StageName == STAGE_CLOSED_WON) ||
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName == STAGE_CLOSED_LOST) ||
            (((Opportunity)Trigger.oldMap.get(op.Id)).StageName == STAGE_NO_BID))) {
                oppIds.add(op.id);
            }
        }
        for (Community_Network__c comm : [SELECT Id, Community_Account__c, Community_Role__c, Opportunity__c, isPrimary__c FROM Community_Network__c WHERE Opportunity__r.Id IN :oppIds]) {
            if (comm.isPrimary__c == true) {
                comm.Community_Account__c = null;
                comm.Community_Role__c = null;
                comRecListToUpdate.add(comm);
            } else {
                recordsListToDelete.add(comm);
            }
        }
        if (comRecListToUpdate.size() > 0) {
            update comRecListToUpdate;
        }
        if (recordsListToDelete.size() > 0) {
            delete recordsListToDelete;
        }
    }

    public void updateComNetPrimaryAccountFields() {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity op : triggerRecordsList) {
            if (
                (op.StageName == STAGE_CLOSED_WON && ((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_CLOSED_WON) ||
                (op.StageName == STAGE_CLOSED_LOST && ((Opportunity)Trigger.oldMap.get(op.Id)).StageName != STAGE_CLOSED_LOST) ||
                ((op.StageName != STAGE_CLOSED_WON && op.StageName != STAGE_CLOSED_LOST && op.StageName != STAGE_NO_BID) && 
                    (((Opportunity)Trigger.oldMap.get(op.Id)).StageName == STAGE_CLOSED_WON) ||
                    (((Opportunity)Trigger.oldMap.get(op.Id)).StageName == STAGE_CLOSED_LOST) ||
                    (((Opportunity)Trigger.oldMap.get(op.Id)).StageName == STAGE_NO_BID)
                ) ||
                ((op.Amount != (((Opportunity)Trigger.oldMap.get(op.Id)).Amount)) && op.StageName != STAGE_NO_BID) 
            ) {
                oppIds.add(op.Id);
            }
        }
        Set<Id> accountIds = new Set<Id>();
        for (Community_Network__c comm : [SELECT Id, Primary_Account__c, Opportunity__c FROM Community_Network__c WHERE Opportunity__r.Id IN :oppIds]) {
            accountIds.add(comm.Primary_Account__c);
        }
        if (accountIds.size() > 0) {
            updateAccountRollUpFields(accountIds);
        }
    }

    public static void updateAccountRollUpFields(Set<Id> accIds) {
        List<Account> listAccountsToUpdate = [
            SELECT 
                Id, Name, Open__c , Won__c, Lost__c, Relationships__c, Conversion__c, Open_Value__c, Lost_Value__c, Won_Value__c, 
                Relationship_Value__c, Average_Won_Value__c
            FROM Account 
            WHERE Id IN :accIds
        ];
        List<Community_Network__c> relatedComNetRecList = [
            SELECT 
                Id, Primary_Account__c, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount 
            FROM Community_Network__c
            WHERE Primary_Account__c IN :accIds
        ];
        Set<Id> allRelatedOppIds = new Set<Id>();
        for (Community_Network__c comN : relatedComNetRecList) {
            allRelatedOppIds.add(comN.Opportunity__r.Id);
        }
        List<Opportunity> relatedOppsList = [SELECT Id, StageName, Amount FROM Opportunity WHERE Id IN :allRelatedOppIds];
        
        Integer numberOpenOpps;
        Integer numberWonOpps;
        Integer numberLostOpps;
        Integer Conversion;
        Decimal amountOpenOpps;
        Decimal amountWonOpps;
        Decimal amountLostOpps;
        Decimal allOppsAmount;
        Decimal averageOppsAmount;
        Integer numberAllOpps;

        for (Account acc : listAccountsToUpdate) {
            Set<Opportunity> oppsReletedToPrimaryAcc = new Set<Opportunity>();
            acc.Open__c = ZERO;
            acc.Won__c = ZERO; 
            acc.Lost__c = ZERO; 
            acc.Relationships__c = ZERO;
            acc.Conversion__c = ZERO;
            acc.Open_Value__c = ZERO; 
            acc.Lost_Value__c = ZERO;
            acc.Won_Value__c = ZERO;
            acc.Relationship_Value__c = ZERO;
            acc.Average_Won_Value__c = ZERO;
            numberOpenOpps = ZERO;
            numberWonOpps = ZERO;
            numberLostOpps = ZERO;
            Conversion = ZERO;
            amountOpenOpps = ZERO;
            amountWonOpps = ZERO;
            amountLostOpps = ZERO;
            allOppsAmount = ZERO;
            averageOppsAmount = ZERO;
            numberAllOpps = ZERO;
            for (Community_Network__c comNet : relatedComNetRecList) {
                if (comNet.Primary_Account__c == acc.Id) {
                    for (Opportunity oppRec : relatedOppsList) {
                        if (comNet.Opportunity__c == oppRec.Id) {
                            oppsReletedToPrimaryAcc.add(oppRec);
                        }
                    }
                }
            }
            for (Opportunity oppRecord : oppsReletedToPrimaryAcc) {
                numberAllOpps++;
                if ((oppRecord.StageName != STAGE_CLOSED_WON) && (oppRecord.StageName != STAGE_CLOSED_LOST) && (oppRecord.StageName !=STAGE_NO_BID)) {
                    numberOpenOpps++;
                }
                if (oppRecord.StageName == STAGE_CLOSED_WON) {
                    numberWonOpps++;
                }
                if (oppRecord.StageName == STAGE_CLOSED_LOST) {
                    numberLostOpps++;
                }
                if (oppRecord.Amount != null && ((oppRecord.StageName != STAGE_CLOSED_WON) && (oppRecord.StageName != STAGE_CLOSED_LOST) && (oppRecord.StageName !=STAGE_NO_BID))) {
                    amountOpenOpps += oppRecord.Amount;
                }
                if (oppRecord.Amount != null && oppRecord.StageName == STAGE_CLOSED_WON) {
                    amountWonOpps += oppRecord.Amount;
                }
                if (oppRecord.Amount != null && oppRecord.StageName == STAGE_CLOSED_LOST) {
                    amountLostOpps += oppRecord.Amount;
                }
                if (oppRecord.Amount != null) {
                    allOppsAmount += oppRecord.Amount;
                }
            }
            Conversion = (numberWonOpps/(numberWonOpps + numberLostOpps))*100;
            averageOppsAmount = allOppsAmount/numberAllOpps;

            acc.Open__c = numberOpenOpps;
            acc.Won__c = numberWonOpps;
            acc.Lost__c = numberLostOpps;
            acc.Conversion__c = Conversion;
            acc.Open_Value__c = amountOpenOpps;
            acc.Lost_Value__c = amountLostOpps;
            acc.Won_Value__c = amountWonOpps;
            acc.Relationship_Value__c = allOppsAmount;
            acc.Average_Won_Value__c = averageOppsAmount;
        }
        update listAccountsToUpdate;
    }

    public override void afterUpdate() {
        updateRelatedONR();
        deleteNotPrimaryCommNetRecordsWhenOppReopen();
        updateComNetPrimaryAccountFields();
    }
}
