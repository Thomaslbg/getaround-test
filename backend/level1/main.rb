require 'json'
require 'date'

file = File.read("backend/level1/data/input.json")
data_hash = JSON.parse(file)

# p data_hash

# create a new hash rentals

rentals = []


# p data_hash["rentals"]
# p data_hash
# push the id of the rental
def calculator(rental_id, data_hash)
  # find hash for rental
  rental_hash = data_hash["rentals"].detect  {|h| h["id"] == rental_id }
  # find hash for car
  car_hash = data_hash["cars"].detect {|h| h["id"] == rental_hash["car_id"] }
  # p rental_hash
  # p car_hash
  # calculate numb of days
  days = (Date.parse(rental_hash["end_date"]).mjd  - Date.parse(rental_hash["start_date"]).mjd) + 1
  # days =
  # multiply it by price
  daily_price = days * car_hash["price_per_day"]
  # p daily_price
  # multiply km by price per km
  km_price = rental_hash["distance"] * car_hash["price_per_km"]

  daily_price + km_price
end


data_hash["rentals"].each do |r|
  # p r
  rentals.push ({"id" => r["id"], "price" => calculator(r["id"], data_hash) })
end


output = { "rentals" => rentals}
# create a new method called calculate
# for each ID calculate the price
  # calculate numb of days
  # multiply it by price
  # multiply km by price per km
  # sum the 2 prices
File.write('backend/level1/data/output.json', JSON.dump(output))
