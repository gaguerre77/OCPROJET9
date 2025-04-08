public class UpdateAccountCAHandler {
  public static void handleAfterUpdate(
    List<Order> newOrders,
    Map<Id, Order> oldOrdersMap
  ) {
    Set<Id> accountIds = new Set<Id>();

    // Identifier les comptes dont le statut de commande est passé de Draft à Activated
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

    if (accountIds.isEmpty()) {
      return;
    }

    // Récupérer les comptes à mettre à jour
    Map<Id, Account> accountsMap = new Map<Id, Account>(
      [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds]
    );

    // Agréger les montants des commandes activées par compte
    List<AggregateResult> aggregatedOrders = [
      SELECT AccountId, SUM(CustomTotalAmount__c) total
      FROM Order
      WHERE AccountId IN :accountIds AND Status = 'Activated'
      GROUP BY AccountId
    ];

    for (AggregateResult ar : aggregatedOrders) {
      Id accId = (Id) ar.get('AccountId');
      Decimal total = (Decimal) ar.get('total');

      if (accountsMap.containsKey(accId)) {
        accountsMap.get(accId).Chiffre_d_affaire__c = total;
      }
    }

    update accountsMap.values();
  }
}
