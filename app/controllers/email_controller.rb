require 'json'
require 'csv'
require 'mandrill'
class EmailController < ApplicationController

  #skip_before_filter :verify_authenticity_token

  MANDRILL_API_KEY = Rails.application.config.mandrill_settings[:api_key]

  def configure

  end

  def send_mail
    mail_sent_count = 0
    s_params = send_mail_params

    csv_file = s_params[:csv_file].tempfile
    data_params = JSON.parse(s_params["data"])

    from_name = data_params["from_name"]
    from_email = data_params["from_email"]
    template_id = data_params["template_id"]
    subject = data_params["subject"]
    session[:notify_email] = data_params["notify_email"]

    users = []
    columns = []

    if from_email.blank?
      render :json => {:status => "Failed", :reason => "From Email id is blank"} and return
    elsif template_id.blank?
      render :json => {:status => "Failed", :reason => "Template Id is missing. Please get the template id from Mandrill"} and return
    end

    CSV.foreach(csv_file).each do |row|
      if columns.length > 0
        users << row
      else
        columns.push(*row)
      end
    end

    #Rails.cache.write("total", users.length)
    to_ids = []
    user_vars = []

    users.each do |user|

      to = {:email => user[0], :type => "to"}
      to_ids << to

      vars = []
      for i in 1...columns.length
        vars << {:name => columns[i] , :content => user[i]}
      end
      user_vars << {:rcpt => user[0], :vars => vars}

      send_count = SendMail(from_name, from_email, subject, to_ids, template_id, nil, user_vars)

      mail_sent_count += send_count

      #Rails.cache.write("sent", mail_sent_count)

    end

    unless session[:notify_email].blank?
      mandrill = Mandrill::API.new MANDRILL_API_KEY
      mandrill.messages.send_raw("Total Emails Sent = #{mail_sent_count}", from_email, from_name, [session[:notify_email]], false)
    end

    render :json => {:status => "Succes", :sent_count => mail_sent_count, :total_count => users.length}.to_json
  end

  def update_notify
    session[:notify_email] = params["notify_email"]
    render :json => {:status => "Success"}.to_json
  end

  # def get_progress
  #   total_count = Rails.cache.fetch("total")
  #   sent_count = Rails.cache.fetch("sent")
  #   render :json => {:total => total_count, :sent => sent_count}
  # end

  private

  def send_mail_params
    params.permit(:csv_file, :data)
  end

  def SendMail(from_name, from_email, subject, to_ids, template_id, global_vars, user_vars)

    reply_to = from_email #TODO: Add another field in UI to give a different reply-to email id

    mandrill = Mandrill::API.new MANDRILL_API_KEY
    count = 0

    begin
      template_id = template_id
      template_content = [{"name" => "example name", "content" => "example content"}] #since we are using mailchimp template, this can have dummy values. Not used actually
      message = {
          "subject"=> subject,
          "from_email" => from_email,
          "from_name" => from_name,
          "to" => to_ids,
          "headers" => {"Reply-To" => reply_to},
          "important" => true,
          "track_opens" => true,
          "track_clicks" => true,
          "auto_text" => nil,
          "auto_html" => nil,
          "inline_css" => nil,
          "url_strip_qs" => nil,
          "preserve_recipients" => nil,
          "view_content_link" => nil,
          "bcc_address" => nil,
          "tracking_domain" => nil,
          "signing_domain" => nil,
          "return_path_domain" => nil,
          "merge" => true,
          "merge_language" => "mailchimp",
          "global_merge_vars" => global_vars,
          "merge_vars"=> user_vars#,
          #"tags"=>["password-resets"],
          #"subaccount"=>"customer-123",
          # "google_analytics_domains"=>["example.com"],
          # "google_analytics_campaign"=>"message.from_email@example.com",
          # "metadata"=>{"website"=>"www.example.com"},
          # "recipient_metadata"=>
          #     [{"rcpt"=>"recipient.email@example.com", "values"=>{"user_id"=>123456}}],
          # "attachments"=>
          #     [{"type"=>"text/plain",
          #       "name"=>"myfile.txt",
          #       "content"=>"ZXhhbXBsZSBmaWxl"}],
          # "images"=>
          #     [{"type"=>"image/png", "name"=>"IMAGECID", "content"=>"ZXhhbXBsZSBmaWxl"}]
      }

      async = false #mandrill API does not allow async to be true if number of emails sent is < 10
      result = mandrill.messages.send_template template_id, template_content, message, async

      if result.present? && result.length > 0 && (result[0]["status"] == "sent" || result[0]["status"] == "queued")
        count += 1
      end

    rescue Mandrill::Error => e
      logger.error("Mandrill API Error - #{e.message}")
    end

    count #return value
  end
end