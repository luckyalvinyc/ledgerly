# frozen_string_literal: true

class TransactionsController < CustomerController
  include PeriodScoped

  def update
    @transaction = current_user.transactions.find(params[:id])
    @transaction.update!(transaction_params)

    load_statement(@transaction.bank_account)
  end

  private

    def transaction_params
      params.expect(transaction: [ :included ])
    end
end
