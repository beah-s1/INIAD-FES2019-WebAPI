require 'digest/sha2'
class UserController < ApplicationController
  before_action :authentication, :except => [:new]
  protect_from_forgery :except => [:new,:update_notification_token]

  def new
    if !params["device_type"].present? then
      render json:{"status" => "error", "description" => "device_type is required"},status:400
      return
    end

    user = User.new
    user.user_id = SecureRandom.uuid
    secret = SecureRandom.alphanumeric(32)
    user.secret = Digest::SHA256.hexdigest(secret)
    user.role = ["app_user"]
    user.device_type = params["device_type"]

    user.save()

    render json:{"status" => "success", "secret" => secret, "role" => user.role}
    return
  end

  def update_notification_token
    if !params["device_token"].present? then
      render json:{"status" => "error", "description" => "required parameters missing"},status:400
      return
    end

    user = User.find_by_user_id(@user.user_id)
    user.notification_token = params["device_token"]

    user.save()

    render json:{"status" => "success", "description" => "notification token update has been successfully"}
  end

  def dump_data
    begin
      fes_user = FesUser.where("devices @> ARRAY[?]::varchar[]", [@user.user_id]).first()
      if !fes_user.present? then
        render json:{"status" => "success", "role" => @user.role, "member_of" => []}
        return
      end

      if fes_user.role.include?("Developer") or fes_user.role.include?("FesCommittee") then
        circle_object = Organization.all
      else
        circle_object = Organization.where("members @> ARRAY[?]::varchar[]",[fes_user.iniad_id])
      end
      circle_list = []
      circle_object.each do |circle|
        contents_object = Content.where(:organizer => circle.ucode)
        contents = []

        contents_object.each do|content|
          contents.append({"ucode" => content.ucode, "title" => content.title})
        end

        circle_list.append({"ucode" => circle.ucode, "organization_name" => circle.organization_name, "contents" => contents})
      end
    rescue
      render json:{"status" => "error", "description" => "internal server error"},status:500
      return
    end

    render json:{"status" => "success", "role" => @user.role, "member_of" => circle_list}
    return
  end
end
