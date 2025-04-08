@isTest
private class UpdateAllAccountsScheduleTest {
  @TestSetup
  static void setup() {
    // Créer des données de test pour les comptes, les produits et les commandes
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
      Status = 'Draft',
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

  @isTest
  static void testScheduledBatchExecution() {
    // Créer une instance du job scheduler
    String cronExp = '0 0 0 * * ?'; // Planifie l'exécution tous les jours à minuit
    String jobName = 'Test UpdateAllAccountsSchedule';

    // Planifier le job pour qu'il s'exécute à l'heure définie par l'expression cron
    System.schedule(jobName, cronExp, new UpdateAllAccountsSchedule());

    // Exécuter le test
    Test.startTest();

    // Vérifier que le job a bien été planifié
    CronTrigger ct = [
      SELECT Id, State, NextFireTime
      FROM CronTrigger
      WHERE CronJobDetail.Name = :jobName
      LIMIT 1
    ];

    // Vérifier l'état du job et la prochaine exécution
    System.assertEquals(
      'WAITING',
      ct.State,
      'Le job doit être dans l\'état WAITING'
    );
    System.assertNotEquals(
      null,
      ct.NextFireTime,
      'Le job doit avoir une prochaine heure d\'exécution définie'
    );

    Test.stopTest();
  }
}
