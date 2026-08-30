import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import { ajax } from "discourse/lib/ajax";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class TradeReputationMarketplaceFeedbackCta extends Component {
  static shouldRender(outletArgs) {
    return outletArgs.transaction?.status === "completed";
  }

  @tracked eligibility = null;

  constructor() {
    super(...arguments);
    this.loadEligibility();
  }

  get transactionId() {
    return this.args.outletArgs?.transaction?.id;
  }

  // static shouldRender only gates whether the connector is instantiated
  // when mounted through the real PluginOutlet -- it isn't consulted by
  // every possible render path, so this checks status again before firing
  // any request rather than relying solely on the outlet-level gate.
  //
  // The eligibility endpoint is the same authoritative, server-side truth
  // used to gate feedback submission itself (see
  // TradeReputation::FeedbacksController#eligibility) -- it already checks
  // the transaction is completed, the current user is a participant, and
  // whether a TradeReputation::Feedback already exists for this reviewer,
  // so this CTA never has to duplicate that logic client-side.
  async loadEligibility() {
    if (
      !this.transactionId ||
      this.args.outletArgs?.transaction?.status !== "completed"
    ) {
      return;
    }

    try {
      this.eligibility = await ajax(
        `/trade-reputation/feedbacks/${this.transactionId}/eligibility.json`
      );
    } catch {
      this.eligibility = { eligible: false };
    }
  }

  get alreadyReviewed() {
    return !!this.eligibility?.already_reviewed;
  }

  get isEligible() {
    return !!this.eligibility?.eligible;
  }

  <template>
    {{#if this.alreadyReviewed}}
      <span
        class="btn btn-default disabled trade-reputation-feedback-cta trade-reputation-feedback-cta--reviewed"
        title={{i18n "trade_reputation.feedback_new.already_reviewed_cta"}}
        role="status"
      >
        {{dIcon "circle-check"}}
        {{i18n "trade_reputation.feedback_new.already_reviewed_cta"}}
      </span>
    {{else if this.isEligible}}
      <LinkTo
        @route="tradeReputationFeedbackNew"
        @query={{hash transaction_id=@outletArgs.transaction.id}}
        class="btn btn-primary trade-reputation-feedback-cta"
      >
        {{dIcon "circle-check"}}
        {{i18n "trade_reputation.feedback_new.cta"}}
      </LinkTo>
    {{/if}}
  </template>
}
