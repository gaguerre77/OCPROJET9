@isTest
public class UpdateOrderCustomTotalAmountTest {
  @isTest
  static void testCustomTotalAmountUpdate() {
    // Créer un produit
    Product2 p = new Product2(Name = 'Produit test', IsActive = true);
    insert p;

    // Récupérer l'Id du Pricebook standard
    Id standardPBId = Test.getStandardPricebookId();

    // Créer le PricebookEntry associé
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = p.Id,
      Pricebook2Id = standardPBId,
      UnitPrice = 100,
      IsActive = true
    );
    insert pbe;

    // Créer un compte
    Account acc = new Account(Name = 'Compte test');
    insert acc;

    // Créer une commande
    Order o = new Order(
      Name = 'Commande test',
      Status = 'Draft',
      EffectiveDate = Date.today(),
      AccountId = acc.Id,
      Pricebook2Id = standardPBId
    );
    insert o;

    // Créer une ligne de commande
    OrderItem item = new OrderItem(
      OrderId = o.Id,
      Quantity = 2,
      UnitPrice = 100,
      PricebookEntryId = pbe.Id
    );
    insert item;

    // ➕ Séparer les DML du déclencheur avec start/stopTest
    Test.startTest();

    // Mise à jour du statut → déclenche le trigger
    o.Status = 'Activated';
    update o;

    Test.stopTest(); // ← force l’exécution complète du trigger

    // Vérification finale
    Order updatedOrder = [
      SELECT CustomTotalAmount__c
      FROM Order
      WHERE Id = :o.Id
    ];
    System.debug('CustomTotalAmount__c = ' + updatedOrder.CustomTotalAmount__c);
    System.assertEquals(
      200,
      updatedOrder.CustomTotalAmount__c,
      'Le montant total doit être 200.'
    );
  }
}
