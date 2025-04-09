@IsTest
public class OrderControllerTest {
  @IsTest
  static void testGetSumOrdersOfAccount() {
    // Créer un compte de test
    Account acc = new Account(Name = 'Compte Test');
    insert acc;

    // Créer un produit actif
    Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
    insert prod;

    // Récupérer le Pricebook standard
    Id pbId = Test.getStandardPricebookId();

    // Créer une entrée de prix active
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = prod.Id,
      Pricebook2Id = pbId,
      UnitPrice = 100.0,
      IsActive = true
    );
    insert pbe;

    // Créer 3 commandes en Draft
    List<Order> orders = new List<Order>{
      new Order(
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = pbId
      ),
      new Order(
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = pbId
      ),
      new Order(
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = pbId
      )
    };
    insert orders;

    // Ajouter les OrderItems
    List<OrderItem> orderItems = new List<OrderItem>{
      new OrderItem(
        OrderId = orders[0].Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100.0
      ), // activated
      new OrderItem(
        OrderId = orders[1].Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 150.0
      ), // activated
      new OrderItem(
        OrderId = orders[2].Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 200.0
      ) // reste en draft
    };
    insert orderItems;

    // Activer uniquement les deux premières commandes
    orders[0].Status = 'Activated';
    orders[1].Status = 'Activated';
    update new List<Order>{ orders[0], orders[1] };

    // Récupérer les TotalAmount
    orders = [SELECT Id, Status, TotalAmount FROM Order WHERE Id IN :orders];

    Decimal expected = 0;
    for (Order o : orders) {
      if (o.Status == 'Activated') {
        expected += o.TotalAmount;
      }
    }

    // Appeler la méthode du contrôleur
    Test.startTest();
    Decimal actual = OrderController.getSumOrdersOfAccount(acc.Id);
    Test.stopTest();

    // Vérifier la somme des commandes Activated
    System.assertEquals(
      expected,
      actual,
      'La somme doit correspondre aux TotalAmount des commandes activées.'
    );
  }
}
