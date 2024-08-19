# frozen_string_literal: true

require 'csv'

# This controller manages transaction records, including import from CSV files,
# transaction analysis, and rendering results in different formats.
class TransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:analyze]

  def index
    @sort_column = params[:sort] || 'created_at'
    @sort_direction = params[:direction] || 'desc'
    @transactions = Transaction.order("#{@sort_column} #{@sort_direction}")

    @transactions = filter_transactions(@transactions)
    @transactions = @transactions.page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @transactions }
    end
  end

  def analyze
    matching_transaction = find_matching_transaction(transaction_params)

    if matching_transaction
      render_existing_transaction(matching_transaction)
    else
      handle_new_or_partial_match(Transaction.where(transaction_id: transaction_params[:transaction_id]))
    end
  end

  def import
    if params[:file].present?
      file = params[:file].tempfile
      import_csv(file)
      flash[:success] = 'Arquivo importado com sucesso!'
    else
      flash[:error] = 'Nenhum arquivo foi selecionado.'
    end
    redirect_to transactions_path
  end

  private

  def filter_transactions(transactions)
    transactions = transactions.where(status_conditions) if params[:filters].present?
    if params[:transaction_id].present?
      transactions = transactions.where('transaction_id::text LIKE ?', "%#{params[:transaction_id]}%")
    end
    transactions
  end

  def status_conditions
    conditions = []
    conditions << 'approved = true' if params[:filters].include?('approved')
    conditions << 'approved = false' if params[:filters].include?('denied')
    conditions += filter_by_rejection_reason(params[:filters])
    conditions.join(' OR ')
  end

  def filter_by_rejection_reason(filters)
    rejection_reasons = {
      'repeated' => 'existing_id',
      'excessive' => 'excessive_transactions',
      'amount_exceeded' => 'amount_limit_exceeded',
      'previous_chargeback' => 'previous_chargeback'
    }

    filters.map do |filter|
      reason_key = rejection_reasons[filter]
      next unless reason_key

      reason = I18n.t("transactions.#{reason_key}")
      "rejection_reason = '#{sanitize_sql(reason)}'"
    end.compact
  end

  def sanitize_sql(value)
    ActiveRecord::Base.connection.quote_string(value)
  end

  def transaction_params
    params.require(:transaction).permit(
      :transaction_id,
      :merchant_id,
      :user_id,
      :card_number,
      :transaction_date,
      :transaction_amount,
      :device_id,
      :has_cbk
    )
  end

  def import_csv(file)
    CSV.foreach(file.path, headers: true) do |row|
      transaction = Transaction.new(row.to_hash)
      recommendation = analyze_transaction(transaction)
      transaction.save if recommendation
    end
  end

  def analyze_transaction(transaction)
    matching_transaction = find_matching_transaction(transaction.attributes)

    if matching_transaction
      apply_existing_transaction_decision(transaction, matching_transaction)
    else
      apply_new_transaction_decision(transaction)
    end
  end

  def find_matching_transaction(transaction)
    transactions_with_same_id = Transaction.where(transaction_id: transaction[:transaction_id])
    transactions_with_same_id.find { |txn| transaction_details_match?(txn, transaction) }
  end

  def apply_existing_transaction_decision(transaction, matching_transaction)
    transaction.approved = matching_transaction.approved
    transaction.rejection_reason = matching_transaction.rejection_reason
    transaction.approved ? 'approve' : 'deny'
  end

  def apply_new_transaction_decision(transaction)
    TransactionAnalyzer.new(transaction).analyze
  end

  def handle_new_or_partial_match(transactions_with_same_id)
    if transactions_with_same_id.empty?
      transaction = Transaction.new(transaction_params)
      recommendation = apply_new_transaction_decision(transaction)
      save_and_render_transaction(transaction, recommendation)
    else
      transaction = create_transaction_with_rejection(I18n.t('transactions.existing_id'))
      render_denial(transaction.transaction_id, transaction.rejection_reason)
    end
  end

  def save_and_render_transaction(transaction, recommendation)
    if transaction.save
      render json: { transaction_id: transaction.transaction_id, recommendation: }
    else
      render json: { error: I18n.t('transactions.save_failure') }, status: :unprocessable_entity
    end
  end

  def render_existing_transaction(matching_transaction)
    render json: {
      transaction_id: matching_transaction.transaction_id,
      recommendation: matching_transaction.approved ? 'approve' : 'deny',
      rejection_reason: matching_transaction.rejection_reason
    }
  end

  def transaction_details_match?(existing_transaction, transaction)
    transaction_date_param = Time.parse(transaction['transaction_date']).utc

    merchant_matches?(existing_transaction, transaction) &&
      user_matches?(existing_transaction, transaction) &&
      card_matches?(existing_transaction, transaction) &&
      date_matches?(existing_transaction, transaction_date_param) &&
      amount_matches?(existing_transaction, transaction) &&
      device_matches?(existing_transaction, transaction)
  end

  def merchant_matches?(existing_transaction, transaction)
    existing_transaction.merchant_id == transaction['merchant_id'].to_i
  end

  def user_matches?(existing_transaction, transaction)
    existing_transaction.user_id == transaction['user_id'].to_i
  end

  def card_matches?(existing_transaction, transaction)
    existing_transaction.card_number == transaction['card_number']
  end

  def date_matches?(existing_transaction, transaction_date_param)
    existing_transaction.transaction_date.to_i == transaction_date_param.to_i
  end

  def amount_matches?(existing_transaction, transaction)
    existing_transaction.transaction_amount.to_d == transaction['transaction_amount'].to_d
  end

  def device_matches?(existing_transaction, transaction)
    existing_transaction.device_id == transaction['device_id'].to_i
  end

  def create_transaction_with_rejection(reason)
    transaction = Transaction.new(transaction_params)
    transaction.rejection_reason = reason
    transaction.approved = false
    transaction.save
    transaction
  end

  def render_denial(transaction_id, reason)
    render json: { transaction_id:, recommendation: 'deny', rejection_reason: reason }
  end
end
