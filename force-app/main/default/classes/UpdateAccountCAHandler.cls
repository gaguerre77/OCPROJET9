public class UpdateAccountCAHandler {
  public static void handleAfterUpdate(
    List<Order> newOrders,
    Map<Id, Order> oldOrdersMap
  ) {
    Set<Id> accountIds = new Set<Id>();

    for (Order newOrder : newOrders) {
      Order oldOrder = oldOrdersMap.get(newOrder.Id);

      if (
        oldOrder.Status == 'Draft' &&
        newOrder.Status == 'Activated' &&
        newOrder.AccountId != null
      ) {
        accountIds.add(newOrder.AccountId);
      }
    }

    if (accountIds.isEmpty()) {
      return;
    }

    Map<Id, Account> accountsMap = new Map<Id, Account>(
      [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds]
    );

    Map<Id, List<Order>> accountOrdersMap = new Map<Id, List<Order>>();
    for (Order order : [
      SELECT Id, AccountId, CustomTotalAmount__c
      FROM Order
      WHERE AccountId IN :accountIds AND Status = 'Activated'
    ]) {
      if (!accountOrdersMap.containsKey(order.AccountId)) {
        accountOrdersMap.put(order.AccountId, new List<Order>());
      }
      accountOrdersMap.get(order.AccountId).add(order);
    }

    for (Id accountId : accountOrdersMap.keySet()) {
      Account acc = accountsMap.get(accountId);
      if (acc != null) {
        Decimal sumTotalAmount = 0;
        for (Order order : accountOrdersMap.get(accountId)) {
          sumTotalAmount += order.CustomTotalAmount__c;
        }
        acc.Chiffre_d_affaire__c = sumTotalAmount;
      }
    }

    update accountsMap.values();
  }
}
