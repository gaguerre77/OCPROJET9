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

    // Créer un produit actif
    Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
    insert testProduct;

    // Récupérer le Pricebook standard
    Id standardPricebookId = Test.getStandardPricebookId();

    // Créer une entrée de prix
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = testProduct.Id,
      Pricebook2Id = standardPricebookId,
      UnitPrice = 100.0,
      IsActive = true
    );
    insert pbe;

    // Créer deux commandes en statut Draft
    Order order1 = new Order(
      AccountId = testAccount.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPricebookId,
      CustomTotalAmount__c = 100.0
    );
    insert order1;

    OrderItem oi1 = new OrderItem(
      OrderId = order1.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 1,
      UnitPrice = 100.0
    );
    insert oi1;

    Order order2 = new Order(
      AccountId = testAccount.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPricebookId,
      CustomTotalAmount__c = 200.0
    );
    insert order2;

    OrderItem oi2 = new OrderItem(
      OrderId = order2.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 2,
      UnitPrice = 100.0
    );
    insert oi2;
  }

  @IsTest
  static void testHandleAfterUpdate() {
    // Récupérer le compte et les commandes
    Account acc = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
    List<Order> orders = [
      SELECT Id, AccountId, Status, CustomTotalAmount__c
      FROM Order
      WHERE AccountId = :acc.Id
    ];

    // Simuler un changement de statut de Draft → Activated
    Order orderToUpdate = orders[0];
    Order oldOrder = orderToUpdate.clone(false, false, false, false);
    orderToUpdate.Status = 'Activated';

    Test.startTest();
    update orderToUpdate;
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ orderToUpdate },
      new Map<Id, Order>{ orderToUpdate.Id => oldOrder }
    );
    Test.stopTest();

    // Le chiffre d'affaire devrait refléter uniquement la commande activée
    acc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(
      100.0,
      acc.Chiffre_d_affaire__c,
      'Chiffre d\'affaire incorrect après activation'
    );
  }

  @IsTest
  static void testNoStatusChangeDoesNothing() {
    // Récupérer les commandes de test
    Account acc = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
    List<Order> orders = [
      SELECT Id, AccountId, Status, CustomTotalAmount__c
      FROM Order
      WHERE AccountId = :acc.Id
    ];

    // Aucune modification de statut
    Test.startTest();
    UpdateAccountCAHandler.handleAfterUpdate(
      new List<Order>{ orders[1] },
      new Map<Id, Order>{ orders[1].Id => orders[1] }
    );
    Test.stopTest();

    // Le chiffre d'affaire doit rester à 0
    acc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(
      0.0,
      acc.Chiffre_d_affaire__c,
      'Chiffre d\'affaire ne devrait pas être modifié'
    );
  }
}
