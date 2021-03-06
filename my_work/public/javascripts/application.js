// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var express = false;
var credit_card_number;
var credit_card_security_code;

function numeric(obj){

	var temp = obj.value;
	
	// avoid changing things if already formatted correctly
	var reg0Str = '[0-9]*';
        reg0Str += '\\.?[0-9]{0,' + 2 + '}';
	reg0Str = '^' + reg0Str;
	reg0Str = reg0Str + '$';
	var reg0 = new RegExp(reg0Str);
	if (reg0.test(temp)) return true;

	// first replace all non numbers
	var reg1Str = '[^0-9' + ('.') + ('') + ']';
	var reg1 = new RegExp(reg1Str, 'g');
	temp = temp.replace(reg1, '');

	var reg3 = /\./g;
	var reg3Array = reg3.exec(temp);
	if (reg3Array != null) {
		// keep only first occurrence of .
		//  and the number of places specified by decimalPlaces or the entire string if decimalPlaces < 0
		var reg3Right = temp.substring(reg3Array.index + reg3Array[0].length);
		reg3Right = reg3Right.replace(reg3, '');
		reg3Right = reg3Right.substring(0, 2)
		temp = temp.substring(0,reg3Array.index) + '.' + reg3Right;
	}	
	obj.value = temp;

//     str = field.value;
//     ch = str.substring(str.length - 1, str.length);
//     if (ch < "0" || ch > "9") {
//         field.value = str.substring(0, str.length - 1)
//     }
}

function toggle_slide(element, image){
    Effect.toggle(element, 'blind');
    if ($(element).style.display == 'none') 
        $(image).src = "/images/minimize.gif";
    else 
        $(image).src = "/images/maximize.gif";
}

function toggle_slide_element(element){
    if ($(element).visible() == true) {
        Effect.SlideUp($(element), {
            duration: 0.5
        });
    }
    else {
        Effect.SlideDown($(element), {
            duration: 0.5
        });
    }
}

function toggle_service_types(serviceId, imgUrl){
    element = $('service_' + serviceId);
    serviceTypes = $('service_types_' + serviceId);
    serviceImg = $('service_' + serviceId + '_image');
    if (element.checked == false) {
        serviceImg.src = '/images/selected_' + imgUrl;
        serviceTypes.show();
        element.checked = true;
    }
    else {
        serviceImg.src = '/images/' + imgUrl;
        serviceTypes.hide();
        element.checked = false;
    }
}

function toggle_express(bol){
    express = bol;
/*    $('free_pic').show();
    if (express) {
    	$('free_pic').hide();
    	$('free_del').hide();
    } else {
    	$('free_pic').show();
    	$('free_del').show();
    }*/
    var value = null;
    $$('.pickup_e').each(function(i){
        if ($F(i)) {
            i.click();
        }
    });
}

function toggle_delivery(toggleId){
    element = $(toggleId);
    delivery = $('order_delivery');
    if (element.checked == false) {
        delivery.show();
    }
    else {
        delivery.hide();
    }
}

function toggle_hand(toggleId){
    element = $(toggleId);
    if (element.src.endsWith('/hand.gif')) {
        element.src = '/images/selected_hand.gif';
    }
    else {
        element.src = '/images/hand.gif';
    }
}

function toggle_rec_div(element){
    if (element.value == 'No Thanks') {
        $('recurring_div').hide();
    }
    else {
        $('recurring_div').show();
    }
}

function quantity_check(qtyId){
    element = $(qtyId);
    if (element.value == '0') {
        element.value = 1;
    }
    
}

