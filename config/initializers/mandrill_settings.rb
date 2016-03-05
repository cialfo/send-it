Rails.application.config.mandrill_settings = {
    :api_key => ENV['MANDRILL_API_KEY'],
  }
raise "No environmental MANDRILL_API_KEY variable found." unless ENV['MANDRILL_API_KEY']