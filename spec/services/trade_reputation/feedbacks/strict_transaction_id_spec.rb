# frozen_string_literal: true

describe TradeReputation::Feedbacks::Create do
  fab!(:buyer, :user)

  it "rejects a partially numeric transaction id before calling Marketplace" do
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)

    result =
      described_class.call(
        guardian: buyer.guardian,
        params: {
          marketplace_transaction_id: "1abc",
          rating: "positive",
          comment: nil,
        },
      )

    expect(result).to be_failure
    expect(Marketplace::TradeContract).not_to have_received(:completed_transaction_info)
  end

  it "passes a verified positive integer to Marketplace after strict parsing" do
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info).and_return(nil)

    result =
      described_class.call(
        guardian: buyer.guardian,
        params: {
          marketplace_transaction_id: "123",
          rating: "positive",
          comment: nil,
        },
      )

    expect(result).to be_failure
    expect(result.feedback_ineligible).to eq(true)
    expect(Marketplace::TradeContract).to have_received(:completed_transaction_info).with(123)
  end
end
