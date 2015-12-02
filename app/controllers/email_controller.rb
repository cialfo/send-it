require 'csv'
require 'mandrill'
class EmailController < ApplicationController

  SUPPORTED_USER_TAGS = %w(FNAME LNAME EMAIL)

  def configure
    @supported_tags = SUPPORTED_USER_TAGS.join(", ")
  end

  def send_mail

    mail_sent_count = 0
    s_params = send_mail_params
    template_id = s_params[:template_id]
    subject = s_params[:subject]
    csv_file = s_params[:csv_file].tempfile
    subject = subject.blank? ? nil : subject

    users = []
    columns = []

    if template_id.empty?
      render :text => "error|Template Id is missing. Please get the template id from Mandrill" and return
    end

    CSV.foreach(csv_file).each do |row|
      if columns.length > 0
        users << row
      else
        columns.push(*row)
      end
    end

    users.each do |user|
      to_ids = []
      user_vars = []

      to = {:email => user[0], :type => "to"}
      to_ids << to

      vars = []
      for i in 1...columns.length
        vars << {:name => columns[i] , :content => user[i]}
      end
      user_vars << {:rcpt => user[0], :vars => vars}

      send_count = SendMail template_id, to_ids, subject, nil, user_vars
      mail_sent_count += send_count
    end

    render :text => "#{mail_sent_count} Mails Sent"
  end

  private

  def send_mail_params
    params.permit(:template_id, :subject, :csv_file)
  end

  def SendMail(template_id, to_ids, subject, global_vars, user_vars)

    #read conifugration
    api_key = Rails.application.config.mandrill_settings[:api_key]
    from_email = Rails.application.config.mandrill_settings[:from_email]
    from_name = Rails.application.config.mandrill_settings[:from_name]
    reply_to = Rails.application.config.mandrill_settings[:reply_to]

    mandrill = Mandrill::API.new api_key
    count = 0

    begin
      template_id = template_id
      template_content = [{"name" => "example name", "content" => "example content"}]
      message = {
          "subject"=> subject,
          "from_email" => "taher435@gmail.com",
          "from_name" => "Mariya Dhilawala",
          "to" => to_ids,
          "headers" => {"Reply-To" => reply_to},
          "important" => false,
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

      async = false
      # ip_pool = "Main Pool"
      # send_at = nil

      result = mandrill.messages.send_template template_id, template_content, message, async

      count += 1

    rescue Mandrill::Error => e
      logger.error("Mandrill API Error - #{e.message}")
    end

    return count

  end
end