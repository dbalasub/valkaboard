class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_listing, only: [:new, :create, :show, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_filter :check_buyer, only: [:edit, :update, :destroy, :create]

  def sales
    @orders =  Order.all.where(seller: current_user).order("created_at DESC")
  end

  def purchases
    @orders =Order.all.where(buyer: current_user).order("created_at DESC")
  end

  

  # GET /orders/new
  def new
    @order = Order.new
    #@listing = Listing.find(params[:listing_id])
  end

  

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)
    @order.buyer_id = current_user.id
    
    #@listing = Listing.find(params[:listing_id])

    @seller = @listing.user
    @order.listing_id = @listing.id
    @order.seller_id = @seller.id
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    token = params[:stripeToken]

    begin
      charge = Stripe::Charge.create(
        :amount => (@listing.price * 100).floor,
        :currency => "usd",
        :card => token
        )
      flash[:notice] = "Thanks for ordering!"
    rescue Stripe::CardError => e
      flash[:danger] = e.message
    end
    respond_to do |format|
      if @order.save
        format.html { redirect_to root_url, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_listing
      @listing = Listing.find(params[:listing_id])
    end
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:address, :city, :state, :listing_id)
    end
    def check_buyer
      if current_user == @listing.user
        redirect_to root_url, alert: "Sorry, can't buy your own listing"
      end
    end
end
