import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class TradeReputationFeedbackShowRoute extends DiscourseRoute {
  model(params) {
    return ajax(`/trade-reputation/feedbacks/public/${params.public_id}.json`);
  }

  titleToken() {
    return i18n("trade_reputation.feedback_detail.title");
  }
}
