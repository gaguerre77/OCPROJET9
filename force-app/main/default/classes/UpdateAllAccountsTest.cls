@IsTest
private class UpdateAllAccountsTest {
  @TestSetup
  static void setup() {
    // Créer des données de test pour les comptes et les commandes
    Account testAccount = new Account(
      Name = 'Test Account',
      Chiffre_d_affaire__c = 0.0
    );
    insert testAccount;

    Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
    insert testProduct;

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pricebookEntry = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = testProduct.Id,
      UnitPrice = 100.0,
      IsActive = true
    );
    insert pricebookEntry;

    // Créer des commandes avec le statut 'Draft'
    Order testOrder1 = new Order(
      AccountId = testAccount.Id,
      Status = 'Draft', // S'assurer que le statut est 'Draft'
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPricebookId
    );
    insert testOrder1;

    OrderItem orderItem1 = new OrderItem(
      OrderId = testOrder1.Id,
      PricebookEntryId = pricebookEntry.Id,
      Quantity = 1,
      UnitPrice = pricebookEntry.UnitPrice
    );
    insert orderItem1;

    // Créer d'autres commandes, toujours avec le statut 'Draft'
    Order testOrder2 = new Order(
      AccountId = testAccount.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPricebookId
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
  static void testBatchWithLargeNumberOfOrders() {
    // Récupérer les enregistrements de test
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    List<Order> orders = [
      SELECT Id, AccountId, Status, CustomTotalAmount__c
      FROM Order
      WHERE AccountId = :testAccount.Id
    ];

    // Passer les commandes en statut 'Activated' (une fois insérées et valides)
    for (Order order : orders) {
      order.Status = 'Activated'; // Activer les commandes
    }

    update orders; // Mettre à jour les commandes pour les activer

    // Lancer le batch
    Test.startTest();
    UpdateAllAccounts batch = new UpdateAllAccounts();
    Database.executeBatch(batch, 200); // Exécuter le batch
    Test.stopTest();

    // Vérifier les résultats
    testAccount = [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :testAccount.Id
    ];
    System.assert(
      testAccount.Chiffre_d_affaire__c > 0,
      'Le chiffre d\'affaires du compte n\'a pas été mis à jour.'
    );
  }
}
