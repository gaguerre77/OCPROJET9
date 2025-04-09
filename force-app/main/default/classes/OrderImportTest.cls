@isTest
private class OrderImportTest {
  @isTest
  static void testInsertItemsThenActivateOrders() {
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );
    List<Order> orders = data.orders;

    // Charger manuellement la ressource statique
    StaticResource csvResource = [
      SELECT Body
      FROM StaticResource
      WHERE Name = 'OrderItems'
      LIMIT 1
    ];

    // Parser les lignes et injecter les bons IDs
    List<OrderItem> items = parseOrderItemsFromCSV(
      csvResource,
      orders[0].Id,
      orders[1].Id,
      data.pricebookEntryId
    );

    insert items;

    System.assertEquals(
      20,
      items.size(),
      '❌ 20 OrderItems doivent être insérés'
    );

    // Activer les commandes
    for (Order o : orders) {
      o.Status = 'Activated';
    }
    update orders;

    // Vérifier le NetAmount__c
    List<Order> updatedOrders = [
      SELECT Id, NAme, TotalAmount, ShipmentCost__c, NetAmount__c
      FROM Order
      WHERE Id IN :orders
    ];

    for (Order o : updatedOrders) {
      Decimal expected = o.TotalAmount - o.ShipmentCost__c;
      System.assertEquals(
        expected,
        o.NetAmount__c,
        '❌ NetAmount__c incorrect pour ' + o.Name
      );
    }
  }

  private static List<OrderItem> parseOrderItemsFromCSV(
    StaticResource csvResource,
    Id order1Id,
    Id order2Id,
    Id pbeId
  ) {
    List<OrderItem> items = new List<OrderItem>();

    String csv = csvResource.Body.toString();
    List<String> lines = csv.split('\n');

    for (Integer i = 1; i < lines.size(); i++) {
      if (String.isBlank(lines[i]))
        continue;
      List<String> cols = lines[i].trim().split(',');

      Integer qty = Integer.valueOf(cols[2]);
      Decimal price = Decimal.valueOf(cols[3]);

      OrderItem item = new OrderItem(
        OrderId = (i <= 10) ? order1Id : order2Id,
        PricebookEntryId = pbeId,
        Quantity = qty,
        UnitPrice = price
      );
      items.add(item);
    }

    return items;
  }
}