function toggle_emails(){
    $('current_email').toggle();
    $('email-toggle').toggle();
    $('email').toggle();
    $('email_confirm').toggle();
    if ($('email').visible() == true) {
        $('current_email').update('<td class="label"><label>Current Email:</label></td><td><input type="hidden" value="true" name="user[current_email_required]" id="user_current_email_required"/><input type="text" size="30" name="user[current_email]" id="user_current_email"/><script type="text/javascript">var user_current_email = new LiveValidation(\'user_current_email\', {onlyOnBlur: true});user_current_email.add(Validate.Presence, {"validMessage": "", "if": "current_email_required?"});</script><td>');
        $('email').update('<td class="label"><label for="user_email_confirmation">New Email:</label></td><td><input type="text" size="30" name="user[email_confirmation]" id="user_email_confirmation"/><script type="text/javascript">var user_email_confirmation = new LiveValidation(\'user_email_confirmation\', {onlyOnBlur: true});user_email_confirmation.add(Validate.Presence, {"validMessage": "", "if": "new_record?"});user_email_confirmation.add(Validate.Format, {"failureMessage": "Must be a valid email address!", "if": "new_record?", pattern:/^([^@\]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i});</script></td>');
        $('email_confirm').update('<td class="label"><label for="user_email">Confirm Email:</label></td><td><input type="text" size="30" name="user[email]" id="user_email"/><script type="text/javascript">var user_email = new LiveValidation(\'user_email\', {onlyOnBlur: true});user_email.add(Validate.Presence, {"validMessage": "", "if": "email_required?"});user_email.add(Validate.Confirmation, {"validMessage": "", "match": "user_email_confirmation", "if": "email_required?"});user_email.add(Validate.Presence, {"validMessage": "", "if": "new_record?"});user_email.add(Validate.Format, {"failureMessage": "Must be a valid email address!", "if": "new_record?", pattern:/^([^@\]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i});</script></td>');
    }
    else {
        $('current_email').update('');
        $('email').update('');
        $('email_confirm').update('');
    }
}

function toggle_passwords(){
    $('pass-toggle').toggle();
    $('old_pass').toggle();
    $('pass').toggle();
    $('pass_confirm').toggle();
    if ($('pass').visible() == true) {
        $('old_pass').update('<td class="label"><label for="user_current_password">Old Password:</label></td><td><input type="hidden" value="true" name="user[current_password_required]" id="user_current_password_required"/><input type="password" size="30" name="user[current_password]" id="user_current_password"/><script type="text/javascript">var user_current_password = new LiveValidation(\'user_current_password\', {onlyOnBlur: true});user_current_password.add(Validate.Presence, {"validMessage": "", "if": "current_password_required?"});</script></td>');
        $('pass').update('<td class="label"><label for="user_password_confirmation">Password:</label></td><td><input type="password" size="30" name="user[password_confirmation]" id="user_password_confirmation"/><script type="text/javascript">var user_password_confirmation = new LiveValidation(\'user_password_confirmation\', {onlyOnBlur: true});user_password_confirmation.add(Validate.Presence, {"validMessage": "", "if": "new_record?"})</script></td>');
        $('pass_confirm').update('<td class="label"><label for="user_password">Confirm Password:</label></td><td><input type="password" size="30" name="user[password]" id="user_password"/><script type="text/javascript">var user_password = new LiveValidation(\'user_password\', {onlyOnBlur: true});user_password.add(Validate.Presence, {"validMessage": "", "if": "password_required?"});user_password.add(Validate.Confirmation, {"validMessage": "", "match": "user_password_confirmation", "if": "password_required?"})</script></td>');
    }
    else {
        $('old_pass').update('');
        $('pass').update('');
        $('pass_confirm').update('');
    }
}


function additional_details(field, itemTypeId){
    str = field.value;
    fieldCount = $$('.item_class_' + itemTypeId).size();
    if (str > fieldCount) {
        $('item_add_details_' + itemTypeId).show();
    }
    else {
        $('item_add_details_' + itemTypeId).hide();
    }
}

