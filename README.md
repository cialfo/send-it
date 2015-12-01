MailChimp + Mandrill
===

####Set up

1. Configure mandrill_settings in <environment>.rb in config folder     

  
    ````
    config.mandrill_settings = {
    	:api_key => "X",
      	:from_email => "from@example.com",
      	:reply_to => "reply@example.com",
      	:from_name => "Sender Name",
  	}
	````
You can get **api_key** from your mandrill account. Also, make sure you configure your sending domain in mandrill to avoid mail bounce.

####To Do

1. Proper validations on page
2. Asynchronous update on page while sending email in background
3. Background notify via email once all emails are sent (useful when sending 1000s of emails)
4. Write unit tests
5. Clean up code