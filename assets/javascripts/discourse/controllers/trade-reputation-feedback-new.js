import Controller from "@ember/controller";

export default class TradeReputationFeedbackNewController extends Controller {
  queryParams = ["transaction_id"];
  transaction_id = null;
}
