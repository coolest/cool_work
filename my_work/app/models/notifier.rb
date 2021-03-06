class Notifier < ActionMailer::Base
  require 'rubygems'
  require 'clickatell'
  require 'liquid'
  
  helper :application
  
  def self.email_content(content)
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"> <html xmlns="http://www.w3.org/1999/xhtml"> <head> <meta http-equiv="Content-Type" content="text/html; charset=utf-8" /> <style type="text/css"> <!-- body p{ font-family: Verdana, Geneva, sans-serif; } --> </style> </head> <body>' + '<table width="800"><tr><td style="border-bottom: 1px solid black;"><img width="800" border="0" src="http://myonlinecleaner.com/images/header_top_email.jpg"/><br /><br/></td><tr><td><br/><br/>' + content + '<br/><br/></td></tr><tr><td align="center" style="border-top: 1px solid black;"><br/><span class="footer"><a href="http://myonlinecleaner.com/home">Home</a> | <a href="http://myonlinecleaner.com/about">About Us</a> | <a href="http://myonlinecleaner.com/how_it_works">How It Works</a> | <a href="http://myonlinecleaner.com/pickup">Pick Up & Delivery</a> | <a href="http://myonlinecleaner.com/prices">Prices</a> | <a href="http://myonlinecleaner.com/faq">FAQ</a> | <a href="http://myonlinecleaner.com/contact_us">Contact Us</a></span><br/><br/><span class="secondary_copy">� 2011 My Fresh Shirt. All Right Reserved.</span></td></tr></table>' + '</body> </html>'
  end
  
  def deliver_template_sms(customer, method_name, body)
    logger.info 'Attempting sms for: ' + method_name + ' - '+ customer.cell
    notification_template = NotificationTemplate.find_by_name(method_name)
    if notification_template && notification_template.sms_body
      template = Liquid::Template.parse(notification_template.sms_body)
      begin
        Notifier.deliver_sms('1' + customer.cell, template.render(body))
        logger.info 'Clickatel SMS: Sent sms to 1' + customer.cell
      rescue Clickatell::API::Error => e
        logger.error 'Clickatel SMS: ' + e.message
      end
    else
      logger.error method_name + ' template not found'
    end
  end
  
  def self.deliver_sms(number, body)
    if number && body 
      api = Clickatell::API.authenticate('3136793', 'global4g', 'OUWnry14')
      api.send_message(number, body)
    end
  end
  
  def render_message(method_name, body)
    notification_template = NotificationTemplate.find_by_name(method_name)
    if notification_template && !notification_template.mail_body.blank?
      template = Liquid::Template.parse(Notifier.email_content(notification_template.mail_body))
      template.render(body)
    else
      super(method_name, body)
    end
  end
  
  def signup_thanks( user )
    recipients user.email
    from  "accounts@myfreshshirt.com"
    subject "Thank you for registering with our website" 
    @body = {'user' => user}
    @content_type = "text/html"
    deliver_template_sms(user.customer, 'signup_thanks', @body)
  end
  
  def invitation_notification( user, referrer, url )
    puts user, referrer
    recipients user.recipient_email
    from  "invitations@myfreshshirt.com"
    subject "You have been invited to check out myonlinecleaner.com" 
    @body = {'user' => user, 'referrer' => referrer, 'url' => url}
    @content_type = "text/html"
