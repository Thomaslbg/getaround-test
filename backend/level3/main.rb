require 'json'
require 'date'

json_path = 'level3/data/input.json'
# p File.read(json_path)
class Rental
  def initialize(json_path)
    file = File.read(json_path)
    @data_hash = JSON.parse(file)
  end

  def write_json
    output = generate_output
    p output
    File.write('level3/data/output.json', JSON.pretty_generate(output))
  end

  private

  def generate_output
    rentals = []

    @data_hash['rentals'].each do |r|
      rentals.push ({ 'id' => r['id'],
                      'price' => calculator(r['id'], @data_hash)['price'],
                      'commission' => calculator(r['id'], @data_hash)['commission']
                    })
    end

    { 'rentals' => rentals}
  end

  def decreasing_price(days, basic_price)
    price_arr = []
    days.times { price_arr << basic_price }
    price_arr = price_arr.map.each_with_index do | pr, ix |
      case ix
      when 0 then pr
      when 1..3 then pr * 0.9
      when 4..9 then pr * 0.7
      else pr * 0.5
      end
    end.sum.to_i
  end

  def calculator(rental_id, data_hash)
    rental_hash = @data_hash['rentals'].detect { |h| h['id'] == rental_id }
    car_hash = @data_hash['cars'].detect { |h| h['id'] == rental_hash['car_id'] }
    days = (Date.parse(rental_hash['end_date']).mjd - Date.parse(rental_hash['start_date']).mjd) + 1
    basic_price = car_hash['price_per_day']
    daily_price = decreasing_price(days, basic_price)
    km_price = rental_hash['distance'] * car_hash['price_per_km']
    price = daily_price + km_price
    commission = commission(price, days)
    p commission
    {'price' => price, "commission" => commission}
  end

  def commission(price, days)
    insurance_fee = (price * 0.3) / 2
    assistance_fee = days * 100
    drivy_fee = (price * 0.3) - assistance_fee - insurance_fee

    { "insurance_fee" => insurance_fee.to_i, "assistance_fee" => assistance_fee.to_i, "drivy_fee" => drivy_fee.to_i }
  end
end


test = Rental.new(json_path)
test.write_json
