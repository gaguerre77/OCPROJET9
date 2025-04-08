trigger UpdateOrderCustomTotalAmount on Order(after insert, after update) {
  if (!TriggerControl.isFirstRun('UpdateOrderCustomTotalAmount'))
    return;

  if (Trigger.isAfter) {
    if (Trigger.isInsert || Trigger.isUpdate) {
      UpdateOrderCustomTotalAmountHandler.handle(Trigger.new);
    }
  }
}
