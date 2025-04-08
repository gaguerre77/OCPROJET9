@IsTest
public class UpdateAccountCAHandlerTest {
  @TestSetup
  static void setup() {
    // Créer un compte de test
    Account testAccount = new Account(
      Name = 'Test Account',
      Chiffre_d_affaire__c = 0.0
    );
    insert testAccount;

    // Créer un produit
    Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
    insert testProduct;

    // Récupérer le carnet de prix standard
    Id standardPricebookId = Test.getStandardPricebookId();

    // Créer un enregistrement de prix
    PricebookEntry pricebookEntry = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = testProduct.Id,
      UnitPrice = 100.0,
      IsActive = true
    );
    insert pricebookEntry;

    // Créer deux commandes en statut 'Draft'
    Order testOrder1 = new Order(
      AccountId = testAccount.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPricebookId,
      CustomTotalAmount__c = 100.0
    );
    insert testOrder1;

    OrderItem orderItem1 = new OrderItem(
      OrderId = testOrder1.Id,
      PricebookEntryId = pricebookEntry.Id,
      Quantity = 1,
      UnitPrice = pricebookEntry.UnitPrice
    );
    insert orderItem1;

    Order testOrder2 = new Order(
      AccountId = testAccount.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPricebookId,
      CustomTotalAmount__c = 200.0
    );
    insert testOrder2;

    OrderItem orderItem2 = new OrderItem(
      OrderId = testOrder2.Id,
      PricebookEntryId = pricebookEntry.Id,
      Quantity = 2,
      UnitPrice = pricebookEntry.UnitPrice
    );
    insert orderItem2;
  }

  @IsTest
  static void testHandleAfterUpdate() {
    // Récupérer les données de test
    Account testAccount = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      LIMIT 1
    ];
    List<Order> orders = [
      SELECT Id, AccountId, Status, CustomTotalAmount__c
      FROM Order
      WHERE AccountId = :testAccount.Id
    ];

    // Préparer la commande à activer
    Order orderToUpdate = orders[0];
    Order oldOrder = orderToUpdate.clone(false, false, false, false);
    orderToUpdate.Status = 'Activated';

    // Vérification que la commande a des produits
    List<OrderItem> orderItems = [
      SELECT Id
      FROM OrderItem
      WHERE OrderId = :orderToUpdate.Id
    ];
    System.assertNotEquals(
      0,
      orderItems.size(),
      'La commande doit avoir au moins un produit.'
    );

    // Exécuter le traitement dans le bloc de test
    Test.startTest();
    update orderToUpdate;
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ orderToUpdate },
      new Map<Id, Order>{ orderToUpdate.Id => oldOrder }
    );
    Test.stopTest();

    // Vérifier le résultat attendu
    testAccount = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    System.assertEquals(
      100.0,
      testAccount.Chiffre_d_affaire__c,
      'Le champ Chiffre_d_affaire__c n\'a pas été mis à jour correctement.'
    );
  }

  @IsTest
  static void testNoUpdateNeeded() {
    // Récupérer les données de test
    Account testAccount = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      LIMIT 1
    ];
    List<Order> orders = [
      SELECT Id, AccountId, Status, CustomTotalAmount__c
      FROM Order
      WHERE AccountId = :testAccount.Id
    ];

    // Exécuter sans changement de statut
    Test.startTest();
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ orders[1] },
      new Map<Id, Order>{ orders[1].Id => orders[1] }
    );
    Test.stopTest();

    // Le chiffre d'affaires ne doit pas avoir changé
    testAccount = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    System.assertEquals(
      0.0,
      testAccount.Chiffre_d_affaire__c,
      'Le champ Chiffre_d_affaire__c a été modifié incorrectement.'
    );
  }
}
