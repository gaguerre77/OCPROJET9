public class UpdateAllAccounts implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          AccountId,
          Pricebook2Id,
          (SELECT Id, UnitPrice, Quantity, PricebookEntryId FROM OrderItems)
        FROM Order
        WHERE Status = 'Activated'
      ]
    );
  }

  public void execute(Database.BatchableContext BC, List<Order> scope) {
    Map<Id, Decimal> accountTotalMap = new Map<Id, Decimal>();
    List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
    List<Order> ordersToUpdate = new List<Order>();
    Set<Id> pricebookIds = new Set<Id>();

    // Collecter les Pricebook2Id nécessaires
    for (Order order : scope) {
      pricebookIds.add(order.Pricebook2Id);
    }

    // Récupérer tous les PricebookEntry nécessaires pour les Pricebook2Id
    Map<Id, List<PricebookEntry>> pricebookEntriesMap = new Map<Id, List<PricebookEntry>>();
    for (PricebookEntry pbe : [
      SELECT Id, Pricebook2Id, Product2Id, UnitPrice
      FROM PricebookEntry
      WHERE Pricebook2Id IN :pricebookIds
    ]) {
      if (!pricebookEntriesMap.containsKey(pbe.Pricebook2Id)) {
        pricebookEntriesMap.put(pbe.Pricebook2Id, new List<PricebookEntry>());
      }
      pricebookEntriesMap.get(pbe.Pricebook2Id).add(pbe);
    }

    // Traiter chaque commande et ses OrderItems
    for (Order order : scope) {
      Decimal newTotalAmount = 0;

      // Récupérer les PricebookEntry associés à cette commande
      Map<Id, PricebookEntry> orderPricebookEntries = new Map<Id, PricebookEntry>();
      for (PricebookEntry pbe : pricebookEntriesMap.get(order.Pricebook2Id)) {
        orderPricebookEntries.put(pbe.Id, pbe);
      }

      // Mettre à jour les OrderItems et recalculer le CustomTotalAmount
      for (OrderItem item : order.OrderItems) {
        PricebookEntry pricebookEntry = orderPricebookEntries.get(
          item.PricebookEntryId
        );
        if (pricebookEntry != null) {
          Decimal newPrice = pricebookEntry.UnitPrice;
          item.UnitPrice = newPrice;
          newTotalAmount += newPrice * item.Quantity;
          orderItemsToUpdate.add(item);
        }
      }

      // Mettre à jour le champ CustomTotalAmount sur l'objet Order
      order.CustomTotalAmount__c = newTotalAmount;
      ordersToUpdate.add(order);

      // Ajouter au total pour le compte
      if (accountTotalMap.containsKey(order.AccountId)) {
        accountTotalMap.put(
          order.AccountId,
          accountTotalMap.get(order.AccountId) + newTotalAmount
        );
      } else {
        accountTotalMap.put(order.AccountId, newTotalAmount);
      }
    }

    // Mettre à jour les OrderItems et les Orders
    if (!orderItemsToUpdate.isEmpty()) {
      update orderItemsToUpdate;
    }
    if (!ordersToUpdate.isEmpty()) {
      update ordersToUpdate;
    }

    // Mettre à jour les comptes
    List<Account> accountsToUpdate = new List<Account>();
    for (Id accountId : accountTotalMap.keySet()) {
      Account acc = new Account(
        Id = accountId,
        Chiffre_d_affaire__c = accountTotalMap.get(accountId)
      );
      accountsToUpdate.add(acc);
    }

    // Mettre à jour les comptes
    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }

  public void finish(Database.BatchableContext BC) {
    // Actions à effectuer après le traitement de tous les lots
    System.debug('Batch processing complete.');
  }
}
