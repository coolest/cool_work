# == Schema Information
# Schema version: 98
#
# Table name: users
#
#  id                        :integer(11)   not null, primary key
#  first_name                :string(255)   
#  last_name                 :string(255)   
#  login                     :string(255)   
#  email                     :string(255)   
#  remember_token            :string(255)   
#  maiden                    :string(255)   
#  crypted_password          :string(40)    
#  salt                      :string(40)    
#  created_at                :datetime      
#  updated_at                :datetime      
#  remember_token_expires_at :datetime      
#  user_class                :string(20)    
#  account_id                :integer(11)   
#  account_type              :string(255)   
#  referrer                  :integer(11)   
#

require 'digest/sha1'
class User < ActiveRecord::Base
  belongs_to :customer, :foreign_key => :account_id
  belongs_to :driver,   :foreign_key => :account_id
  belongs_to :employee, :foreign_key => :account_id
  belongs_to :account, :polymorphic => true
  has_and_belongs_to_many :roles
  has_many :news
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password, :current_password, :current_password_required, :current_email, :current_email_required
  
  validates_presence_of     :email, :first_name, :last_name
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :new_record?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_confirmation_of :email,                   :if => :email_required?
  validates_presence_of     :email_confirmation,      :if => :new_record?
  validates_format_of       :email, :if => :email_required?, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_format_of       :email_confirmation, :if => :new_record?, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_presence_of     :current_email, :if => :current_email_required?
  validates_presence_of     :current_password, :if => :current_password_required?
  validate :current_matches
  
#  validates_presence_of :invitation_id, :message => 'is required', :allow_blank => true, :allow_nil => true
#  validates_uniqueness_of :invitation_id, :allow_blank => true, :allow_nil => true
  
  has_many :sent_invitations, :class_name => 'Invitation', :foreign_key => 'sender_id'
  belongs_to :invitation
  
  #before_create :set_invitation_limit
  #before_create :set_invitation_max
  #before_create :set_invitation_count
  
  attr_accessible :login, :email, :name, :password, :password_confirmation, :invitation_token
  
  
  def current_matches
    if current_email_required?
      user = User.find(self.id)
      errors.add_to_base("Current email is incorrect") unless current_email == user.email
    end
    if current_password_required?
      errors.add_to_base("Current password is incorrect") unless authenticated?(current_password)
    end
  end
  
  #validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :email, :case_sensitive => false
  before_save :encrypt_password
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :current_email, :current_email_required, :email, :email_confirmation, :current_password, :current_password_required, :password, :password_confirmation, :user_class, :first_name, :last_name, :maiden, :referrer
  
  liquid_methods :first_name, :last_name, :name, :customer, :account
  
  
  # Test if user is an admin
  def admin?
    has_role?("admin")
  end
  
  def employee?
    user_class == 'employee' || user_class == 'admin' || user_class == 'driver'
  end
  
  def before_save
    if self.login == nil
      self.login = self.email
    end
    self.set_invitation_id
  end
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    if @_list.include?("admin")
      true
    else
      if @_list
        @_list.include?(role_in_question.to_s)
      else
        false
      end
    end
  end
  
  def name
    name = [ first_name, last_name ].join(" ")
     (name.empty? || name == " ") ? email : name 
  end
  
  def self.administrators
    find(:all, :conditions => 'user_class <> "customer"').collect{ |u| u if u.has_role?('admin')}.flatten.compact
  end
  
  def self.search(search)
    if search
      find(:all, :conditions => ['(email LIKE ? or last_name LIKE ? or first_name LIKE ? or login LIKE ?) AND account_id IS NOT NULL AND account_type = "customer"', "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%"])
    end
  end
  
  def fresh_dollars
    if self.account_type == 'Customer'
      return self.account.fresh_dollars
    else
      return 0
    end
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
#  def referrer
#    @referrer
#  end
  def referrer=(val)
    if val.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/) == nil:
      @referrer = nil
    else
      if User.find_by_email(val) and self.email != val
        write_attribute('referrer', User.find_by_email(val).id)
        @referrer = User.find_by_email(val).id
      else 
        @referrer = nil
      end
    end
  end
#  def referrer=(val)
#    #puts "setting referrer..." + val.class.to_s
#    if val == nil
#      @referrer = nil
#    elsif val.class == String
#      #puts "...by code: " + val
#      write_attribute('referrer', Employee.find_by_referral_code(val).account.id)
#      @referrer = Employee.find_by_referral_code(val).account.id
#    else
#      #puts "...by integer/employee"
#      @referrer = Employee.find(val).account.id
#      write_attribute('referrer', Employee.find(val).account.id)
#      #puts 'REF: ' + @referrer.to_s
#    end
#  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
  #4b84a4b47fd321a23e92803a47f7423d65900649
  #69a14de529f437eba3f80485cf5525e8b93faa3e
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end
  
  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end
  
  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end
  
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end
  
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def email
    read_attribute('email')
  end

  def email=(value)
    if self.login == read_attribute('email')
      write_attribute('login', value)
    end
    write_attribute('email',value)
  end
  
  def invitation_token
    invitation.token if invitation
  end
  
  def invitation_token=(token)
    self.invitation = Invitation.find_by_token(token)
  end
  
  def orders_count
      customer = User.find(self.id).customer
      promotion = Promotion.find(:first,:conditions =>["code = 'FREETRIAL'"])
      customer.orders.find(:all, :conditions => ["status = 'delivered' AND promotion_id = ? ",promotion.id]).size
  end

  def fresh_cash_earned
      customer = User.find(self.id).customer
      promotion = Promotion.find(:first,:conditions =>["code = 'FREETRIAL'"])
      orders = customer.orders.find(:all, :conditions => ["status = 'delivered' AND promotion_id = ? ",promotion.id])
      points = orders.blank? ? 0 : 20 
  end
  protected
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def email_required?
    !email.blank?
  end
  
  def current_email_required?
    current_email_required == 'true'
  end
  
  def current_password_required?
    current_password_required == 'true'
  end

  def set_invitation_id
    if self.referrer
      invite = Invitation.find_by_sender_id(self.referrer)
      self.invitation_id = invite
    end
  end
  private
  
  def set_invitation_limit
    self.invitation_limit = 10
  end

  def set_invitation_max
    self.invitation_max = 100
  end
  
  def set_invitation_count
    self.invitation_count = 10
  end

end
