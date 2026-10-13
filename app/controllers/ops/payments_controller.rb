module Ops
  class PaymentsController < BaseController
    def update
      payment = Payment.find(params[:id])
      payment.update!(params.expect(payment: [ :status ]))
      redirect_back_or_to ops_root_path
    end
  end
end
