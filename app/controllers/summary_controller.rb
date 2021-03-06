require 'devise'
class SummaryController < ApplicationController
  include Devise::Controllers::SignInOut
  before_action :check_sign_in_status
  before_action :check_fesadmin_permission, :only => [:index]

  def index
    @contents = Content.all
  end

  def show
    target_content = Content.find_by_ucode(params[:ucode])
    if !target_content.present? then
      flash.now[:error] = "danger:指定されたucodeに該当する企画情報がありません"
      return
    end

    organization = Organization.find_by_ucode(target_content.organizer)

    if !(current_fes_user.role & ["Developer","FesAdmin","FesCommittee"]).present? and !organization.members.include?(current_fes_user.iniad_id) then
      flash.now[:error] = "danger:データへのアクセス権がありません"
      return
    end

    visitors = []
    target_content["visitors"].each do|visitor|
      visitors.append("user" => VisitorAttribute.find_by_user_id(visitor["user_id"]), "timestamp" => Time.parse(visitor["timestamp"]).in_time_zone("Tokyo"))
    end

    target_content["visitors"] = visitors.uniq{|visitor| visitor["user"].user_id}.sort{|visitor1, visitor2| visitor1["timestamp"] <=> visitor2["timestamp"]}

    @contents = target_content
    base_unix_time = [1572742800,1572829200]

    @visitor_by_hours = [
    ]

    time_keys = ["11月3日 11時","11月3日 13時","11月3日 15時","11月3日 17時","11月3日 19時","11月4日 11時","11月4日 13時","11月4日 15時","11月4日 17時","11月4日 19時"]
    5.times do |key|
      @visitor_by_hours.append({"key" => time_keys[key] ,"value" => target_content["visitors"].select{|visitor| Time.parse(visitor["timestamp"]).to_i >= base_unix_time[0] and Time.parse(visitor["timestamp"]).to_i < base_unix_time[0] + 7200}.sum{|visitor| visitor["user"]["visitor_attribute"]["number_of_people"].to_i}})
      base_unix_time[0] += 7200
    end

    5.times do |key|
      @visitor_by_hours.append({"key" => time_keys[key] ,"value" => target_content["visitors"].select{|visitor| Time.parse(visitor["timestamp"]).to_i >= base_unix_time[1] and Time.parse(visitor["timestamp"]).to_i < base_unix_time[1] + 7200}.sum{|visitor| visitor["user"]["visitor_attribute"]["number_of_people"].to_i}})
      base_unix_time[1] += 7200
    end

    age_counts = []
    age_keys = ["無回答・その他","10代以下","20代","30代","40代","50代","60代以上"]
    7.times do|id|
      age_counts.append({"key" => age_keys[id],"value" => target_content["visitors"].count{|visitor| visitor["user"]["visitor_attribute"]["age"] == id.to_s}})
    end
    @age_percentage = []
    age_counts.each do|count|
      @age_percentage.append({"key" => count["key"], "value" => Float(count["value"])/Float(age_counts.sum{|age| age["value"]})*100})
    end

    @gender_percentage = []
    gender_counts = []
    ["m","f","n"].each do|gender|
      gender_counts.append(target_content["visitors"].count{|visitor| visitor["user"]["visitor_attribute"]["gender"] == gender})
    end
    @gender_percentage = []
    gender_counts.each do|count|
      @gender_percentage.append(Float(count)/Float(gender_counts.sum)*100)
    end
    #render json:{"status" => "success", "data" => target_content}
    return


  end
end