function addAditionalDetails(itemTypeId, position){
    html = '<br/>';
    html += '<div class="special-handling" ><input type="hidden" name="item_details_' + itemTypeId + '[' + position + ']" value="' + position + '" />';
    html += 'Color: <input size=8 type="text" name="customer_item_type_' + itemTypeId + '_' + position + '[color]" />';
    html += 'Brand: <input size=8 type="text" name="customer_item_type_' + itemTypeId + '_' + position + '[brand]" />';
    html += 'Size: <input size=7 type="text" name="customer_item_type_' + itemTypeId + '_' + position + '[size]" />';
    html += '<div class="item-instructions">';
    html += 'Instructions: <textarea name="instructions_item_type_' + itemTypeId + '_' + position + '[text]" cols=40 rows=3></textarea>';
    html += '</div><div><a href="#" class="tooltip"><img src="/images/help.png?1213004525" alt=""/><span>Select an option if you want to alter this items specific service level to that of the main order.</span></a> <a onclick="javascript:load_window(\'/prices#Premium\', \'Premium Prices\'); return false;" href="#" class="green">Premium Service</a> ';
    html += '<input type="radio" value="true" name="customer_item_type_' + itemTypeId + '_' + position + '[premium]" id="customer_item_type_' + itemTypeId + '_' + position + 'premium_true" /> Yes <input type="radio" name="customer_item_type_' + itemTypeId + '_' + position + '[premium]" id="customer_item_type_' + itemTypeId + '_' + position + 'premium_false" /> No</div>';
    html += '<div class="special-title green"><a style="float: right" href="#" onclick="$(\'item_type_' + itemTypeId + '_' + position + '\').remove(); additional_details($(\'quantity_item_type_' + itemTypeId + '\'), ' + itemTypeId + '); return false;">Remove</a> Special Handling</div></div>';
    $("item_type_" + itemTypeId + "_" + position).update(html);
    
    newPos = position + 1
    html = '<div id="item_type_' + itemTypeId + '_' + newPos + '" class="item_class_' + itemTypeId + '" >'
    html += '<div id="item_add_details_' + itemTypeId + '" class="item-handling" style="display:none;">'
    html += '<br/>'
    html += '<a href="#" onclick="javascript:addAditionalDetails(' + itemTypeId + ',' + newPos + '); return false;">Add additional item details</a>'
    html += '</div></div>'
    $("item_special_handling_" + itemTypeId).insert({
        bottom: html
    });
    
    additional_details($('quantity_item_type_' + itemTypeId), itemTypeId);
}

function toggle_preference_element(element, showElement){
    if ($(element).visible() == true) {
        if (!showElement) {
            Effect.SlideUp($(element), {
                duration: 0.5
            });
        }
    }
    else {
        if (showElement) {
            Effect.SlideDown($(element), {
                duration: 0.5
            });
        }
    }
}

function changePickUpDelivery(date, day, startTime, endTime, isPickup){
    if (isPickup == true) {
        // remote function to update order delivery
/*        $('free_pic').show();
        if ($('express_yes_true').checked) {
        	$('free_del').hide();
        	$('free_pic').hide();
        } else {
        	$('free_pic').show();
        	$('free_del').show();
        }*/
        changePickUpDelivery.pickup = new Date(date);
        changePickUpDelivery.start_time = startTime 
        $('order_delivery').update('<center><h2 class="green">Loading Delivery Windows...</h2></center>');
        $('delivery-block').show();
        $('delivery-block').scrollTo();
        new Ajax.Request('?date=' + date + '&express=' + $('express_yes_true').checked + '&start=' + startTime, {
            method: 'get',
            asynchronous: true,
            evalScripts: true
        });
        
    }
    else if(new Date(date) >= changePickUpDelivery.pickup)
    {
        $('order_delivery').update('<center><h2 class="green">Loading Delivery Windows...</h2></center>');
        $('delivery-block').show();
        $('delivery-block').scrollTo();
        new Ajax.Request('?date=' + date + '&express=' + $('express_yes_true').checked + '&start=' + ((""+new Date(date))==(""+changePickUpDelivery.pickup) ? changePickUpDelivery.start_time : startTime), {
            method: 'get',
            asynchronous: true,
            evalScripts: true
        });
    }
}

var addss=new Hash({});

