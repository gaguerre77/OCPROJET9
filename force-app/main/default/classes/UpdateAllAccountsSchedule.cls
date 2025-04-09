public class UpdateAllAccountsSchedule implements Schedulable {
  public void execute(SchedulableContext context) {
    // Créer une instance du batch
    UpdateAllAccounts batch = new UpdateAllAccounts();

    // Exécuter le batch avec une taille de lot de 200
    Database.executeBatch(batch, 200);
  }
}
