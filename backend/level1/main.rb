require 'json'
require 'date'

json_path = 'level1/data/input.json'
# p File.read(json_path)
class Rental
  def initialize(json_path)
    file = File.read(json_path)
    @data_hash = JSON.parse(file)
  end


  def write_json
    output = generate_output
    p output
    File.write('level1/data/output.json', JSON.dump(output))
  end

  private

  def generate_output
    rentals = []

    @data_hash["rentals"].each do |r|
      rentals.push ({"id" => r["id"], "price" => calculator(r["id"], @data_hash) })
    end

    output = { "rentals" => rentals}
  end

  def calculator(rental_id, data_hash)
    # find hash for rental
    rental_hash = @data_hash["rentals"].detect  {|h| h["id"] == rental_id }
    # find hash for car
    car_hash = @data_hash["cars"].detect {|h| h["id"] == rental_hash["car_id"] }

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
end


test = Rental.new(json_path)
test.write_json