function populateCreditCard(cType, pType){
    if (cType == "No") {
    		pType = $("credit_card_payment_method").options[$('credit_card_payment_method').selectedIndex].text;
        $('payment-info').show();
        $('payment-address').show();
        credit_card_number = new LiveValidation('credit_card_number', {
            onlyOnBlur: true
        });
        credit_card_number.add(Validate.Presence, {
            "validMessage": ""
        });
        
        secLength = 3;
        if (pType == 'American Express') {
            secLength = 4;
        }
        if (credit_card_security_code!=null){
            credit_card_security_code.destroy();}
	//credit_card_security_code.destroy();
        credit_card_security_code = new LiveValidation('credit_card_security_code', {
            onlyOnBlur: true
        });
        credit_card_security_code.add(Validate.Presence, {
            "validMessage": ""
        });
        credit_card_security_code.add(Validate.Length, {
            "validMessage": "",
            "is": secLength
        })
    }
    else {
    	$('payment-address').hide();
        $('payment-info').hide();
        if (credit_card_number != null) {
            credit_card_number.destroy();
        }
        if ( credit_card_security_code != null) {
            credit_card_security_code.destroy();
        }
    }
}

function updCcAddss(adres){
	$('credit_card_address').value = adres.address;
	$('credit_card_city').value = adres.city;
	$('credit_card_state').value = adres.state;
	$('credit_card_zip').value = adres.zip;
}

function changeSecCodeValidation(cardType){
    secLength = 3;
    if (cardType == 'American Express') {
        secLength = 4;
    }
    if (credit_card_security_code!=null){
	credit_card_security_code.destroy();}
    credit_card_security_code = new LiveValidation('credit_card_security_code', {
        onlyOnBlur: true
    });
    credit_card_security_code.add(Validate.Presence, {
        "validMessage": ""
    });
    credit_card_security_code.add(Validate.Length, {
        "validMessage": "",
        "is": secLength
    })
}

function updateCompletion(orderAmount, item, el){
    price = 0.00;
    switch (item) {
        case 'laundry':
            price = 15.00;
            break;
        case 'garment':
            price = 15.00;
            break;
        case 'detergent':
            price = 17.99;
            break;
        default:
            break
    }
    document.cookie = $("Reusable_laundry_bag").value + "," + $("Reusable_garmet_bag").value
    $(item + "-quantity").update($F(el));
    $(item + "-subtotal").update('$' + (price * $F(el)).toFixed(2));
    sub = parseFloat($("laundry-subtotal").innerHTML.substring(1)) + parseFloat($("garment-subtotal").innerHTML.substring(1)) + parseFloat($("detergent-subtotal").innerHTML.substring(1));
    $("completion-sub").update('$' + sub.toFixed(2));
    tax = sub * 0.09;
    $("completion-tax").update('$' + tax.toFixed(2));
    total = sub + tax;
    tax = sub * 0.09;
    $("completion-total").update('$' + total.toFixed(2));
    complete = total + orderAmount
    $("est-complete-total").update('$' + complete.toFixed(2));
}

function set_product_value(estimated_amount)
{
  if(document.cookie.length <= 0)
  {
    document.cookie = "0,0";
  }
  dc = document.cookie
  dc = dc.split(",");
  $("Reusable_laundry_bag").value = dc[0];
  $("Reusable_garmet_bag").value = dc[1];
  updateCompletion(estimated_amount,'laundry',$("Reusable_laundry_bag"));
  updateCompletion(estimated_amount,'garment',$("Reusable_garmet_bag"));
}

function load_window(url, title){
    var load = window.open(url, title, 'scrollbars=yes,menubar=no,height=800,width=550,resizable=yes,toolbar=no,location=no,status=no');
}

function load_window_large(url, title){
    var load = window.open(url, title, 'scrollbars=yes,menubar=no,height=800,width=900,resizable=yes,toolbar=no,location=no,status=no');
}

function checkDate(mnth, yr){
    var t = new Date();
    var today = new Date(t.getFullYear(), t.getMonth(), 1);
    var selected = new Date('20' + $F(yr), $F(mnth) - 1, 1);
    
    today.setDay
    if (today > selected) {
        //		alert("Invalid Date<br/>Today: " + today + "<br/>selected:" + selected);
        alert("Invalid Date");
    }
    return false;
}


function updateItemQuantity(element) {
	if (element.value == 0) {
		element.remove();
	}
}
