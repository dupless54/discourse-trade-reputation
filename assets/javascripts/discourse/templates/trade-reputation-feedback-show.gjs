import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import RouteTemplate from "ember-route-template";
import { ajax } from "discourse/lib/ajax";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

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
      <div class="trade-reputation-feedback-detail__header">
        <h1>{{i18n "trade_reputation.feedback_detail.title"}}</h1>
        <span
          class={{dConcatClass
            "trade-reputation-feedback-detail__rating"
            this.feedback.rating
          }}
        >
          {{i18n this.ratingLabelKey}}
        </span>
      </div>

      <section class="trade-reputation-feedback-detail__card">
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
          <dd>{{i18n this.ratingLabelKey}}</dd>
          <dt>{{i18n "trade_reputation.feedback_detail.completed_at"}}</dt>
          <dd>{{dFormatDate this.feedback.completed_at format="medium"}}</dd>
          <dt>{{i18n "trade_reputation.feedback_detail.feedback_at"}}</dt>
          <dd>{{dFormatDate this.feedback.created_at format="medium"}}</dd>
        </dl>

        {{#if this.feedback.comment}}
          <p class="trade-reputation-feedback-detail__comment">
            {{this.feedback.comment}}
          </p>
        {{/if}}
      </section>

      {{#if this.canModerate}}
        <section
          class="trade-reputation-feedback-detail__moderation"
          aria-labelledby="trade-reputation-moderation-heading"
        >
          <h2 id="trade-reputation-moderation-heading">
            {{i18n "trade_reputation.feedback_detail.moderation.heading"}}
          </h2>

          {{#if this.moderationComplete}}
            <p
              class="trade-reputation-feedback-detail__moderation-success"
              role="status"
            >
              {{i18n "trade_reputation.feedback_detail.moderation.success"}}
            </p>
          {{else}}
            <p class="trade-reputation-feedback-detail__moderation-description">
              {{i18n "trade_reputation.feedback_detail.moderation.description"}}
            </p>

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

            <button
              type="button"
              class="btn btn-danger trade-reputation-feedback-detail__invalidate-button"
              disabled={{this.invalidateDisabled}}
              {{on "click" this.invalidateFeedback}}
            >
              {{#if this.invalidating}}
                {{i18n "trade_reputation.feedback_detail.moderation.invalidating"}}
              {{else}}
                {{i18n "trade_reputation.feedback_detail.moderation.invalidate"}}
              {{/if}}
            </button>

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
