# # == Schema Information
# Schema version: 98
#
# Table name: orders
#
#  id                :integer(11)   not null, primary key
#  customer_id       :integer(11)   
#  count             :integer(11)   
#  shipping          :decimal(6, 2) 
#  delivery_type     :integer(11)   
#  created_at        :datetime      
#  updated_at        :datetime      
#  verified          :boolean(1)    
#  status            :string(255)   
#  amount            :decimal(8, 2) 
#  processed         :boolean(1)    
#  instructions_id   :integer(11)   
#  tracking_number   :string(255)   
#  recurring         :boolean(1)    
#  finalized         :boolean(1)    
#  tax               :decimal(9, 2) 
#  carbon_cost       :decimal(9, 2) 
#  water_cost        :decimal(9, 2) 
#  point_value       :integer(11)   
#  promotion_id      :integer(11)   
#  discount          :decimal(9, 2) default(0.0)
#  points_used       :integer(11)   default(0)
#  recycling         :boolean(1)    
#  clothing_donation :boolean(1)    
#  express           :boolean(1)    
#  free_shipping     :boolean(1)    
#

class Order < ActiveRecord::Base
  has_many :order_items, :dependent => :destroy
  has_many :requests, :dependent => :destroy
  has_many :order_parts, :dependent => :destroy
  has_many :order_products, :dependent => :destroy
  has_many :notes, :dependent => :destroy
  has_many :requests, :dependent => :destroy
  has_one :payment, :dependent => :destroy
  belongs_to :promotion
  belongs_to :customer
  belongs_to :instructions
  belongs_to :recurring_order  

  liquid_methods :identifier, :id, :customer, :tracking_number, :delivery_date, :pickup_date
  
  validates_presence_of :customer
  @@StatusMenu = ['awaiting pickup', 'delivered', 'in transit', 'processing', 'incomplete', 'missed pickup','missed delivery', 'cancelled', 'picked up', 'enroute to delivery']
  @@DonationValue = 25      #The number of points awarded if a clothing donation is included with the order.
  @@CashInInterval = 1000   #Fresh Cash will be awarded automatically when the customer accumulates this many points.
    

  def diff
    nil
  end
  
  def self.DonationValue
    @@DonationValue
  end
  def self.CashInInterval
    @@CashInInterval
  end
  
  def cancel
    if self.finalized
      Notifier.deliver_failed_cancellation(self)
      false
    else
      self.status = 'cancelled'
      Notifier.deliver_order_cancellation(self)
      true
    end 
  end
  
  def initialize(*params)
    super(*params)
    self.status = 'incomplete'
    self.verified = false
  end
  
  def take_order_item_snapshot
    @snapshot = OrderItem.find_all_by_order_id(50,:readonly => true)
  end
  def snapshot
    @snapshot
  end
  
  def validate
    if self.promotion
      unless self.promotion.available_for(self)
        errors.add_to_base("Promotion already used or expired.")
      end
    end
    #total = self.amount + self.shipping
    #total+self.tax if self.tax
    #if total < ORDER_MIN_PRICE 
      #errors.add_to_base("We're sorry but your order has not met the $30 min order requirement yet – The min order amount is simply to maximize fuel consumption and #efficiency")
      #return false
    #end
  end
  
  def self.create_eco(carbon, water, *params)
    o = Order.new(*params)
    if carbon > 0
      carbon_credit = Product.find_by_name('Carbon Credit')
      o.order_products << OrderProduct.create(:product => carbon_credit, :quantity => carbon, :price => carbon_credit.price)
    end
    if water > 0
      water_credit  = Product.find_by_name('Water Credit')
      o.order_products << OrderProduct.create(:product => water_credit, :quantity => water, :price => water_credit.price)
    end
    o.save!
    o
  end
  
  def has_purchased_carbon?
    carbon_credit = Product.find_by_name('Carbon Credit')
    val = self.order_products.find(:all, :conditions => {:product_id => carbon_credit.id})
    val.size > 0
  end
  
  def buy_carbon_credits(amt = self.carbon_footprint)
    carbon_credit = Product.find_by_name('Carbon Credit')
    self.order_products << OrderProduct.create(:product => carbon_credit, :quantity => amt, :price => carbon_credit.price)
  end
  
  def has_purchased_water?
    water_credit = Product.find_by_name('Water Credit')
    val = self.order_products.find(:all, :conditions => {:product_id => water_credit.id})
    val.size > 0
  end
  
  def buy_water_credits(amt = self.water_saved)
    water_credit  = Product.find_by_name('Water Credit')
    self.order_products << OrderProduct.create(:product => water_credit, :quantity => amt, :price => water_credit.price)
  end
  
  def est_water_price()
   (self.water_saved * Product.find_by_name('Water Credit').price).ceil(2)
  end
  
  def water_price()
   (self.water_cost * Product.find_by_name('Water Credit').price).ceil(2)
  end
  
  def est_carbon_price()
   (self.carbon_footprint * Product.find_by_name('Carbon Credit').price).ceil(2)
  end
  
  def carbon_price()
   (self.carbon_cost * Product.find_by_name('Carbon Credit').price).ceil(2)
  end
  
  def buy_product(name, qty)
    p = Product.find_by_name(name)
    self.order_products << OrderProduct.create(:product => p, :quantity => qty, :price => p.price)
  end
  
  def buy_garment_bags(qty)
    self.buy_product('Garment bag', qty)
  end
  
  def buy_laundry_bags(qty)
    self.buy_product('Laundry Bag', qty)
  end
  
  def buy_detergent(qty)
    self.buy_product('Detergent', qty)
  end
  
  def after_create
    self.tracking_number = self.create_tracking_number
    self.save!
  end
  
  def verify_all!
    for item in self.order_items
      item.assign_tracking_number!
      item.verify! if !item.verified?
    end
    self.remove_fresh_cash_to_referral()
    self.status = 'picked up'
  end
  
  def verify(tracking_no)
    order_item = OrderItem.find_by_tracking_number(tracking_no)
    if order_item.order.id == self.id:
      result = order_item.verify!
    end
    state = read_attribute(:verified)
    self.reload
    if self.verified_number == self.order_items.count
      write_attribute(:verified, true)
    else
      write_attribute(:verified, false) unless state == false
    end
    result
  end
  
  def verified?
    read_attribute(:verified)
  end
  def fully_verified?
    self.verified_number == self.order_items.count
  end
  
  def barcode
    self.tracking_number
  end
  
  # Number will increase as each item is scanned, until the total number of items are verified
  def verified_number
    self.order_items.find_all { |oi| oi.verified? }.length
  end
  
  def confirmed?
    confirmed_statuses = Order.StatusMenu - ['delivered','cancelled', 'incomplete']
    confirmed_statuses.include?(status)
  end
  
  # Orders to be shown on the admin intake page
  def self.intake_orders(sort=nil)
    sort != nil ? sort = "#{sort}, created_at desc" : sort = 'updated_at desc'
    #Order.find(:all, :conditions => ['status != ?', 'incomplete'], :order => sort)
    Order.find(:all, :conditions => ['status not in (?,?,?,?)', 'incomplete','awaiting pickup', 'cancelled', 'missed pickup'], :order => sort)
  end
  
  def self.intake_search(sort=nil,search=nil)
    if search
      cids = User.find(:all, :select => 'account_id', :conditions => ['(last_name LIKE ? or first_name LIKE ?) AND account_id IS NOT NULL', "%#{search}%", "%#{search}%"])
      c = []
      for cid in cids
        c << cid.account_id
      end
      Order.find(:all, :conditions => ["customer_id in (#{c.join(',')})"], :order => sort) unless c.blank?
    end
  end
  
  def self.newest_orders(how_many = 10, for_customer = nil)
    if for_customer
      for_customer = ['status != ? AND customer_id = ?', 'incomplete', for_customer]
    else
      for_customer = ['status != ?', 'incomplete']
    end
    Order.find(:all, 
               :conditions => for_customer,
               :order => 'id DESC', :limit => how_many)
  end
  
  # Following 3 methods get passed :
  # "" for all zips or an id
  # "" for all windows or an id
  # "" for all dates or a date
  # We don't really have the concept of orders in zipcodes, or windows, or dates...  Those only apply if an order is scheduled.
  # These also risk being really big and really slow... especially if date is ignored.
  def self.current_orders(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), Order.StatusMenu - ['delivered', 'processing', 'incomplete', 'cancelled', 'missed pickup', 'missed delivery'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
    list
  end

  def self.pending_orders(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), Order.StatusMenu - ['delivered','awaiting pickup', 'incomplete', 'cancelled','missed pickup', 'missed delivery', 'picked up'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
    add_sorting_to_order_list(list)
  end
  
  def self.complete_orders(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), ['delivered'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
    list
  end
  
  def self.cancelled_orders(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), ['cancelled'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
    list
  end
  
  def self.missed_pickup(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), ['missed pickup'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
    list
  end
  
  def self.missed_delivery(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), ['missed delivery'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
    list
  end
  
  def self.order_for_notes(zip_id = nil, window_id = nil, date = nil, sort='updated_at')
    list = Order.find(:all,
                      :conditions => [['orders.status IN (?)', window_id ? 'stops.window_id = ?':nil, date ? 'stops.date = ?':nil].compact.join(' AND '), Order.StatusMenu - ['delivered', 'processing', 'incomplete', 'cancelled', 'missed pickup', 'missed delivery'], window_id, date].compact,
    :joins      => [window_id, date].any? ? 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id' : '',
    :order => "#{sort}"
    ).uniq
    if zip_id
      zip = ServicedZip.find(zip_id).zip
      list = list.select{|o| o.customer.primary_address.zip == zip}
    end
      list = list.select{|o| !(o.notes.blank?)}
    list
  end  
  
  def self.all_current_orders
    Order.find(:all,:conditions => ['status in (?,?)','awaiting pickup','picked up'])
  end

  def self.all_pending_orders
    Order.find(:all,:conditions => ['status in (?)','processing'])
  end

  def self.all_complete_orders
    Order.find(:all,:conditions => ['status in (?)','delivered'])
  end

  def self.all_cancelled_orders
    Order.find(:all,:conditions => ['status in (?)','cancelled'])
  end

  def self.all_missed_pickup_orders
    Order.find(:all,:conditions => ['status in (?)','missed pickup'])
  end

  def self.all_missed_delivery_orders
    Order.find(:all,:conditions => ['status in (?)','missed delivery'])
  end
  
  def identifier
    self.tracking_number
  end
  
  def classes
    self.items.collect{|i| i.service.nil? ? '' : i.service.name}.uniq
  end
  
  def promotion_code
    return self.promotion.code if self.promotion
    return ''
  end
  def promotion_code=(code)
    self.promotion = Promotion.find_by_code(code)
    self.promotion.apply_to(self) if self.promotion
  end
  
  def express?
    express  
  end
  
  def address
    self.customer.primary_address
  end
  
  def premium?
    premium
  end
  
  def special_handling?
    !special_instructions.nil?
  end
  
  def items
    self.order_items
  end
  
  def processed?
    self.processed
  end
  
  def total
    return false unless self.finalized
    self.amount.round(2) + self.tax.round(2) + self.shipping.round(2)
  end
  
  def finalize!
    success = false
    if self.payment && self.payment.credit_card 
      self.processed  = true
      self.finalized = true
      self.status = 'processing'
      self.save
      success = self.payment.credit_card.authorize(self)

      if !success
        self.finalized = false
        self.processed  = false
        self.save
      end
    end
    if success
      if self.fully_verified?
        self.verified!
      end
    end
    return success
  end
  
  def estimated_shipping_amount
    self.shipping
  end
    
  def estimated_amount
#    if premium
#      itemtotal = self.order_items.collect {|item| item.premium}.sum
#    else
#      itemtotal = self.order_items.collect {|item| item.price}.sum
#    end
    #puts ">>>>>>>>>>>>>>item total" + itemtotal.to_s
    bag_prices = self.order_products.collect {|product| product.price * product.quantity}.sum
    bag_tax = bag_prices* 0.09
    itemtotal = self.order_items.collect {|item| item.price}.sum 
    if self.is_referred?
      itemtotal = itemtotal.to_f * 0.85
    end
    amount = itemtotal + self.estimated_shipping_amount + bag_prices + bag_tax
    amount = amount + ((amount > 0 && express?) ? 0.25 * amount : 0.00) - self.discount.to_f - self.fresh_cash_used.to_f
  end
  
  def amount
#    if premium
#      itemtotal = self.order_items.collect {|item| item.premium}.sum
#    else
    itemtotal = self.order_items.collect {|item| item.price}.sum
    if self.is_referred?
      itemtotal = itemtotal.to_f * 0.85
    end
#    end
    bag_prices = self.order_products.collect {|product| product.price * product.quantity}.sum
    bag_tax = bag_prices* 0.09
    @amount = itemtotal + CustomerItem.sum("extra_charge", :include => [:order_item], :conditions => ["order_items.order_id = ?", self.id]).to_f + bag_tax + bag_prices
    markup = (@amount > 0 && express?) ? 0.25 * @amount : 0.00
     (@amount + markup) - self.discount.to_f - self.fresh_cash_used.to_f
  end

  def is_referred?
      user = self.customer.account
      !Invitation.find_by_recipient_email(user.email).blank? && ( user.created_at + 1.month ) > self.created_at && self.promotion_code != "FREETRIAL"
  end

  def finalized
    read_attribute(:finalized)
  end
  def finalized=(val)
    if val == true
      self.tax = 0.0# * self.amount
#       self.customer.points += self.eco_points
      write_attribute(:point_value, self.eco_points)
      write_attribute(:water_cost, self.water_saved)
      write_attribute(:carbon_cost, self.carbon_footprint)
    end
    write_attribute(:finalized, val)
    self.promotion.apply_to(self) if self.promotion
  end
  
  def delivery_date
    self.requests.each do |request|
      if request.for_delivery?
        return request.stop.date
      end
    end
    # "Order is not scheduled for delivery."
    nil
  end
  
  def pickup_date
    self.requests.each do |request|
      if request.for_pickup?
        return request.stop.date
      end
    end
    # "Order is not scheduled for pickup."
    nil
  end
  
  # TODO I'm not sure what method "route" is supposed to do.  Right now it's returning the serviced_zip of the primary_address of the customer.
  def route
    self.customer.primary_address.building.zip
  end
  
  # count(wash and folds)
  def total_bundles
    self.items.collect {|item| item if !item.is_itemizeable? }.compact.size
  end
  
  # count(all other)
  def total_pieces
    self.items.collect {|item| item if item.is_itemizeable? }.compact.size
  end
  
  def special_instructions
    self.instructions
  end
  
  def instruction_notes
    self.items.collect {|n| n.instructions.text if n.instructions}
  end
  
  def payment_status
    if self.payment
      self.payment.status
    else
      "Unpaid"
    end
  end
  
  def pickup_time(window_edge = :start) #for window_edge in {:start, :end}
    return self.pickup.stop.window.start if window_edge == :start
    return self.pickup.stop.window.end if window_edge == :end
    return nil
  end
  
  def delivery_time
    self.delivery.stop.window.start if self.delivery 
  end
  
  def pickup_window
    self.pickup.stop.window if self.pickup
  end
  
  def delivery_window
    self.delivery.stop.window if self.delivery 
  end
  
  def pickup
    self.requests.each do |request|
      if request.for_pickup?
        return request
      end
    end
    return nil
  end
  
  def delivery
    self.requests.each do |request|
      if request.for_delivery?
        return request
      end
    end
    return nil
  end
  
  def has_service?(service)
    for item in order_items
      if item.service == service
        return true
      end
    end
    false
  end
  
  def has_items_of_type?(service)
    for item in order_items
      if item.customer_item.item_type.has_service?(service)
        return true
      end
    end
    return false
  end
  
  def items_from_type(item_type, service_id)
    type_items = []
    for item in order_items
      if item.customer_item.item_type == item_type && ( item.customer_item.service_id == service_id || item.customer_item.service_id.blank? )
        type_items << item
      end
    end
    type_items
  end

  def services_for_order
    service_type = []
    for item in order_items
      if service_type.index(item.service).nil?
        service_type << item.service
      end
    end
    service_type
  end
  
  def service_in_order(service)
    order_item = []
    for item in order_items
      if service.id == item.service_id
        order_item << item
      end
    end
    order_item
  end
  
  def delivered!
    if self.payment && self.payment.credit_card && self.total && !self.requests.find(:all, :conditions=>["requests.for = 'delivery'"]).blank?
      self.status = 'delivered'
      self.award_points
      for item in self.order_items
        item.move_to(nil)
        item.bin = nil
        item.stand = nil
        item.status = 'delivered' unless ['missing'].include? item.status
      end
      self.payment.credit_card.capture(self)
      self.fresh_cash_to_referral()
      self.give_point_for_green_selected_window if self.green_leaf_pickup == 1 
      self.green_leaf_pickup = 0
      self.give_point_for_green_selected_window if self.green_leaf_delivery == 1
      self.green_leaf_delivery = 0
      if self.eco_status != 0
        self.give_eco_points if self.donations
        self.give_eco_points if self.recycling
        self.give_eco_points if self.clothing_donation
        self.give_fifty_eco_points if self.hangers
        #self.give_fresh_cash_for_eco_points()
        self.eco_status = 0
      end
      if Order.find(:all,:conditions=>["recurring = ? and status = ? and customer_id = ? ",1,'delivered',self.customer_id]).size == 4
        self.give_fifty_eco_points
        self.give_fifty_eco_points
        self.give_fresh_cash_for_eco_points
      end
      return self.payment && self.save!
    else
      self.fresh_cash_to_referral()
      return false
    end
  end
  
  def green? (request)
    return !self.pickup.takes_slot if request == :pickup
    return !self.delivery.takes_slot if request == :delivery
    return nil
  end
  
  # TODO This doesn't seem to be getting called
  def green
    if self.green?(:pickup) and self.green?(:delivery)
      return "both"
    elsif self.green?(:pickup)
      return "pickup only"
    elsif self.green?(:delivery)
      return "delivery only"
    else
      return "false"
    end
  end
  
  # TODO
  def eco_points
    self.order_items.collect { |i| i.point_value || 0}.sum
  end
  
  def carbon_footprint
    self.order_items.collect { |i| i.carbon_cost if i.carbon_cost > 0 || 0}.sum + self.order_products.collect { |p| p.carbon_cost if p.carbon_cost > 0 || 0}.sum
  end
  
  def water_saved
    self.order_items.collect { |i| i.water_cost if i.water_cost > 0 || 0}.sum + self.order_products.collect { |p| p.water_cost if p.water_cost > 0 || 0}.sum
  end
  
  def carbon_offset
    self.order_items.collect { |i| (i.carbon_cost if i.carbon_cost < 0) || 0}.sum + self.order_products.collect { |p| (p.carbon_cost if p.carbon_cost < 0) || 0}.sum
  end
  
  def water_donated
    self.order_items.collect { |i| (i.water_cost if i.water_cost < 0) || 0}.sum + self.order_products.collect { |p| (p.water_cost if p.water_cost < 0) || 0}.sum
  end
  
  def paid?
    self.payment && self.payment.paid?
  end
  
  def delinquent?
    self.payment && self.payment.delinquent?
  end
  
  def approved?
    self.payment && self.payment.credit_card
  end
  
  def authorized?
    self.payment && self.payment.authorized?
  end
  
  def self.StatusMenu
    @@StatusMenu
  end
  
  def award_points
    unless self.points_awarded
      #      TODO Line below caused no method error
      #      self.customer.points += self.points
#       self.customer.points = self.customer.points + Order.DonationValue if self.clothing_donation
      self.customer.cash_in_points(Order.CashInInterval) if self.customer.points >= Order.CashInInterval
      self.customer.save!
      self.update_attribute(:points_awarded, true)
      true
    else
      false
    end
  end
  
  def create_tracking_number
    self.customer.id.to_s.rjust(7,"0") + self.id.to_s.rjust(8, "0")
  end
  
  def shipping
    if self.free_shipping or self.customer.free_shipping
      ship = 0.00
    elsif self.order_items == [] && !self.order_products.collect { |p| false if p.id > 2 }.any?
      ship = 0.00
    else   
      ship = 4.95
    end
    
    return ship
  end
  
  def shipping=(val)
    write_attribute(:shipping, val)
  end
  
  def earliest_deliverable(date = nil)
    date = self.pickup.stop.date if date == nil    
    if date.wday == 5
      return date + 4.days
    elsif date.wday == 6 or date.wday == 0
      return date + 3.days
    else
      return date + 2.days
    end
  end
  
  # earliest pickups should be the next day between 00:00 and 23:00 and the following day if between 23:00 and 23:59:59
  def earliest_pickup_date()
   ((Time.now  - (60*60*4)) + 25.hours).to_date
  end
  
  def express_delivery_schedule(location = nil, date = nil, start_time = nil)
    # puts ServicedZip.find_by_zip(self.customer.primary_address.zip).zip
    location = ServicedZip.find_by_zip(self.customer.primary_address.zip).location if location == nil
    date = self.pickup.stop.date if date == nil
    puts "date: #{date}, #{start_time}, #{date.tomorrow.tomorrow}"
    if start_time.to_i < 10
      # puts "Gettings schedule for " + location.to_s + " on " + Date.today.to_s, location
      s = Schedule.for_week_of(location, date.tomorrow, nil)
      s[0].stops.delete_if do |stop|
        stop.window.start.hour < 0
      end
    elsif
      # puts "after 10"
      s = Schedule.for_week_of(location, date.tomorrow.tomorrow, nil)
      # puts s
      s[0].stops.delete_if do |stop|
        stop.window.start.hour < 6
      end
    end
    s[0]
  end
  
  def verified!
    raise Exception unless self.fully_verified?
    #select distinct services from the order
    services = Service.find(:all,
                            :conditions => ['order_items.order_id = ?', self.id],
    :joins => 'INNER JOIN order_items ON order_items.service_id = services.id'
    ).uniq!
    
    if !services.nil?
      services.each do |s|
        #for each service, create an order part and for each order part, 
        op = OrderPart.new(:service => s, :order => self, :status => "verified", :position => nil, :order_items => self.items.collect {|i| i if i.service == s}.compact.flatten)
        self.order_parts << op
      end
    end
    
    self.status = 'processing'
    self.award_points
    self.save!
  end
  
  def make_recurring(interval)
    parent_recurring_order.destroy if parent_recurring_order
    num_days = 7  if interval == :weekly
    num_days = 14 if interval == :two_weeks
#     num_days = 21 if interval == :three_weeks
    num_days = 28 if interval == :four_weeks
    self.recurring = true
    if self.pickup && self.delivery
      RecurringOrder.create(
                            :address => self.customer.primary_address,
                            :pickup_time => self.pickup.stop.window_id,
                            :delivery_time => self.delivery.stop.window_id,
                            :interval => num_days,
                            :pickup_day => self.pickup.stop.date.wday,
                            :delivery_day => self.delivery.stop.date.wday,
                            :customer => self.customer,
                            :last_order_id => self.id)

      self.recurring_order_id = RecurringOrder.last.id
    end
      self.save
  end
  
  def parent_recurring_order
    RecurringOrder.find(:first, :conditions => {:last_order_id => self.id})
  end
  
  def self.find_todays_intake
    Order.find(:all,
               :conditions => ['requests.type = "pickup" AND stops.date = ?', Date.today],
    :joins => 'INNER JOIN requests ON requests.order_id = orders.id INNER JOIN stops ON requests.stop_id = stops.id'
    )
  end
  
  def self.average_carbon_purchase(over_last_n = 5000)
    OrderProduct.average(:quantity, :conditions => ['product_id = ? AND quantity < 0', Product.find_by_name('Carbon Credit')], :order => 'id DESC', :limit => over_last_n)
  end
  
  def self.average_water_purchase(over_last_n = 5000)
    OrderProduct.average(:quantity, :conditions => ['product_id = ? AND quantity < 0', Product.find_by_name('Water Credit')], :order => 'id DESC', :limit => over_last_n)
  end
  
  def fresh_cash_to_referral()
    if self.customer.user.referrer != nil and self.promotion_code == 'FREETRIAL' and Order.find(:all, :conditions=>["customer_id = ? AND status = 'delivered'", self.customer_id]).size == 0
      referrer = Customer.find_by_id(User.find_by_id(self.customer.user.referrer).account_id)
      referrer.fresh_cash += 20
      referrer.save!
    end
  end

   def give_eco_points
    @customer = Customer.find(self.customer_id)
    @customer.points = @customer.points.to_i+25
    @customer.save
  end
  
  def give_fifty_eco_points
    @customer = Customer.find(self.customer_id)
    @customer.points = @customer.points.to_i+50
    @customer.save
  end

  #def give_fresh_cash_for_eco_points
  #  @customer = Customer.find(self.customer_id)
  #  if @customer.points >=5000 
  #    @customer.points = @customer.points - 5000
  #    @customer.fresh_cash = @customer.fresh_cash.to_i+500
  #    @customer.save
  #  end
  #  if @customer.points >=2000 and @customer.points<5000 
  #    @customer.points = @customer.points - 2000
  #    @customer.fresh_cash = @customer.fresh_cash.to_i+200
  #    @customer.save
  #  end
  #  if @customer.points >=1000 and @customer.points<2000 
  #    @customer.points = @customer.points - 1000
  #    @customer.fresh_cash = @customer.fresh_cash.to_i+100
  #    @customer.save
  #  end
  #  if @customer.points >=500 and @customer.points<1000 
  #    @customer.points = @customer.points - 500
  #    @customer.fresh_cash = @customer.fresh_cash.to_i+50
  #    @customer.save
  #  end
  #end

   def give_point_for_green_leaf_pickup(selected_date,gren_leaf_array)
    gren_leaf_array_split = gren_leaf_array.split("==") 
    if gren_leaf_array_split.include?("#{selected_date}")
      self.green_leaf_pickup = 1
    end
  end

  def give_point_for_green_leaf_delivery(selected_date,gren_leaf_array)
    gren_leaf_array_split = gren_leaf_array.split("==") 
    if gren_leaf_array_split.include?("#{selected_date}")
      self.green_leaf_delivery = 1
    end
  end
  
  def take_point_for_green_leaf_pickup(selected_date,gren_leaf_array)
    gren_leaf_array_split = gren_leaf_array.split("==") 
    unless gren_leaf_array_split.include?("#{selected_date}")
      self.green_leaf_pickup = 0
    end
  end
  
  def take_point_for_green_leaf_delivery(selected_date,gren_leaf_array)
    gren_leaf_array_split = gren_leaf_array.split("==") 
    unless gren_leaf_array_split.include?("#{selected_date}")
      self.green_leaf_delivery = 0
    end
  end
  
  def give_point_for_green_selected_window
     @customer = Customer.find(self.customer_id)
     @customer.points = @customer.points.to_i+25 
     @customer.save
  end

  def remove_fresh_cash_to_referral()
    if self.customer.user.referrer != nil and self.promotion_code == 'FREETRIAL' and Order.find(:all, :conditions=>["customer_id = ? AND status = 'delivered'", self.customer_id]).size == 1
      referrer = Customer.find_by_id(User.find_by_id(self.customer.user.referrer).account_id)
      referrer.fresh_cash -= 20
      if referrer.fresh_cash < 0.00
          order_with_fcash = Order.find(:all , :conditions => ["customer_id = ? AND status IN ('picked up', 'awaiting pickup') AND fresh_cash_used > 0.00", referrer.id], :order => "id DESC")
          fresh_cash = referrer.fresh_cash
          referrer.fresh_cash = 0.00
          unless order_with_fcash.blank?
            order_with_fcash.each do |ord|
              fresh_cash += ord.fresh_cash_used
              ord.fresh_cash_used = 0.00
              ord.save!
              if fresh_cash >= 0.00
                referrer.fresh_cash = fresh_cash
                break
              end
            end
          end
      end
      referrer.save!
    end
  end
  
  private
  
  def self.add_sorting_to_order_list(list)
    class << list
      def sort_by_customer_name
        self.sort_by{|o| o.customer.last_name }
      end
      
      def sort_by_zip
        self.sort_by{|o| o.customer.primary_address.zip }
      end
      
      def sort_by_address
        self.sort_by{|o| o.customer.primary_address.addr1}
      end
      
      def sort_by_pickup_date
        self.sort_by{|o| o.pickup_date}
      end
      
      def sort_by_delivery_date
        self.sort_by{|o| o.delivery_date}
      end
    end
    list
  end
  
end
