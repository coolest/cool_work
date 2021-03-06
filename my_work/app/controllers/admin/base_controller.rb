class Admin::BaseController < ApplicationController
  before_filter :admin_required

  def index
    @tab = 'current'
    session[:tab] = request.url
    @serviced_zips = ServicedZip.find(:all, :order => :zip)
    @windows = Window.find_all_regular
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')
    params[:sort] ? sort = params[:sort] : sort = 'id'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end
    @orders = Order.current_orders(zip, window, date, sort).paginate :page => params[:page], :per_page => 9
    @total_orders = Order.all_current_orders
  rescue Exception
    @orders = Order.current_orders(zip, window, nil).paginate :page => params[:page], :per_page => 9
    flash[:error] = 'Invalid date'
    redirect_to "/admin"
  end
  
  def pending
    session[:tab] = request.url
    @tab = 'pending'
    @serviced_zips = ServicedZip.find(:all, :order => :zip, :limit => 20)
    @windows = Window.find_all_regular
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')
    params[:sort] ? sort = params[:sort] : sort = 'updated_at'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end
    @orders = Order.pending_orders(zip, window, date, sort).paginate :page => params[:page], :per_page => 9
    @total_orders = Order.all_pending_orders
    render :template => 'admin/base/index'
    rescue Exception
      @orders = Order.pending_orders(zip, window, nil).paginate :page => params[:page], :per_page => 9
      flash[:error] = 'Invalid date'
#     redirect_to "pending"
  end
  
  def complete
      session[:tab] = request.url
    @tab = 'complete'
    @serviced_zips = ServicedZip.find(:all, :order => :zip, :limit => 20)
    @windows = Window.find_all_regular
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')
    params[:sort] ? sort = params[:sort] : sort = 'updated_at'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end
    @orders = Order.complete_orders(zip, window,  date, sort).paginate :page => params[:page], :per_page => 9
    @total_orders = Order.all_complete_orders
    render :template => 'admin/base/index'
    rescue Exception
      @orders = Order.complete_orders(zip, window, nil).paginate :page => params[:page], :per_page => 9
      flash[:error] = 'Invalid date'
#     redirect_to "/complete"
  end
  
  def cancelled
    @tab = 'cancelled'
    @serviced_zips = ServicedZip.find(:all, :order => :zip, :limit => 20)
    @windows = Window.find_all_regular
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')
    params[:sort] ? sort = params[:sort] : sort = 'updated_at'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end
    @orders = Order.cancelled_orders(zip, window,  date, sort).paginate :page => params[:page], :per_page => 9
    @total_orders = Order.all_cancelled_orders
    render :template => 'admin/base/index'
    rescue Exception
      @orders = Order.cancelled_orders(zip, window, nil).paginate :page => params[:page], :per_page => 9
      flash[:error] = 'Invalid date'
#     redirect_to "/cancelled"
  end
  
  def missed_pickup
    @tab = 'missed_pickup'
    @serviced_zips = ServicedZip.find(:all, :order => :zip, :limit => 20)
    @windows = Window.find_all_regular
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')
    params[:sort] ? sort = params[:sort] : sort = 'updated_at'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end
    @orders = Order.missed_pickup(zip, window,  date, sort).paginate :page => params[:page], :per_page => 9
    @total_orders = Order.all_missed_pickup_orders
    render :template => 'admin/base/index'
    rescue Exception
      @orders = Order.missed_pickup(zip, window, nil).paginate :page => params[:page], :per_page => 9
      flash[:error] = 'Invalid date'
#     redirect_to "/missed_pickup"
  end
  
  def missed_delivery
    @tab = 'missed_delivery'
    @serviced_zips = ServicedZip.find(:all, :order => :zip, :limit => 20)
    @windows = Window.find_all_regular
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')
    params[:sort] ? sort = params[:sort] : sort = 'updated_at'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end
    @orders = Order.missed_delivery(zip, window,  date, sort).paginate :page => params[:page], :per_page => 9
    @total_orders = Order.all_missed_delivery_orders
    render :template => 'admin/base/index'
    rescue Exception
      @orders = Order.missed_delivery(zip, window, nil).paginate :page => params[:page], :per_page => 9
      flash[:error] = 'Invalid date'
#     redirect_to "/missed_delivery"
  end
  
  def change_state
    state = params[:state]
    order = Order.find(params[:order])
    success = true
    if state == 'current'
      order.status = 'awaiting pickup'
    elsif state == 'picked up'
      order.verify_all!
    elsif state == 'pending'
      order.verify_all!
      success = order.finalize!
    elsif state == 'complete'
      success = order.delivered!
    elsif state == 'missed pickup'
      order.status = 'missed pickup'
    elsif state == 'missed delivery'
      order.status = 'missed delivery'
    end
    
    if success && order.save!
      flash[:notice] = "Order state changed"
    else
      flash[:error] = "There was a problem in completing that task"
    end
    redirect_to :back
  end
  
  def customer_notes
    zip = params[:zip].blank? ? nil : params[:zip]
    window = params[:window].blank? ? nil : params[:window]
    date = params[:date].blank? ? nil : Date.strptime(params[:date], '%d/%m/%Y')  
    params[:sort] ? sort = params[:sort] : sort = 'updated_at'
    if params[:orderby] && !params[:orderby].empty?
      sort = sort + " #{params[:orderby]}"
      params[:orderby] == 'desc' ? @orderby = 'asc' : @orderby = 'desc'
    else
      sort = sort + " desc"
      @orderby = 'asc'
    end    
    @serviced_zips = ServicedZip.find(:all, :order => :zip, :limit => 20)
    @windows = Window.find_all_regular  
    @orders = Order.order_for_notes(zip, window, date, sort).paginate :page => params[:page], :per_page => 9    
    rescue Exception
      @orders = Order.current_orders(zip, window, nil).paginate :page => params[:page], :per_page => 9
      flash[:error] = 'Invalid date'
      redirect_to "/admin/base/customer_notes"    
  end
    
  
end
