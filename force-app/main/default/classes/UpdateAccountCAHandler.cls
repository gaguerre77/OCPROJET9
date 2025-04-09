public class UpdateAccountCAHandler {
  public static void handleAfterUpdate(
    List<Order> newOrders,
    Map<Id, Order> oldOrdersMap
  ) {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> orderIds = new Set<Id>();

    // Identifier les comptes concernés par un changement Draft → Activated
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

    // Récupérer les commandes activées des comptes concernés
    List<Order> activatedOrders = [
      SELECT Id, AccountId
      FROM Order
      WHERE Status = 'Activated' AND AccountId IN :accountIds
    ];

    for (Order o : activatedOrders) {
      orderIds.add(o.Id);
    }

    if (orderIds.isEmpty())
      return;

    // Récupérer tous les OrderItems liés aux commandes activées
    List<OrderItem> items = [
      SELECT Id, Order.AccountId, Quantity, UnitPrice
      FROM OrderItem
      WHERE OrderId IN :orderIds
    ];

    // Calculer les totaux par compte
    Map<Id, Decimal> accountTotals = new Map<Id, Decimal>();
    for (OrderItem item : items) {
      Id accId = item.Order.AccountId;
      Decimal total = item.UnitPrice * item.Quantity;

      if (!accountTotals.containsKey(accId)) {
        accountTotals.put(accId, total);
      } else {
        accountTotals.put(accId, accountTotals.get(accId) + total);
      }
    }

    // Mettre à jour les comptes
    List<Account> accountsToUpdate = new List<Account>();
    for (Id accId : accountTotals.keySet()) {
      accountsToUpdate.add(
        new Account(Id = accId, Chiffre_d_affaire__c = accountTotals.get(accId))
      );
    }

    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }
}
