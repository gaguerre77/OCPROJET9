public class UpdateAccountCAHandler {
  public static void handleAfterUpdate(
    List<Order> newOrders,
    Map<Id, Order> oldOrdersMap
  ) {
    Set<Id> accountIds = new Set<Id>();

    for (Order newOrder : newOrders) {
      Order oldOrder = oldOrdersMap.get(newOrder.Id);
      if (
        oldOrder != null &&
        oldOrder.Status == 'Draft' &&
        newOrder.Status == 'Activated' &&
        newOrder.AccountId != null
      ) {
        accountIds.add(newOrder.AccountId);
      }
    }

    if (accountIds.isEmpty())
      return;

    // Agrégation directe du TotalAmount des commandes activées
    List<AggregateResult> results = [
      SELECT AccountId, SUM(TotalAmount) total
      FROM Order
      WHERE Status = 'Activated' AND AccountId IN :accountIds
      GROUP BY AccountId
    ];

    Map<Id, Decimal> accountTotals = new Map<Id, Decimal>();
    for (AggregateResult ar : results) {
      Id accId = (Id) ar.get('AccountId');
      Decimal total = (Decimal) ar.get('total');
      accountTotals.put(accId, total != null ? total : 0);
    }

    // Mise à jour des comptes
    List<Account> updates = new List<Account>();
    for (Id accId : accountTotals.keySet()) {
      updates.add(
        new Account(Id = accId, Chiffre_d_affaire__c = accountTotals.get(accId))
      );
    }

    if (!updates.isEmpty()) {
      update updates;
    }
  }
}