#     deliver_template_sms(user.customer, 'signup_thaordernks', @body)
  end
  
  def new_password(user, new_password) 
    recipients user.email
    from  "accounts@myfreshshirt.com"
    subject 'Your new password' 
    @body = {'user' => user, 'new_password'  => new_password}
    @content_type = "text/html"
    deliver_template_sms(user.customer, 'new_password', @body)
  end  
  
  def order_payment_thanks( user, order )
    recipients user.email
    from  "orders@myfreshshirt.com"
    subject "Thank you for your order" 
    @body = {'user' => user , 'order' => order}
    @content_type = "text/html"
    deliver_template_sms(user.customer, 'order_payment_thanks', @body)
  end
  
  def order_cancellation( order )
    recipients order.customer.email
    from "orders@myfreshshirt.com"
    subject "Your order has been cancelled."
    @body = {'order' => order}
    @content_type = "text/html"
    deliver_template_sms(order.customer, 'order_cancellation', @body)
  end
  
  def contact_message(email, service, message)
    recipients 'customerservice@myfreshshirt.com' #service
    from  email
    subject "Contact Form Enquiry" 
    @body = {'message' => message, 'customer' => email}
    @content_type = "text/html"
  end
  
  def new_complaint(users, note)
    recipients users
    from  "complaints@myfreshshirt.com"
    subject "New Complaint" 
    @body = {'note' => note, 'user' => note.customer.user}
    @content_type = "text/html"
  end
  
  def failed_cancellation( order)
    recipients order.customer.email
    from "orders@myfreshshirt.com"
    subject "Order cancellation failed."
    @body = {'order' => order}
    @content_type = "text/html"
    deliver_template_sms(order.customer, 'failed_cancellation', @body)
  end
  
  def service_request_confirmation(customer)
    recipients customer.email
    from "customerservice@myfreshshirt.com"
    subject "Thank you for your inquiry."
    @body = {'customer' => customer}
    @content_type = "text/html"
    deliver_template_sms(customer, 'service_request_confirmation', @body)
  end
  
  def authorization_failure(order)
    recipients order.customer.email
    from       "orders@myfreshshirt.com"
    cc         "customerservice@myfreshshirt.com"    
    subject    "Order authorization failure."
    @body = {'order' => order}
    @content_type = "text/html"
  end
  
  def itemization(order, services = nil) #call after intake
    recipients order.customer.email
    from       "orders@myfreshshirt.com"
    subject    "Your itemization!  --This is not a bill"
    services = order.order_items.collect {|oi| oi.service } if services == nil
    @body = {'customer' => order.customer, 'order' => order, 'services' => services}
    @content_type = "text/html"
    deliver_template_sms(order.customer, 'itemization', @body)
  end
  
  def failed_delivery( order )
    recipients order.customer.email
    from       "orders@myfreshshirt.com"
    subject    "My Oh My - We Missed You"
    @body = {'customer' => order.customer, 'order' => order}
    @content_type = "text/html"
    deliver_template_sms(order.customer, 'failed_delivery', @body)
  end
  
  def order_thanks ( order )
    recipients order.customer.email
    from       "order@myfreshshirt.com"
    subject    "Your request has been received!"
    bcc        "customerservice@myfreshshirt.com"
    @body = {'customer' => order.customer, 'order' => order}
    @content_type = "text/html"
    deliver_template_sms(order.customer, 'order_thanks', @body)
  end
  
  def complaint_receipt ( customer )
    recipients customer.email
    from       "customerservice@myfreshshirt.com"
    subject    "We have received your complaint."
    @content_type = "text/html"
    deliver_template_sms(customer, 'complaint_receipt', @body)
  end
  
  def not_serviced_notice (customer)
    recipients customer.email
    from       "customerservice@myfreshshirt.com"
    subject    "New user"
    @body = {'customer' => customer}
    @content_type = "text/html"
    deliver_template_sms(customer, 'not_serviced_notice', @body)
  end
  
  def failed_change( order )
    recipients order.customer.email
    from       "customerservice@myfreshshirt.com"
    subject    "My Oh My - It's Too Late"
    @body = {'customer' => order.customer, 'order' => order}
    @content_type = "text/html"
    deliver_template_sms(order.customer, 'failed_change', @body)
  end

  def send_promotion( user, promotion_content )
    recipients user.email
    from  "customerservice@myfreshshirt.com"
    subject "My Fresh Shirt - " + promotion_content.title.split.each{|i| i.capitalize!}.join(' ')
    ip_addr = 'http://' + ( RAILS_ENV == 'production' ? "www.myonlinecleaner.com" : "staging.myonlinecleaner.com" )
    @body = { 'user' => user, 'promotion_content' => promotion_content, 'ip_addr' => ip_addr }
    @content_type = "text/html"
  end

  def auth_error(request, response)
    recipients "jayesh@systematixtechnocrates.com"
    from  "exceptions@practical.cc"
    subject "Authorize.net error"
    @body = {"request" => request, "response" => response}
    #@content_type = "text/html"
  end

  def send_mail_for_reschduling(order)
    recipients order.customer.email
    from       "order@myfreshshirt.com"
    subject    "Order has been recheduled!"
    @body = {'customer' => order.customer, 'order' => order}
    @content_type = "text/html"
  end
  
  def send_reminder_mail_for_order(register_invitee)
    recipients register_invitee.email
    from       "customerservice@myfreshshirt.com"
    subject    "Place your order!"
    @body = {'register_invitee' => register_invitee}
    @content_type = "text/html"
  end
end
