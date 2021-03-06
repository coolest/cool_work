# == Schema Information
# Schema version: 98
#
# Table name: serviced_zips
#
#  id  :integer(11)   not null, primary key
#  zip :string(9)     
#

class ServicedZip < ActiveRecord::Base
  has_many :promotion_zips
  belongs_to :state
  has_one :location, :as => :target
  validates_uniqueness_of :zip
  
  # def orders_for_today
  #     today = Time.today
  #     #todays_shifts = '('
  #     todays_shifts = []
  #     Shift.find(:all, :select => :id, :conditions => ["day = ? OR (recurring = true AND day_of_week = ?)", Date.today, Shift.day_array[today.wday]]).each do |s|
  #       #todays_shifts << s.id.to_s + ','
  #       todays_shifts << s.id
  #     end
  #     #todays_shifts[-1] = ')'
  #     Order.find(:all, :from => ["orders, shifts"], :conditions => ["orders.pickup_time_id IN (?)", todays_shifts])
  #   end
  
  def self.find_all_available_by_selection(selected_ids)
    return find(:all, :conditions => ['id IN (?)', selected_ids], :order => :zip)
  end
  
   # returns all requests for this zip on said date.
  def requests_for_date(date)
    #find all requests in this zip on this date
    s = Schedule.for(self.location, date)
    puts "generated schedule", s
    requests = []
    s.stops.each do |stop|
      puts stop
      requests << stop.requests if stop
      puts "requests: " + requests.to_s
    end
    requests.flatten.sort_by{|r| r.order.address.addr1}
  end
  
  def parent_location
    Zone.find(:all, :select => ["zones.id, zones.name"], :from => ["zones, zone_assignments"], :conditions => ["zones.id = zone_assignments.zone_id AND zone_assignments.location_id = ?", self.location.id])
  end
  
  def is_in(superzone)
    self.location.is_in(superzone)
  end
  def contains(subzone)
    self.location.contains(subzone)
  end
  
  def density
    d = 0
    Building.find_all_by_zip(self.zip).each do |b|
      d += b.density
    end
    d
  end
  
  def schedule
    
  end
  
end
