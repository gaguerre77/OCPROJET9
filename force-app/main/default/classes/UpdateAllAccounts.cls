public class UpdateAllAccounts implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          AccountId,
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

    // Récupérer les nouveaux prix des produits
    Map<Id, PricebookEntry> pricebookEntriesMap = new Map<Id, PricebookEntry>(
      [
        SELECT Id, UnitPrice, Product2Id
        FROM PricebookEntry
        WHERE
          Pricebook2Id = :[
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = TRUE
            LIMIT 1
          ]
          .Id
      ]
    );

    // Log des PricebookEntry récupérés
    System.debug('PricebookEntries retrieved: ' + pricebookEntriesMap.keySet());

    // Mettre à jour les OrderItems et recalculer le CustomTotalAmount
    for (Order order : scope) {
      Decimal newTotalAmount = 0;
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

      // Mettre à jour le champ CustomTotalAmount de l'Order
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

    // Mettre à jour les OrderItems
    if (!orderItemsToUpdate.isEmpty()) {
      update orderItemsToUpdate;
    }

    // Mettre à jour les orders
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
    System.debug('Batch processing complete.');
  }
}
