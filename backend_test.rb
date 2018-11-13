require 'json'

input = {
  "listings": [
    { "id": 1, "num_rooms": 2 },
    { "id": 2, "num_rooms": 1 },
    { "id": 3, "num_rooms": 3 }
  ],
  "bookings": [
    { "id": 1, "listing_id": 1, "start_date": "2016-10-10", "end_date": "2016-10-15" },
    { "id": 2, "listing_id": 1, "start_date": "2016-10-16", "end_date": "2016-10-20" },
    { "id": 3, "listing_id": 2, "start_date": "2016-10-15", "end_date": "2016-10-20" }
  ],
  "reservations": [
    { "id": 1, "listing_id": 1, "start_date": "2016-10-11", "end_date": "2016-10-13" },
    { "id": 1, "listing_id": 1, "start_date": "2016-10-13", "end_date": "2016-10-15" },
    { "id": 1, "listing_id": 1, "start_date": "2016-10-16", "end_date": "2016-10-20" },
    { "id": 3, "listing_id": 2, "start_date": "2016-10-15", "end_date": "2016-10-18" }
  ]
}

def handle_cleanings(input)
  set_variables(input)
  first_checkin_missions = get_first_checkin_missions
  last_checkout_missions = get_last_checkout_missions
  checkout_checkin_missions = check_listing_match(get_bookings_per_listing, get_reservations_per_listing)
  missions = [first_checkin_missions, last_checkout_missions, checkout_checkin_missions].flatten
  generate_json(missions)
end

def set_variables(input)
  @listings, @bookings, @reservations = input[:listings], input[:bookings], input[:reservations]
end

def get_first_checkin_missions
  @bookings.map do |booking|
    {
      listing_id: booking[:listing_id],
      mission_type: 'first_checkin',
      date: booking[:start_date],
      price: calculate_cleaning_price(booking)
    }
  end
end

def get_last_checkout_missions
  @bookings.map do |booking|
    {
      listing_id: booking[:listing_id],
      mission_type: 'last_checkout',
      date: booking[:end_date],
      price: calculate_cleaning_price(booking)
    }
  end
end

def check_listing_match(bookings_per_listing, reservations_per_listing)
  checkout_checkin_missions = []
  reservations_per_listing.each { |k, v| check_booking_dates_match(k, v, checkout_checkin_missions) if bookings_per_listing.key?(k) }
  checkout_checkin_missions
end

def check_booking_dates_match(listing, reservations, checkout_checkin_missions)
  reservations.map do |reservation|
    checkout_checkin_missions << create_checkout_checkin(listing, reservation) unless booking_dates_by_listing(listing).include?(reservation[:end_date])
  end
end

def create_checkout_checkin(listing, reservation)
  {
    listing_id: listing,
    mission_type: 'checkout_checkin',
    date: reservation[:end_date],
    price: calculate_cleaning_price(reservation, 'checkout_checkin')
  }
end

def get_bookings_per_listing
  @bookings.group_by { |booking| booking[:listing_id] }
end

def get_reservations_per_listing
  @reservations.group_by { |reservation| reservation[:listing_id] }
end

def booking_dates_by_listing(listing)
  @bookings.map { |booking| booking[:end_date] if booking[:listing_id] == listing }
end

def calculate_cleaning_price(object_type, mission_type = nil)
  object_and_listing_match = @listings.select {|listing| listing[:id] == object_type[:listing_id]}
  mission_type.nil? ? object_and_listing_match[0][:num_rooms] * 10 : object_and_listing_match[0][:num_rooms] * 5
end

def generate_json(missions)
  File.open('output.json', 'wb') do |file|
    file.write(JSON.generate({"missions": missions}))
  end
end

handle_cleanings(input)
