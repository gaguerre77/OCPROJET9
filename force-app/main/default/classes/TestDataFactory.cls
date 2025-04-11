// test Data Factory
@isTest
public class TestDataFactory {
  public class TestEntities {
    public Id accountId;
    public Id productId;
    public Id pricebookEntryId;
    public Id pricebook2Id;
    public List<Order> orders;
  }

  public static TestEntities createBaseDataWithDraftOrders(Integer nbOrders) {
    TestEntities result = new TestEntities();

    // Création du compte
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    result.accountId = acc.Id;

    // Création du produit
    Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
    insert prod;
    result.productId = prod.Id;

    // Pricebook standard + PBE
    Id stdPbId = Test.getStandardPricebookId();
    result.pricebook2Id = stdPbId;

    PricebookEntry pbe = new PricebookEntry(
      Product2Id = prod.Id,
      Pricebook2Id = stdPbId,
      UnitPrice = 100,
      IsActive = true
    );
    insert pbe;
    result.pricebookEntryId = pbe.Id;

    // Création des commandes en statut Draft
    List<Order> orders = new List<Order>();
    for (Integer i = 0; i < nbOrders; i++) {
      orders.add(
        new Order(
          Name = 'Test Order ' + (i + 1),
          AccountId = acc.Id,
          Pricebook2Id = stdPbId,
          Status = 'Draft',
          EffectiveDate = Date.today(),
          ShipmentCost__c = 10 + (i * 5)
        )
      );
    }

    insert orders;
    result.orders = orders;

    return result;
  }
}
