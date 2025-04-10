@isTest
public class UpdateAccountCAHandlerTest {
  @TestSetup
  static void setupTestData() {
    // Créer un compte, produit, PBE et 2 commandes Draft via la factory
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );
    List<Order> orders = data.orders;

    // Ajouter des OrderItems pour calculer automatiquement le TotalAmount

    // Commande 1 : 1 x 100 + 2 x 150 = 400
    List<OrderItem> items = new List<OrderItem>{
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
      // Commande 2 : 3 x 200 = 600
      new OrderItem(
        OrderId = orders[1].Id,
        PricebookEntryId = data.pricebookEntryId,
        Quantity = 3,
        UnitPrice = 200
      )
    };

    insert items;

    // TotalAmount sera automatiquement calculé par Salesforce après insertion des OrderItems
  }

  @isTest
  static void testChiffreAffaireAvecTotalAmount() {
    // Récupérer les commandes
    List<Order> orders = [
      SELECT Id, Status, AccountId
      FROM Order
      ORDER BY CreatedDate ASC
      LIMIT 2
    ];

    Order orderToActivate = orders[0];
    Order oldOrder = orderToActivate.clone(false, false, false, false);

    // Activer la commande (commande 1 : TotalAmount = 400)
    orderToActivate.Status = 'Activated';

    Test.startTest();
    update orderToActivate;
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ orderToActivate },
      new Map<Id, Order>{ orderToActivate.Id => oldOrder }
    );
    Test.stopTest();

    // Vérifier que le CA du compte est bien égal à TotalAmount de la commande activée
    Account acc = [
      SELECT Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :orderToActivate.AccountId
      LIMIT 1
    ];

    Decimal expected = 400;
    System.debug(
      '✅ CA attendu : ' + expected + ' | CA réel : ' + acc.Chiffre_d_affaire__c
    );
    System.assertEquals(
      expected,
      acc.Chiffre_d_affaire__c,
      '❌ Le CA ne correspond pas au TotalAmount de la commande.'
    );
  }

  @isTest
  static void testStatutInchangeNeModifiePasCA() {
    List<Order> orders = [
      SELECT Id, Status, AccountId
      FROM Order
      ORDER BY CreatedDate ASC
      LIMIT 2
    ];

    Order unchangedOrder = orders[1]; // reste en Draft

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
      '❌ Le CA ne doit pas être modifié si le statut ne change pas.'
    );
  }
}
