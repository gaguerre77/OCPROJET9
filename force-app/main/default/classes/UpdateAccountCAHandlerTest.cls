@isTest
public class UpdateAccountCAHandlerTest {
  @TestSetup
  static void setupTestData() {
    // Crée un compte, produit, PBE, et deux commandes Draft via la factory
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );
    List<Order> orders = data.orders;

    // Créer les lignes de commandes pour chaque Order
    List<OrderItem> items = new List<OrderItem>{
      // Commande 1 : 1 x 100 + 2 x 150 = 400
      new OrderItem(
        OrderId = orders[0].Id,
        PricebookEntryId = data.pricebookEntryId,
        Quantity = 1,
        UnitPrice = 100
      ),
      new OrderItem(
        OrderId = orders[0].Id,
        PricebookEntryId = data.pricebookEntryId,
        Quantity = 2,
        UnitPrice = 150
      ),
      // Commande 2 : 3 x 200 = 600 (non activée dans ce test)
      new OrderItem(
        OrderId = orders[1].Id,
        PricebookEntryId = data.pricebookEntryId,
        Quantity = 3,
        UnitPrice = 200
      )
    };

    insert items;
  }

  @isTest
  static void testChiffreAffaireRecalculatedOnActivation() {
    // Récupérer les commandes créées
    List<Order> orders = [
      SELECT Id, Status, AccountId
      FROM Order
      ORDER BY CreatedDate ASC
      LIMIT 2
    ];

    Order orderToActivate = orders[0];
    Order oldOrder = orderToActivate.clone(false, false, false, false);

    // Activer la commande
    orderToActivate.Status = 'Activated';

    Test.startTest();
    update orderToActivate;
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ orderToActivate },
      new Map<Id, Order>{ orderToActivate.Id => oldOrder }
    );
    Test.stopTest();

    // Vérification du CA = 400 (100×1 + 150×2)
    Account acc = [
      SELECT Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :orderToActivate.AccountId
      LIMIT 1
    ];

    System.debug(
      '✅ CA attendu : 400 | CA calculé : ' + acc.Chiffre_d_affaire__c
    );
    System.assertEquals(
      400,
      acc.Chiffre_d_affaire__c,
      '❌ Le chiffre d\'affaire devrait être 400 après activation.'
    );
  }

  @isTest
  static void testNoRecalculationIfStatusUnchanged() {
    List<Order> orders = [
      SELECT Id, Status, AccountId
      FROM Order
      ORDER BY CreatedDate ASC
      LIMIT 2
    ];

    Order unchangedOrder = orders[1];

    Test.startTest();
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ unchangedOrder },
      new Map<Id, Order>{ unchangedOrder.Id => unchangedOrder }
    );
    Test.stopTest();

    Account acc = [
      SELECT Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :unchangedOrder.AccountId
      LIMIT 1
    ];

    Decimal actualCA = acc.Chiffre_d_affaire__c != null
      ? acc.Chiffre_d_affaire__c
      : 0;
    System.assertEquals(
      0,
      actualCA,
      '❌ Le CA ne doit pas être modifié sans changement de statut.'
    );
  }
}
