@isTest
public class UpdateAllAccountsTest {
  @isTest
  static void testBatchUpdatesPricesAndCalculatesCA() {
    // 🧪 Créer les données de base via la factory
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );

    // 🛒 Ajouter des OrderItems
    List<OrderItem> items = new List<OrderItem>();
    for (Order o : data.orders) {
      items.add(
        new OrderItem(
          OrderId = o.Id,
          Quantity = 2,
          PricebookEntryId = data.pricebookEntryId,
          UnitPrice = 80 // volontairement différent du prix standard (100)
        )
      );
    }
    insert items;

    // ✅ Activer une commande pour test du CA
    Order activatedOrder = data.orders[0];
    activatedOrder.Status = 'Activated';
    update activatedOrder;

    // ⚙️ Lancer le batch
    Test.startTest();
    UpdateAllAccounts batch = new UpdateAllAccounts();
    Database.executeBatch(batch, 50);
    Test.stopTest();

    // ✅ Vérification : CA du compte (commande activée = 2 x 100)
    Account acc = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :data.accountId
    ];
    System.assertEquals(
      200,
      acc.Chiffre_d_affaire__c,
      '💥 Le CA du compte est incorrect'
    );

    // 🧪 Vérification que les prix des OrderItems ont été mis à jour à 100
    for (OrderItem oi : [
      SELECT Id, UnitPrice
      FROM OrderItem
      WHERE OrderId IN :data.orders
    ]) {
      System.assertEquals(
        100,
        oi.UnitPrice,
        '💥 Prix de l\'OrderItem non mis à jour'
      );
    }
  }
}
