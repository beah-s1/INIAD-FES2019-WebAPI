class ContentsController < ApplicationController
  # before_action :authentication
  # -> Webサイトからのアクセスを受け入れるため削除

  def index
    response.headers["Access-Control-Allow-Origin"] = "*"
    contents = Content.all

    if params["room_num"].present? then
      rooms = []
      Room.where(:room_num => params["room_num"].split(",")).each do|room|
        rooms.append(room.ucode)
      end

      contents = contents.where(:place => rooms)
    end

    if params["room_near"].present? then
      related_rooms = []
      Room.where("related_rooms @> ?",[params["room_near"]]).each do|room|
        related_rooms += room.ucode
      end

      contents = contents.where(:place => related_rooms)
    end

    if params["floor"].present? then
      rooms = Room.where(:floor => params["floor"])
      room_ucodes = []

      rooms.each do|room|
        room_ucodes += room.ucode
      end

      contents = contents.where(:place => room_ucodes)
    end

    data = []

    contents.each do|content|
      place = Room.where("ucode @> ARRAY[?]::varchar[]",content.place).first()
      organizer = Organization.find_by_ucode(content.organizer)

      data.append({
                      "ucode" => content.ucode,
                      "title" => content.title,
                      "description" => content.description,
                      "organizer" => {
                          "ucode" => organizer.ucode,
                          "organizer_name" => organizer.organization_name
                      },
                      "place" => {
                          "ucode" => place.ucode,
                          "room_name" => place.room_num,
                          "door_name" => place.door_name,
                          "room_color" => place.room_color
                      },
                      "image" => content.image_url
                  })
    end

    data.sort! do|a,b|
      a["place"]["room_name"] <=> b["place"]["room_name"]
    end

    render json:{"status" => "success", "objects" => data}
  end

  def show
    response.headers["Access-Control-Allow-Origin"] = "*"
    if !params["ucode"].present? then
      render json:{"status" => "error", "description" => "required parameter missing"},status:400
      return
    end

    content = Content.find_by_ucode(params["ucode"])
    place = Room.where("ucode @> ARRAY[?]::varchar[]",content.place).first()
    organizer = Organization.find_by_ucode(content.organizer)

    data = {
        "ucode" => content.ucode,
        "title" => content.title,
        "description" => content.description,
        "organizer" => {
            "ucode" => organizer.ucode,
            "organizer_name" => organizer.organization_name
        },
        "place" => {
            "ucode" => place.ucode,
            "room_name" => place.room_num,
            "door_name" => place.door_name,
            "room_color" => place.room_color
        },
        "image" => content.image_url
    }

    render json:{"status" => "success", "object" => data}
  end

  def floor_images
    images = FloorImage.all.order(:floor)

    image_response = []
    images.each do |image|
      image_response.append({"floor" => image.floor, "image_url" => image.image_url})
    end

    response.headers["Access-Control-Allow-Origin"] = "*"
    render json:{"status" => "success", "images" => image_response},status:200
  end
end
