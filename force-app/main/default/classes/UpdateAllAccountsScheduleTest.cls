@isTest
public class UpdateAllAccountsScheduleTest {
  @isTest
  static void testExecuteSchedulesBatchWithTestDataFactory() {
    // 🧪 Générer les données de test (2 commandes Draft)
    TestDataFactory.TestEntities data = TestDataFactory.createBaseDataWithDraftOrders(
      2
    );

    // ⚙️ Créer des OrderItems sur chaque commande
    List<OrderItem> items = new List<OrderItem>();
    for (Order o : data.orders) {
      items.add(
        new OrderItem(
          OrderId = o.Id,
          Quantity = 2,
          PricebookEntryId = data.pricebookEntryId,
          UnitPrice = 80 // volontairement différent du prix standard
        )
      );
    }
    insert items;

    // ✅ Activer une des commandes pour déclencher le calcul de CA
    Order activatedOrder = data.orders[0];
    activatedOrder.Status = 'Activated';
    update activatedOrder;

    // 🔁 Exécution de la classe Schedulable (appel manuel de execute)
    Test.startTest();
    new UpdateAllAccountsSchedule().execute(null);
    Test.stopTest();

    // 📊 Vérification : le CA du compte doit avoir été mis à jour (2 * 100)
    Account updatedAcc = [
      SELECT Chiffre_d_affaire__c
      FROM Account
      WHERE Id = :data.accountId
    ];
    System.assertEquals(
      200,
      updatedAcc.Chiffre_d_affaire__c,
      '💥 Le chiffre d\'affaire est incorrect après l\'exécution du batch'
    );
  }
}
