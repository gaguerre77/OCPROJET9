public class UpdateAllAccounts implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext BC) {
    System.debug('🚀 Démarrage du batch UpdateAllAccounts');
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          AccountId,
          Pricebook2Id,
          Status, // On inclus le Status pour pouvoir trier les commandes pour le CA
          (SELECT Id, UnitPrice, Quantity, PricebookEntryId FROM OrderItems)
        FROM Order
        WHERE Status IN ('Activated', 'Draft')
        // on garde toutes les commandes pour la mise à jour des prix
      ]
    );
  }

  public void execute(Database.BatchableContext BC, List<Order> scope) {
    System.debug('📦 Traitement d\'un lot de ' + scope.size() + ' commandes');

    List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
    Set<Id> pricebookIds = new Set<Id>();

    // Collecter les Pricebook2Id nécessaires
    for (Order order : scope) {
      pricebookIds.add(order.Pricebook2Id);
    }
    System.debug('🔎 Pricebook2 à charger : ' + pricebookIds);

    // Récupérer tous les PricebookEntry nécessaires mais pas plus !
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

    // Étape 1: Mettre à jour tous les OrderItem
    for (Order order : scope) {
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
          item.UnitPrice = newPrice;
          orderItemsToUpdate.add(item);

          System.debug(
            '  🛒 OrderItem ' +
              item.Id +
              ' : ' +
              item.Quantity +
              ' x ' +
              newPrice +
              ' = ' +
              (item.Quantity * newPrice)
          );
        } else {
          System.debug(
            '  ⚠️ PricebookEntry non trouvé pour OrderItem ' + item.Id
          );
        }
      }
    }

    System.debug(
      '💾 OrderItems à mettre à jour : ' + orderItemsToUpdate.size()
    );

    if (!orderItemsToUpdate.isEmpty()) {
      update orderItemsToUpdate;
    }

    // Étape 2: Calculer le chiffre d'affaires pour les comptes sans faire de requetes pour chaque compte
    Map<Id, Decimal> accountTotalMap = new Map<Id, Decimal>();

    for (Order order : scope) {
      if (order.Status == 'Activated') {
        Decimal newTotalAmount = 0;

        for (OrderItem item : order.OrderItems) {
          newTotalAmount += item.UnitPrice * item.Quantity;
        }

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
