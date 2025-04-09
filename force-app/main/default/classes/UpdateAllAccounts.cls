public class UpdateAllAccounts implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext BC) {
    System.debug('🚀 Démarrage du batch UpdateAllAccounts');
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          AccountId,
          Pricebook2Id,
          Status, // Include the Status field here
          (SELECT Id, UnitPrice, Quantity, PricebookEntryId FROM OrderItems)
        FROM Order
        WHERE Status IN ('Activated', 'Draft')
      ]
    );
  }

  public void execute(Database.BatchableContext BC, List<Order> scope) {
    System.debug('📦 Traitement d\'un lot de ' + scope.size() + ' commandes');

    Map<Id, Decimal> accountTotalMap = new Map<Id, Decimal>();
    List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
    Set<Id> pricebookIds = new Set<Id>();

    // Collecter les Pricebook2Id nécessaires
    for (Order order : scope) {
      pricebookIds.add(order.Pricebook2Id);
    }
    System.debug('🔎 Pricebook2 à charger : ' + pricebookIds);

    // Récupérer tous les PricebookEntry nécessaires
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
    System.debug('📘 PricebookEntry chargés : ' + pricebookEntriesMap.size());

    for (Order order : scope) {
      Decimal newTotalAmount = 0;

      System.debug('🧾 Traitement de la commande ' + order.Id);

      Map<Id, PricebookEntry> orderPricebookEntries = new Map<Id, PricebookEntry>();
      if (pricebookEntriesMap.containsKey(order.Pricebook2Id)) {
        for (PricebookEntry pbe : pricebookEntriesMap.get(order.Pricebook2Id)) {
          orderPricebookEntries.put(pbe.Id, pbe);
        }
      }

      for (OrderItem item : order.OrderItems) {
        PricebookEntry pricebookEntry = orderPricebookEntries.get(
          item.PricebookEntryId
        );
        if (pricebookEntry != null) {
          Decimal newPrice = pricebookEntry.UnitPrice;
          Decimal lineTotal = newPrice * item.Quantity;
          item.UnitPrice = newPrice;
          newTotalAmount += lineTotal;
          orderItemsToUpdate.add(item);

          System.debug(
            '  🛒 OrderItem ' +
              item.Id +
              ' : ' +
              item.Quantity +
              ' x ' +
              newPrice +
              ' = ' +
              lineTotal
          );
        } else {
          System.debug(
            '  ⚠️ PricebookEntry non trouvé pour OrderItem ' + item.Id
          );
        }
      }

      // Calculer le chiffre d'affaires uniquement pour les commandes 'Activated'
      if (order.Status == 'Activated') {
        System.debug(
          '✅ Total recalculé pour Order ' + order.Id + ' : ' + newTotalAmount
        );

        if (accountTotalMap.containsKey(order.AccountId)) {
          accountTotalMap.put(
            order.AccountId,
            accountTotalMap.get(order.AccountId) + newTotalAmount
          );
        } else {
          accountTotalMap.put(order.AccountId, newTotalAmount);
        }
      }
    }

    System.debug(
      '💾 OrderItems à mettre à jour : ' + orderItemsToUpdate.size()
    );

    if (!orderItemsToUpdate.isEmpty()) {
      update orderItemsToUpdate;
    }

    List<Account> accountsToUpdate = new List<Account>();
    for (Id accountId : accountTotalMap.keySet()) {
      Decimal totalCA = accountTotalMap.get(accountId);
      accountsToUpdate.add(
        new Account(Id = accountId, Chiffre_d_affaire__c = totalCA)
      );
      System.debug('📈 Compte ' + accountId + ' → nouveau CA : ' + totalCA);
    }

    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
      System.debug(
        '✅ Mise à jour de ' + accountsToUpdate.size() + ' comptes terminée.'
      );
    }
  }

  public void finish(Database.BatchableContext BC) {
    System.debug('🎉 Batch UpdateAllAccounts terminé avec succès.');
  }
}
