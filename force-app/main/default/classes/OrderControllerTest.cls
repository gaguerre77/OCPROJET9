@isTest
public class OrderControllerTest {
  @isTest
  static void testGetSumOrdersOfAccount_ok() {
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      1
    );
    Order toActivate = data.orders[0];

    insert new OrderItem(
      OrderId = toActivate.Id,
      Quantity = 1,
      UnitPrice = 100,
      PricebookEntryId = data.pricebookEntryId
    );

    toActivate.Status = 'Activated';
    update toActivate;

    Decimal total = OrderController.getSumOrdersOfAccount(data.accountId);
    System.assertEquals(
      100,
      total,
      'Le total de la commande activée devrait être correct.'
    );
  }

  @isTest
  static void testGetSumOrdersOfAccount_multipleActivatedOrders() {
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );

    List<Order> toUpdate = new List<Order>();
    for (Order o : data.orders) {
      insert new OrderItem(
        OrderId = o.Id,
        Quantity = 1,
        UnitPrice = 100,
        PricebookEntryId = data.pricebookEntryId
      );
      o.Status = 'Activated';
      toUpdate.add(o);
    }
    update toUpdate;

    Decimal total = OrderController.getSumOrdersOfAccount(data.accountId);
    System.assertEquals(
      2 * 100,
      total,
      'Le total cumulé des commandes activées devrait être correct.'
    );
  }

  @isTest
  static void testGetSumOrdersOfAccount_noActivatedOrders() {
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      1
    );

    insert new OrderItem(
      OrderId = data.orders[0].Id,
      Quantity = 1,
      UnitPrice = 100,
      PricebookEntryId = data.pricebookEntryId
    );

    Decimal total = OrderController.getSumOrdersOfAccount(data.accountId);
    System.assertEquals(0, total, 'Aucune commande activée => total = 0');
  }

  @isTest
  static void testGetSumOrdersOfAccount_nullId_throwsException() {
    Test.startTest();
    Boolean exceptionThrown = false;
    try {
      OrderController.getSumOrdersOfAccount(null);
    } catch (AuraHandledException e) {
      exceptionThrown = true;
    }
    Test.stopTest();
    System.assert(
      exceptionThrown,
      'L’exception AuraHandledException aurait dû être levée.'
    );
  }
}
