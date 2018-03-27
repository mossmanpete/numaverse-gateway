class AccountsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update, :attach_transaction]
  before_action :authenticate_user!, except: [:show]
  before_action :load_account

  def show
    @messages = @account.messages.visible.order('created_at desc').page(params[:page])
    respond_to do |format|
      format.html { }
      format.json { render 'show', locals: { account: @account }}
    end   
  end

  def update
    authorize! :manage, @account
    if @account.update(account_params)
      @account.post_on_ipfs
      render json: { ipfs_hash: @account.ipfs_hash }
    else
      render json: { errors: @account.errors.full_messages }, status: :error
    end
  end

  def attach_transaction
    authorize! :manage, @account
    attach_transaction_to(@account)
  end

  def edit
    authorize! :manage, @account
  end

  def transfer
    account = current_account
    if params[:message_id]
      @message = Message.find(params[:message_id])
      @tip = account.tip(@account, params[:amount].to_i, @message)
      @transaction = @tip.tx
    else
      @transaction = account.transfer(@account, params[:amount].to_i)
    end
  end

  private

  def account_params
    params.require(:account).permit(:username, :display_name, :bio, :location, :avatar_ipfs_hash)
  end

  def load_account
    id = params[:id]
    if id.starts_with?('0x')
      @account = Account.make_by_address(id)
    else
      @account = Account.find_by(id: id) || Account.find_by(username: id)
    end
    if @account.blank?
      raise ActiveRecord::RecordNotFound.new("Couldn't find account with id: #{id}")
    end
  end

end