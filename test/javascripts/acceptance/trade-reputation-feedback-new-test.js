import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const FORM_SELECTOR = ".trade-reputation-feedback-new__form";
const SUBMIT_SELECTOR = `${FORM_SELECTOR} button[type="submit"]`;

function postRequests() {
  return pretender.handledRequests.filter(
    (request) =>
      request.method === "POST" &&
      request.url === "/trade-reputation/feedbacks.json"
  );
}

function eligibilityRequests() {
  return pretender.handledRequests.filter((request) =>
    request.url.includes("/trade-reputation/feedbacks/")
  );
}

acceptance("Trade Reputation | Feedback submission", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get(
      "/trade-reputation/feedbacks/:transaction_id/eligibility.json",
      (request) => {
        switch (request.params.transaction_id) {
          case "2":
            return helper.response({ eligible: false, already_reviewed: true });
          case "3":
            return helper.response({ eligible: false });
          case "4":
            return helper.response(503, { error: "unavailable" });
          default:
            return helper.response({ eligible: true });
        }
      }
    );

    server.post("/trade-reputation/feedbacks.json", (request) => {
      const params = new URLSearchParams(request.requestBody);
      const comment = params.get("comment") || "";

      if (comment.includes("trigger-409")) {
        return helper.response(409, { errors: ["duplicate"] });
      }
      if (comment.includes("trigger-422")) {
        return helper.response(422, { errors: ["ineligible"] });
      }
      if (comment.includes("trigger-503")) {
        return helper.response(503, { errors: ["unavailable"] });
      }
      if (comment.includes("trigger-500")) {
        return helper.response(500, { errors: ["boom"] });
      }

      return helper.response(201, { success: true });
    });
  });

  test("eligible transaction renders the feedback form", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");

    assert.dom(FORM_SELECTOR).exists("the feedback form is rendered");
  });

  test("positive, neutral, and negative ratings can be selected", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");

    for (const rating of ["positive", "neutral", "negative"]) {
      await formKit().field("rating").select(rating);
      assert
        .dom(`input[type="radio"][value="${rating}"]`)
        .isChecked(`${rating} can be selected`);
    }
  });

  test("submit is disabled until a rating is selected", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");

    assert.dom(SUBMIT_SELECTOR).isDisabled("submit starts disabled");

    await formKit().field("rating").select("positive");

    assert
      .dom(SUBMIT_SELECTOR)
      .isNotDisabled("submit enables once a rating is chosen");
  });

  test("submitting sends only the supported fields and shows a success state", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");

    await formKit().field("rating").select("positive");
    await formKit().field("comment").fillIn("Smooth trade");
    await formKit().submit();

    const requests = postRequests();
    assert.strictEqual(requests.length, 1, "one submission request was made");

    const params = new URLSearchParams(requests[0].requestBody);
    assert.deepEqual(
      [...params.keys()].sort(),
      ["comment", "marketplace_transaction_id", "rating"],
      "only the supported fields were sent"
    );
    assert.strictEqual(params.get("marketplace_transaction_id"), "1");
    assert.strictEqual(params.get("rating"), "positive");

    assert
      .dom(".trade-reputation-feedback-new__message.-success")
      .exists("a success state is shown");
    assert.dom(FORM_SELECTOR).doesNotExist("the form is no longer shown");
  });

  test("double submission is prevented while a request is pending", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");
    await formKit().field("rating").select("positive");

    const button = document.querySelector(SUBMIT_SELECTOR);
    const firstClick = click(button);
    const secondClick = click(button);
    await Promise.all([firstClick, secondClick]);

    assert.strictEqual(
      postRequests().length,
      1,
      "only a single submission request was sent"
    );
  });

  test("an already-reviewed eligibility response hides the form", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=2");

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert
      .dom(".trade-reputation-feedback-new__message")
      .containsText("already submitted");
  });

  test("an ordinary ineligible response hides the form", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=3");

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.dom(".trade-reputation-feedback-new__message").exists();
  });

  test("a 503 eligibility response shows a temporary unavailable state", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=4");

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert
      .dom(".trade-reputation-feedback-new__message")
      .containsText("temporarily unavailable");
  });

  test("a 409 submission response shows the already-submitted state", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");
    await formKit().field("rating").select("positive");
    await formKit().field("comment").fillIn("trigger-409");
    await formKit().submit();

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert
      .dom(".trade-reputation-feedback-new__message")
      .containsText("already submitted");
  });

  test("a 422 submission response shows a generic ineligible state", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");
    await formKit().field("rating").select("positive");
    await formKit().field("comment").fillIn("trigger-422");
    await formKit().submit();

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.dom(".trade-reputation-feedback-new__message").exists();
  });

  test("a 503 submission response shows a temporary unavailable state", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");
    await formKit().field("rating").select("positive");
    await formKit().field("comment").fillIn("trigger-503");
    await formKit().submit();

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert
      .dom(".trade-reputation-feedback-new__message")
      .containsText("temporarily unavailable");
  });

  test("an unexpected submission error keeps the form for a retry", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=1");
    await formKit().field("rating").select("positive");
    await formKit().field("comment").fillIn("trigger-500");
    await formKit().submit();

    assert.dom(FORM_SELECTOR).exists("the form remains for a retry");
    assert
      .dom(`${FORM_SELECTOR} .form-kit__alert.alert-error`)
      .exists("a retryable error is shown");
  });

  test("an invalid transaction_id never calls the eligibility or submission endpoints", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=not-a-number");

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.strictEqual(eligibilityRequests().length, 0);
    assert.strictEqual(postRequests().length, 0);
  });

  test("a missing transaction_id never calls the eligibility or submission endpoints", async function (assert) {
    await visit("/trade-reputation/feedback/new");

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.strictEqual(eligibilityRequests().length, 0);
    assert.strictEqual(postRequests().length, 0);
  });

  test("a zero transaction_id never calls the eligibility or submission endpoints", async function (assert) {
    await visit("/trade-reputation/feedback/new?transaction_id=0");

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.strictEqual(eligibilityRequests().length, 0);
    assert.strictEqual(postRequests().length, 0);
  });

  test("a transaction_id that is not a safe integer never calls the eligibility or submission endpoints", async function (assert) {
    await visit(
      "/trade-reputation/feedback/new?transaction_id=9007199254740992"
    );

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.strictEqual(eligibilityRequests().length, 0);
    assert.strictEqual(postRequests().length, 0);
  });

  test("a transaction_id one above the max safe integer never calls the eligibility or submission endpoints", async function (assert) {
    await visit(
      "/trade-reputation/feedback/new?transaction_id=9007199254740993"
    );

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.strictEqual(eligibilityRequests().length, 0);
    assert.strictEqual(postRequests().length, 0);
  });

  test("an arbitrarily large digit-only transaction_id never calls the eligibility or submission endpoints", async function (assert) {
    await visit(
      "/trade-reputation/feedback/new?transaction_id=99999999999999999999999999999999"
    );

    assert.dom(FORM_SELECTOR).doesNotExist();
    assert.strictEqual(eligibilityRequests().length, 0);
    assert.strictEqual(postRequests().length, 0);
  });
});
