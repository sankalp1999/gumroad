# frozen_string_literal: true

FactoryBot.define do
  factory :recurring_service do
    user
    price_cents { 1000 }
    recurrence { :monthly }
  end
end
