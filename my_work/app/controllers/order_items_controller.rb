class OrderItemsController < ApplicationController
  require_role "intake"
  
  def new
    @order = Order.find(params[:o_id])
    @service = Service.find(params[:s_id])
    @item = OrderItem.new(:order => @order, :service => @service)
    @customer_item = CustomerItem.new()
    
     respond_to do |format|
      format.html # new.html.erb
      format.js   { render :action => "new.html.erb", :layout => false }
    end
  end
  
  def create
    @customer_item = CustomerItem.new(params[:customer_item])
    @customer_item.service_id = params[:order_item][:service_id]
    @item = OrderItem.new(params[:order_item])
    @customer_item.customer = @item.order.customer 
    price = Price.find(:first, :conditions=> ["item_type_id = ? AND service_id = ?", params[:customer_item][:item_type_id], params[:order_item][:service_id]])
    is_premium = ( @customer_item.premium || @item.order.premium )
    @customer_item.plant_price = price.get_plant_price(is_premium, @item.weight)
    @item.customer_item = @customer_item 
    @item.price = ItemType.find(params[:customer_item][:item_type_id]).name == 'Miscellaneous' ? params[:order_item][:price] : nil 
    if @item.save
      flash[:notice] = 'Item was successfully created.'
    end
    redirect_to :back
  end
  
  def update
    @item = OrderItem.find(params[:id])
    if @item.update_attributes(params[:order_item]) && @item.customer_item.save! 
      price = Price.find(:first, :conditions=> ["item_type_id = ? AND service_id = ?", @item.customer_item.item_type_id, @item.service_id])
      is_premium = ( @item.customer_item.premium || @item.order.premium || @item.premium )
      @item.customer_item.update_attribute(:plant_price, price.get_plant_price(is_premium, @item.weight) )
      @item.instructions.save! if @item.instructions
      @item.assign_tracking_number!
      @item.verify!
      flash[:notice] = 'Item was successfully updated.'
    end
    redirect_to :back
  end
  
  def destroy
    @item = OrderItem.find(params[:id])
    @item.destroy

    flash[:notice] = 'Item was successfully deleted.'
    redirect_to :back
  end

  def update_extra_charge
    @item = CustomerItem.find(params[:c_id])
    params[:customer_item][:extra_charge] = 0.00 if params[:customer_item][:extra_charge].blank?
    if @item.update_attributes(params[:customer_item])
      flash[:notice] = 'Item was successfully updated.'
    end
    redirect_to :back
  end

  def edit_extra_charge
    @item = OrderItem.find(params[:o_id]).customer_item
    render :layout => false
  end
end
