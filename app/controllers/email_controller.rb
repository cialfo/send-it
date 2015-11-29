require 'csv'

class EmailController < ApplicationController

  SUPPORTED_USER_TAGS = %w(FNAME LNAME EMAIL)

  def configure
    @supported_tags = SUPPORTED_USER_TAGS.join(", ")
  end

  def send_mail

    s_params = send_mail_params
    template_id = s_params[:template_id]
    subject = s_params[:subject]
    csv_file = s_params[:csv_file].tempfile
    subject = subject.blank? ? nil : subject

    col_tags = []
    col_values = []

    CSV.foreach(csv_file).each do |row|
      if col_tags.length > 0
        col_values.push(*row)
      else
        col_tags.push(*row)
      end
    end

    render :text => "success" and return

    mail_result = "Default Result"
    user_count = 0
    mail_sent_count = 0

    if template_id.empty?
      render :text => "error|Template Id is missing. Please get the template id from Mandrill" and return
    end

    global_vars = []
    global_tag_names = params["data"]["global-tag-names"]
    if !global_tag_names.blank?
      g_names = global_tag_names.split(",")
      g_values = params["data"]["global-tag-values"].split(",")

      total_tags = g_names.length

      for i in 0..total_tags - 1
        var = {g_names[i] => g_values[i]}
        global_vars << var
      end
    end

    api_params = {}
    api_params[:token] = "#{session[:token]}"

    mode = params["data"]["mode"]
    if mode == "test"
      api_params["emails"] = params["data"]["test_email_ids"]
      res = send_http_request_using_rest_client("users/get_users_by_email", "POST", api_params)
    else
      res = send_http_request_using_rest_client("users/get_all_users", "POST", api_params)
    end

    if @valid_response
      user_count = res["user_count"]
      users = res["data"]["users"]

      users.each do |user|

        to_ids = []
        user_vars = []

        to = {:email => user["email"], :name => user["first_name"], :type => "to"}
        to_ids << to

        vars = []
        SUPPORTED_USER_TAGS.each do |utag|
          vars << {:name => utag[:tag] , :content => user[utag[:value]]}
        end
        user_vars << {:rcpt => user["email"], :vars => vars}

        send_count = SendMail template_id, to_ids, subject, global_vars, user_vars
        mail_sent_count += send_count
      end

      render :text => "Total Users = #{user_count}. Mail sent to = #{mail_sent_count}."
    else
      render :text => "API Error. Check server logs for more details"
    end

  end

  private

  def send_mail_params
    params.permit(:template_id, :subject, :csv_file)
  end

  def SendMail(template_id, to_ids, subject, global_vars, user_vars)

    api_key = Rails.application.config.action_mailer.smtp_settings[:password]
    mandrill = Mandrill::API.new api_key
    count = 0

    begin
      template_id = template_id
      template_content = [{"name" => "example name", "content" => "example content"}]
      message = {
          "subject"=> subject,
          "from_email" => "hello@sitforsat.com",
          "from_name" => "SitforSAT Team",
          "to" => to_ids,
          "headers" => {"Reply-To" => "hello@sitforsat.com"},
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