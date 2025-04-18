trigger UpdateAccountCA on Order(after update) {
  // Appeler la méthode du gestionnaire pour traiter la logique métier
  UpdateAccountCAHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
  //test
}
