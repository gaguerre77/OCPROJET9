import { LightningElement, api, wire, track } from "lwc";
import getSumOrdersOfAccount from "@salesforce/apex/OrderController.getSumOrdersOfAccount";
import { refreshApex } from "@salesforce/apex";

export default class Orders extends LightningElement {
  @track sumOrdersOfCurrentAccount = 0;
  @api recordId;
  wiredSumOrdersResult;

  get isError() {
    const result = this.sumOrdersOfCurrentAccount <= 0;
    console.log("🟥 isError →", result);
    return result;
  }

  get isSuccess() {
    const result = this.sumOrdersOfCurrentAccount > 0;
    console.log("🟩 isSuccess →", result);
    return result;
  }

  @wire(getSumOrdersOfAccount, { accountId: "$recordId" })
  wiredSumOrders(result) {
    console.log("📨 wiredSumOrders called with recordId:", this.recordId);
    this.wiredSumOrdersResult = result;
    const { data, error } = result;

    if (data) {
      this.sumOrdersOfCurrentAccount = data;
      console.log("✅ Data received from Apex:", data);
    } else if (error) {
      console.error("❌ Error during Apex call:", error);
      this.sumOrdersOfCurrentAccount = 0;
    }
  }

  // Method to refresh data
  handleRefresh() {
    console.log("🔄 Refresh button clicked");
    refreshApex(this.wiredSumOrdersResult);
  }

  connectedCallback() {
    console.log("🔌 Component connected to the DOM");
  }

  renderedCallback() {
    console.log("🖌 Component rendered");
  }

  disconnectedCallback() {
    console.log("🔌 Component disconnected from the DOM");
  }
}
