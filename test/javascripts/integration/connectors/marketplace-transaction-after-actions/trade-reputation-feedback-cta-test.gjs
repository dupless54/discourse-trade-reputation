import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import TradeReputationFeedbackCta from "discourse/plugins/discourse-trade-reputation/discourse/connectors/marketplace-transaction-after-actions/trade-reputation-feedback-cta";

const CTA_SELECTOR = ".trade-reputation-feedback-cta";

module(
  "Integration | Connector | Marketplace transaction feedback CTA",
  function (hooks) {
    setupRenderingTest(hooks);

    test("renders for a completed transaction with the feedback route", async function (assert) {
      this.outletArgs = {
        transaction: { id: 42, status: "completed" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );

      assert.dom(CTA_SELECTOR).exists("completed transaction shows the CTA");
      assert
        .dom(CTA_SELECTOR)
        .hasAttribute(
          "href",
          "/trade-reputation/feedback/new?transaction_id=42",
          "CTA points to the existing feedback form"
        );
    });

    test("does not render for a pending transaction", async function (assert) {
      this.outletArgs = {
        transaction: { id: 43, status: "pending" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );

      assert.dom(CTA_SELECTOR).doesNotExist();
    });
  }
);
