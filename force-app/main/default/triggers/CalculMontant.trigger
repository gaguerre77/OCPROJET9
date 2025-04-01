trigger CalculMontant on Order(before update) {
  Order newOrder = Trigger.new[0];
  newOrder.NetAmount__c = newOrder.TotalAmount - newOrder.ShipmentCost__c;
}
