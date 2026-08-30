import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import RouteTemplate from "ember-route-template";
import { ajax } from "discourse/lib/ajax";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const RATING_ICONS = {
  positive: "circle-check",
  neutral: "circle-minus",
  negative: "circle-exclamation",
};

class TradeReputationFeedbackShow extends Component {
  @service currentUser;

  @tracked moderationReason = "";
  @tracked moderationState = "idle";
  @tracked moderationError = null;
  @tracked invalidating = false;

  get feedback() {
    return this.args.model?.feedback ?? this.args.controller?.model?.feedback;
  }

  get ratingLabelKey() {
    return `trade_reputation.feedback_new.ratings.${this.feedback.rating}`;
  }

  get ratingIcon() {
    return RATING_ICONS[this.feedback.rating];
  }

  get canModerate() {
    return Boolean(this.currentUser?.staff);
  }

  get moderationComplete() {
    return this.moderationState === "success";
  }

  get invalidateDisabled() {
    return (
      this.invalidating ||
      this.moderationComplete ||
      this.moderationReason.trim().length === 0
    );
  }

  @action
  updateModerationReason(event) {
    this.moderationReason = event.target.value;
  }

  @action
  async invalidateFeedback() {
    if (this.invalidateDisabled) {
      return;
    }

    this.invalidating = true;
    this.moderationError = null;

    try {
      await ajax(
        `/trade-reputation/feedbacks/public/${this.feedback.public_id}/invalidate.json`,
        {
          type: "PUT",
          data: { reason: this.moderationReason.trim() },
        }
      );
      this.moderationState = "success";
    } catch {
      this.moderationError = i18n(
        "trade_reputation.feedback_detail.moderation.error"
      );
    } finally {
      this.invalidating = false;
    }
  }

  <template>
    <div class="trade-reputation-feedback-detail">
      <header class="trade-reputation-feedback-detail__header">
        <div>
          <p class="trade-reputation-feedback-detail__eyebrow">
            {{i18n "trade_reputation.feedback_detail.eyebrow"}}
          </p>
          <h1>{{i18n "trade_reputation.feedback_detail.title"}}</h1>
          <p class="trade-reputation-feedback-detail__description">
            {{i18n "trade_reputation.feedback_detail.description"}}
          </p>
        </div>
        <span
          class={{dConcatClass
            "trade-reputation-feedback-detail__rating"
            this.feedback.rating
          }}
        >
          {{dIcon this.ratingIcon}}
          {{i18n this.ratingLabelKey}}
        </span>
      </header>

      <section
        class="trade-reputation-feedback-detail__card"
        aria-labelledby="trade-reputation-detail-context-heading"
      >
        <div class="trade-reputation-feedback-detail__section-heading">
          <div>
            <h2 id="trade-reputation-detail-context-heading">
              {{i18n "trade_reputation.feedback_detail.context_heading"}}
            </h2>
            <p>{{i18n "trade_reputation.feedback_detail.context_description"}}</p>
          </div>
          <span class="trade-reputation-feedback-detail__verified">
            {{dIcon "circle-check"}}
            {{i18n "trade_reputation.feedback_detail.verified"}}
          </span>
        </div>

