import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const PUBLIC_ID = "11111111-1111-4111-8111-111111111111";
const DETAIL_PATH = `/trade-reputation/feedback/${PUBLIC_ID}`;
const MODERATION_PATH =
  `/trade-reputation/feedbacks/public/${PUBLIC_ID}/invalidate.json`;

const feedbackResponse = {
  feedback: {
    public_id: PUBLIC_ID,
    transaction_reference: "TR-42",
    listing_reference: "LISTING-7",
    rating: "positive",
    comment: "Smooth trade",
    created_at: "2026-08-27T10:00:00Z",
    completed_at: "2026-08-27T09:00:00Z",
    buyer: { username: "buyer" },
    seller: { username: "seller" },
    reviewer: { username: "buyer" },
    reviewee: { username: "seller" },
  },
};

function installDetailPretender(needs, moderationRequests = []) {
  needs.pretender((server, helper) => {
    server.get(
      "/trade-reputation/feedbacks/public/:public_id.json",
      () => helper.response(feedbackResponse)
    );

    server.put(
      "/trade-reputation/feedbacks/public/:public_id/invalidate.json",
      (request) => {
        moderationRequests.push(request);
        return helper.response({ success: true });
      }
    );
  });
}

acceptance("Trade Reputation | Feedback detail | regular user", function (needs) {
  needs.user({ admin: false, moderator: false, staff: false });
  installDetailPretender(needs);

  test("does not render staff moderation controls", async function (assert) {
    await visit(DETAIL_PATH);

    assert.dom(".trade-reputation-feedback-detail__card").exists();
    assert
      .dom(".trade-reputation-feedback-detail__moderation")
      .doesNotExist("moderation controls are staff-only");
  });
});

acceptance("Trade Reputation | Feedback detail | staff", function (needs) {
  needs.user({ admin: true, moderator: false, staff: true });
  const moderationRequests = [];
  installDetailPretender(needs, moderationRequests);

  needs.hooks.afterEach(() => moderationRequests.splice(0));

  test("staff can invalidate feedback with an audit reason", async function (assert) {
    await visit(DETAIL_PATH);

    const button = ".trade-reputation-feedback-detail__invalidate-button";
    assert.dom(button).isDisabled("a reason is required");

    await fillIn("#trade-reputation-moderation-reason", "abusive content");
    assert.dom(button).isNotDisabled("the action enables after a reason is entered");

    await click(button);

    assert.strictEqual(moderationRequests.length, 1, "one moderation request was sent");
    assert.strictEqual(moderationRequests[0].url, MODERATION_PATH);

    const params = new URLSearchParams(moderationRequests[0].requestBody);
    assert.strictEqual(params.get("reason"), "abusive content");
    assert
      .dom(".trade-reputation-feedback-detail__moderation-success")
      .exists("a success state is shown");
  });
});
