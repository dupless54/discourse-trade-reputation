import Component from "@glimmer/component";
import RouteTemplate from "ember-route-template";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

class TradeReputationFeedbackShow extends Component {
  get feedback() {
    return this.args.model.feedback;
  }

  <template>
    <div class="trade-reputation-feedback-detail">
      <h1>{{i18n "trade_reputation.feedback_detail.title"}}</h1>
      <dl>
        <dt>{{i18n "trade_reputation.feedback_detail.transaction"}}</dt>
        <dd>{{this.feedback.transaction_reference}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.listing"}}</dt>
        <dd>{{this.feedback.listing_reference}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.buyer"}}</dt>
        <dd>
          {{#if this.feedback.buyer}}
            {{this.feedback.buyer.username}}
          {{else}}
            {{i18n "trade_reputation.feedback_detail.deleted_user"}}
          {{/if}}
        </dd>
        <dt>{{i18n "trade_reputation.feedback_detail.seller"}}</dt>
        <dd>
          {{#if this.feedback.seller}}
            {{this.feedback.seller.username}}
          {{else}}
            {{i18n "trade_reputation.feedback_detail.deleted_user"}}
          {{/if}}
        </dd>
        <dt>{{i18n "trade_reputation.feedback_detail.rating"}}</dt>
        <dd>{{this.feedback.rating}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.completed_at"}}</dt>
        <dd>{{dFormatDate this.feedback.completed_at format="medium"}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.feedback_at"}}</dt>
        <dd>{{dFormatDate this.feedback.created_at format="medium"}}</dd>
      </dl>
      {{#if this.feedback.comment}}
        <p>{{this.feedback.comment}}</p>
      {{/if}}
    </div>
  </template>
}

export default RouteTemplate(TradeReputationFeedbackShow);
