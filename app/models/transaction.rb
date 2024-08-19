# frozen_string_literal: true

class Transaction < ApplicationRecord
  def self.excessive_transactions?(user_id)
    where(user_id:).where('transaction_date > ?', 1.minute.ago).count >= 3
  end

  def self.high_value_transaction?(transaction_amount)
    transaction_amount > 10_000
  end

  def self.previous_chargeback?(user_id)
    where(user_id:, has_cbk: true).exists?
  end
end
