trigger UpdateAccountCA on Order(after update) {
  set<Id> setAccountIds = new Set<Id>();

  for (integer i = 0; i < Trigger.new.size(); i++) {
    Order newOrder = Trigger.new[i];

    Account acc = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :newOrder.AccountId
    ];
    acc.Chiffre_d_affaire__c = acc.Chiffre_d_affaire__c + newOrder.TotalAmount;
    update acc;
  }
}
