@isTest
public class OrderControllerTest {
  @isTest
  static void testGetSumOrdersOfAccount_WithActivatedOrders() {
    // Préparation des données
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );

    // Ajout d'OrderItems aux commandes créées
    List<OrderItem> items = new List<OrderItem>();
    for (Order ord : data.orders) {
      items.add(
        new OrderItem(
          OrderId = ord.Id,
          PricebookEntryId = data.pricebookEntryId,
          Quantity = 2,
          UnitPrice = 100
        )
      );
    }
    insert items;

    // Activation de la première commande
    Order toActivate = data.orders[0];
    toActivate.Status = 'Activated';
    update toActivate;

    Test.startTest();
    Decimal total = OrderController.getSumOrdersOfAccount(data.accountId);
    Test.stopTest();

    System.debug('📊 Total retourné : ' + total);
    System.assertEquals(
      200,
      total,
      'Le total devrait être égal à 200 pour une commande activée de 2 x 100.'
    );
  }

  @isTest
  static void testGetSumOrdersOfAccount_InvalidId() {
    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      OrderController.getSumOrdersOfAccount(null);
    } catch (Exception e) {
      exceptionThrown = true;
      System.debug('✅ Exception capturée : ' + e.getMessage());
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Une exception aurait dû être levée avec un ID null.'
    );
  }

  @isTest
  static void testGetSumOrdersOfAccount_EmptyResult() {
    // Création d'un compte sans commande activée
    Account acc = new Account(Name = 'Account without orders');
    insert acc;

    Test.startTest();
    Decimal total = OrderController.getSumOrdersOfAccount(acc.Id);
    Test.stopTest();

    System.assertEquals(
      0,
      total,
      'Le total doit être 0 si aucune commande activée n’est liée au compte.'
    );
  }
}
