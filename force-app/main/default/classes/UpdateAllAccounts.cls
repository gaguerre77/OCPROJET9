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

    // Mettre à jour les OrderItem et recalculer le CustomTotalAmount
    for (Order order : scope) {
      Decimal newTotalAmount = 0;

      // Récupérer les nouveaux prix des produits pour le catalogue actif de la commande
      Map<Id, PricebookEntry> pricebookEntriesMap = new Map<Id, PricebookEntry>(
        [
          SELECT Id, UnitPrice, Product2Id
          FROM PricebookEntry
          WHERE Pricebook2Id = :order.Pricebook2Id
        ]
      );

      for (OrderItem item : order.OrderItems) {
        System.debug(
          'Processing OrderItem ID: ' +
            item.Id +
            ' with PricebookEntryId: ' +
            item.PricebookEntryId
        );
        PricebookEntry pricebookEntry = pricebookEntriesMap.get(
          item.PricebookEntryId
        );
        if (pricebookEntry != null) {
          Decimal newPrice = pricebookEntry.UnitPrice;
          System.debug(
            'Updating OrderItem ID: ' + item.Id + ' with new price: ' + newPrice
          );
          item.UnitPrice = newPrice;
          newTotalAmount += newPrice * item.Quantity;
          orderItemsToUpdate.add(item);
        } else {
          System.debug('PricebookEntry not found for OrderItem ID: ' + item.Id);
        }
      }

      // Mettre à jour le champ personnalisé sur l'objet Order
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

    // Mettre à jour les OrderItem et les Order
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

    update accountsToUpdate;
  }

  public void finish(Database.BatchableContext BC) {
    // Actions à effectuer après le traitement de tous les lots
    System.debug('Batch processing complete.');
  }
}
