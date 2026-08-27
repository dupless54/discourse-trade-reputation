import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

<template>
  {{#let @controller.model.feedback as |feedback|}}
    <div class="trade-reputation-feedback-detail">
      <h1>{{i18n "trade_reputation.feedback_detail.title"}}</h1>
      <dl>
        <dt>{{i18n "trade_reputation.feedback_detail.transaction"}}</dt>
        <dd>{{feedback.transaction_reference}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.listing"}}</dt>
        <dd>{{feedback.listing_reference}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.buyer"}}</dt>
        <dd>
          {{#if feedback.buyer}}
            {{feedback.buyer.username}}
          {{else}}
            {{i18n "trade_reputation.feedback_detail.deleted_user"}}
          {{/if}}
        </dd>
        <dt>{{i18n "trade_reputation.feedback_detail.seller"}}</dt>
        <dd>
          {{#if feedback.seller}}
            {{feedback.seller.username}}
          {{else}}
            {{i18n "trade_reputation.feedback_detail.deleted_user"}}
          {{/if}}
        </dd>
        <dt>{{i18n "trade_reputation.feedback_detail.rating"}}</dt>
        <dd>{{feedback.rating}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.completed_at"}}</dt>
        <dd>{{dFormatDate feedback.completed_at format="medium"}}</dd>
        <dt>{{i18n "trade_reputation.feedback_detail.feedback_at"}}</dt>
        <dd>{{dFormatDate feedback.created_at format="medium"}}</dd>
      </dl>
      {{#if feedback.comment}}
        <p>{{feedback.comment}}</p>
      {{/if}}
    </div>
  {{/let}}
</template>
