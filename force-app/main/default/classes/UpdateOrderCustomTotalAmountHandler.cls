public class UpdateOrderCustomTotalAmountHandler {
  public static void handle(List<Order> orders) {
    Set<Id> orderIds = new Set<Id>();
    for (Order o : orders) {
      orderIds.add(o.Id);
    }

    Map<Id, Decimal> orderAmountMap = new Map<Id, Decimal>();

    for (AggregateResult ar : [
      SELECT OrderId, SUM(TotalPrice) total
      FROM OrderItem
      WHERE OrderId IN :orderIds
      GROUP BY OrderId
    ]) {
      orderAmountMap.put((Id) ar.get('OrderId'), (Decimal) ar.get('total'));
    }

    List<Order> ordersToUpdate = new List<Order>();
    for (Order o : orders) {
      Decimal total = orderAmountMap.get(o.Id);
      if (total == null)
        total = 0;

      Order updatedOrder = new Order(Id = o.Id);
      updatedOrder.CustomTotalAmount__c = total;
      ordersToUpdate.add(updatedOrder);
    }

    if (!ordersToUpdate.isEmpty()) {
      // 👉 Empêche la récursivité ici

      update ordersToUpdate;
    }
  }
}
