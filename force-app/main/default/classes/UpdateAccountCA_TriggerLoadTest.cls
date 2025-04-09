/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
public class UpdateAccountCA_TriggerLoadTest {
  @IsTest
  static void testTriggerWithMoreThan100Orders() {
    // Créer un compte de test
    Account acc = new Account(Name = 'Big Account', Chiffre_d_affaire__c = 0.0);
    insert acc;

    // Créer un produit actif
    Product2 prod = new Product2(Name = 'Bulk Product', IsActive = true);
    insert prod;

    // Récupérer le Pricebook standard
    Id pbId = Test.getStandardPricebookId();

    // Créer une entrée de prix
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = prod.Id,
      Pricebook2Id = pbId,
      UnitPrice = 10.0,
      IsActive = true
    );
    insert pbe;

    List<Order> orders = new List<Order>();
    List<OrderItem> orderItems = new List<OrderItem>();

    // Créer 150 commandes "Draft" + leurs OrderItems
    for (Integer i = 0; i < 150; i++) {
      Order ord = new Order(
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = pbId,
        CustomTotalAmount__c = 10.0
      );
      orders.add(ord);
    }
    insert orders;

    // Ajouter les OrderItems
    for (Order ord : orders) {
      orderItems.add(
        new OrderItem(
          OrderId = ord.Id,
          PricebookEntryId = pbe.Id,
          Quantity = 1,
          UnitPrice = 10.0
        )
      );
    }
    insert orderItems;

    // Cloner les versions "avant" update
    Map<Id, Order> oldOrdersMap = new Map<Id, Order>();
    for (Order ord : orders) {
      Order oldOrd = ord.clone(false, false, false, false);
      oldOrdersMap.put(ord.Id, oldOrd);
    }

    // Passer tous les statuts à "Activated"
    for (Order ord : orders) {
      ord.Status = 'Activated';
    }

    Test.startTest();
    update orders; // le trigger s'exécutera ici
    Test.stopTest();

    // Vérifier que le chiffre d'affaires du compte est mis à jour
    acc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(
      1500.0,
      acc.Chiffre_d_affaire__c,
      'Chiffre d\'affaire incorrect avec plus de 100 commandes'
    );
  }
}
