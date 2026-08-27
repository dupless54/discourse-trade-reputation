import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import { i18n } from "discourse-i18n";

export default class TradeReputationMarketplaceFeedbackCta extends Component {
  static shouldRender(outletArgs) {
    return outletArgs.transaction?.status === "completed";
  }

  <template>
    <LinkTo
      @route="tradeReputationFeedbackNew"
      @query={{hash transaction_id=@outletArgs.transaction.id}}
      class="btn btn-primary trade-reputation-feedback-cta"
    >
      {{i18n "trade_reputation.feedback_new.cta"}}
    </LinkTo>
  </template>
}
