# frozen_string_literal: true

require "spec_helper"

describe ServiceMailer do
  describe "service_charge_receipt" do
    it "renders properly" do
      user = create(:user)
      recurring_service = create(:recurring_service, user:, price_cents: 1000, recurrence: :monthly)
      service_charge = create(:service_charge, user:, recurring_service:)
      mail = ServiceMailer.service_charge_receipt(service_charge.id)
      expect(mail.subject).to eq "Gumroad — Receipt"
      expect(mail.to).to eq [user.email]
      expect(mail.body).to include "Thanks for continuing to support Gumroad!"
      expect(mail.body).to include "you'll be charged at the same rate."
    end
  end
end
