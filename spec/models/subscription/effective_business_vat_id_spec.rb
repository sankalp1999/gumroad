# frozen_string_literal: true

require "spec_helper"

describe Subscription, :vcr do
  include ManageSubscriptionHelpers

  context "#effective_business_vat_id" do
    it "returns nil when no VAT ID exists on original purchase or refunds" do
      setup_subscription_with_vat

      expect(@subscription.effective_business_vat_id).to be_nil
    end

    it "returns VAT ID from original purchase when present" do
      allow_any_instance_of(VatValidationService).to receive(:process).and_return(true)
      setup_subscription_with_vat(vat_id: "FR123456789")

      expect(@subscription.effective_business_vat_id).to eq("FR123456789")
    end

    it "returns VAT ID from VAT-only refund when original purchase had none" do
      allow_any_instance_of(VatValidationService).to receive(:process).and_return(true)
      setup_subscription_with_vat

      @subscription.original_purchase.process!(off_session: false)
      expect(@subscription.original_purchase.gumroad_tax_cents).to be > 0

      @subscription.original_purchase.refund_gumroad_taxes!(
        refunding_user_id: @user.id,
        note: "Auto VAT",
        business_vat_id: "IE6388047V"
      )

      expect(@subscription.effective_business_vat_id).to eq("IE6388047V")
    end
  end
end
