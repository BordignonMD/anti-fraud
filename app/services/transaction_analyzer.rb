# frozen_string_literal: true

class TransactionAnalyzer
  def initialize(transaction)
    @transaction = transaction
  end

  def analyze
    return approve_transaction if @transaction.has_cbk
    return handle_excessive_transactions if excessive_transactions?
    return handle_amount_limit_exceeded if amount_limit_exceeded?
    return handle_previous_chargeback if user_has_previous_chargeback?

    approve_transaction
  end

  private

  def excessive_transactions?
    same_user_or_device_with_recent_transactions?
  end

  def amount_limit_exceeded?
    transaction_above_limit?
  end

  def user_has_previous_chargeback?
    Transaction.where(user_id: @transaction.user_id, has_cbk: true).exists?
  end

  def handle_excessive_transactions
    deny_transaction(I18n.t('transactions.excessive_transactions'))
  end

  def handle_amount_limit_exceeded
    deny_transaction(I18n.t('transactions.amount_limit_exceeded'))
  end

  def handle_previous_chargeback
    deny_transaction(I18n.t('transactions.previous_chargeback'))
  end

  def approve_transaction
    @transaction.approved = true
    'approve'
  end

  def deny_transaction(reason)
    @transaction.rejection_reason = reason
    @transaction.approved = false
    'deny'
  end

  def same_user_or_device_with_recent_transactions?
    recent_transactions = Transaction
                          .where('user_id = ? OR device_id = ?', @transaction.user_id, @transaction.device_id)
                          .where('ABS(EXTRACT(EPOCH FROM transaction_date - ?)) < 60', @transaction.transaction_date)
                          .where.not(id: @transaction.id)
    recent_transactions.exists?
  end

  def transaction_above_limit?
    amount_limit = ENV.fetch('TRANSACTION_AMOUNT_LIMIT', 1000).to_i
    recent_transactions_amount = Transaction.where(user_id: @transaction.user_id)
                                            .where('transaction_date > ?', time_limit_for_period)
                                            .where.not(id: @transaction.id)
                                            .sum(:transaction_amount)
    (recent_transactions_amount + @transaction.transaction_amount.to_f) > amount_limit
  end

  def time_limit_for_period
    ENV.fetch('TRANSACTION_PERIOD', 24.hours).to_i.seconds.ago
  end
end
