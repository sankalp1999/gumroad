# frozen_string_literal: true

class RecurringService < ApplicationRecord
  include ExternalId
  include JsonData
  include DiscountCode

  belongs_to :user, optional: true
  has_many :charges, class_name: "ServiceCharge"
  has_one :latest_charge, -> { order(id: :desc) }, class_name: "ServiceCharge"

  enum recurrence: %i[monthly yearly]

  validates_presence_of :user, :price_cents
  validates_associated :user
end
