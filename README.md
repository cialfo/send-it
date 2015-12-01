MailChimp + Mandrill
===

####Set up

* Configure mandrill_settings in <environment>.rb in config folder    
````
config.mandrill_settings = {
      :api_key => "X",
      :from_email => "from@example.com",
      :reply_to => "reply@example.com",
      :from_name => "Sender Name",
  }
````