        <dl class="trade-reputation-feedback-detail__facts">
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.transaction"}}</dt>
            <dd>{{this.feedback.transaction_reference}}</dd>
          </div>
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.listing"}}</dt>
            <dd>{{this.feedback.listing_reference}}</dd>
          </div>
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.buyer"}}</dt>
            <dd>
              {{#if this.feedback.buyer}}
                {{this.feedback.buyer.username}}
              {{else}}
                <span class="trade-reputation-feedback-detail__unavailable-user">
                  {{i18n "trade_reputation.feedback_detail.unavailable_user"}}
                </span>
              {{/if}}
            </dd>
          </div>
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.seller"}}</dt>
            <dd>
              {{#if this.feedback.seller}}
                {{this.feedback.seller.username}}
              {{else}}
                <span class="trade-reputation-feedback-detail__unavailable-user">
                  {{i18n "trade_reputation.feedback_detail.unavailable_user"}}
                </span>
              {{/if}}
            </dd>
          </div>
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.rating"}}</dt>
            <dd>{{i18n this.ratingLabelKey}}</dd>
          </div>
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.completed_at"}}</dt>
            <dd>{{dFormatDate this.feedback.completed_at format="medium"}}</dd>
          </div>
          <div>
            <dt>{{i18n "trade_reputation.feedback_detail.feedback_at"}}</dt>
            <dd>{{dFormatDate this.feedback.created_at format="medium"}}</dd>
          </div>
        </dl>
      </section>

      {{#if this.feedback.comment}}
        <section
          class="trade-reputation-feedback-detail__feedback"
          aria-labelledby="trade-reputation-detail-feedback-heading"
        >
          <div class="trade-reputation-feedback-detail__section-heading">
            <div>
              <h2 id="trade-reputation-detail-feedback-heading">
                {{i18n "trade_reputation.feedback_detail.feedback_heading"}}
              </h2>
              <p>{{i18n "trade_reputation.feedback_detail.feedback_description"}}</p>
            </div>
          </div>
          <p class="trade-reputation-feedback-detail__comment">
            {{this.feedback.comment}}
          </p>
        </section>
      {{/if}}

      {{#if this.canModerate}}
        <section
          class="trade-reputation-feedback-detail__moderation"
          aria-labelledby="trade-reputation-moderation-heading"
        >
          <div class="trade-reputation-feedback-detail__moderation-heading">
            <span aria-hidden="true">{{dIcon "circle-exclamation"}}</span>
            <div>
              <h2 id="trade-reputation-moderation-heading">
                {{i18n "trade_reputation.feedback_detail.moderation.heading"}}
              </h2>
              <p class="trade-reputation-feedback-detail__moderation-description">
                {{i18n "trade_reputation.feedback_detail.moderation.description"}}
              </p>
            </div>
          </div>

          {{#if this.moderationComplete}}
            <p
              class="trade-reputation-feedback-detail__moderation-success"
              role="status"
            >
              {{dIcon "circle-check"}}
              {{i18n "trade_reputation.feedback_detail.moderation.success"}}
            </p>
          {{else}}
            <label
              class="trade-reputation-feedback-detail__moderation-label"
              for="trade-reputation-moderation-reason"
            >
              {{i18n "trade_reputation.feedback_detail.moderation.reason_label"}}
            </label>
            <textarea
              id="trade-reputation-moderation-reason"
              class="trade-reputation-feedback-detail__moderation-reason"
              maxlength="1000"
              value={{this.moderationReason}}
              disabled={{this.invalidating}}
              {{on "input" this.updateModerationReason}}
            ></textarea>

            <div class="trade-reputation-feedback-detail__moderation-actions">
              <p>{{i18n "trade_reputation.feedback_detail.moderation.audit_notice"}}</p>
              <button
                type="button"
                class="btn btn-danger trade-reputation-feedback-detail__invalidate-button"
                disabled={{this.invalidateDisabled}}
                aria-busy={{this.invalidating}}
                {{on "click" this.invalidateFeedback}}
              >
                {{#if this.invalidating}}
                  {{i18n "trade_reputation.feedback_detail.moderation.invalidating"}}
                {{else}}
                  {{i18n "trade_reputation.feedback_detail.moderation.invalidate"}}
                {{/if}}
              </button>
            </div>

            {{#if this.moderationError}}
              <p
                class="trade-reputation-feedback-detail__moderation-error"
                role="alert"
              >
                {{this.moderationError}}
              </p>
            {{/if}}
          {{/if}}
        </section>
      {{/if}}
    </div>
  </template>
}

export default RouteTemplate(TradeReputationFeedbackShow);
