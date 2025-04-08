trigger CalculMontant on Order(before update) {
  // remplacé par un champ calculé
  //Order newOrder = Trigger.new[0];
  //newOrder.NetAmount__c = newOrder.TotalAmount - newOrder.ShipmentCost__c;
}
