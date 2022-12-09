require 'json'
require 'date'

json_path = 'level4/data/input.json'

class Rental
  def initialize(json_path)
    file = File.read(json_path)
    @data_hash = JSON.parse(file)
    @price_hash = generate_price_hash
    @payment_hash = generate_payment_hash
  end


  def write_price_json
    File.write('level4/data/output.json', JSON.pretty_generate(@price_hash))
  end

  def write_payment_json
    File.write('level4/data/output.json', JSON.pretty_generate(@payment_hash))
  end


  private

  def generate_price_hash
    rentals = []

    @data_hash['rentals'].each do |r|
      rentals.push ({ 'id' => r['id'],
                      'price' => calculator(r['id'])['price'],
                      'commission' => calculator(r['id'])['commission']
                    })
    end
    { 'rentals' => rentals}
  end

  def generate_payment_hash
    rentals = []

    @price_hash['rentals'].each do |r|
      actions = []
      actions << generate_actions('driver', 'debit', r['price'])
      actions << generate_actions('owner', 'credit', owner_payment(r))
      actions << generate_actions('insurance', 'credit', r['commission']['insurance_fee'])
      actions << generate_actions('assistance', 'credit', r['commission']['assistance_fee'])
      actions << generate_actions('drivy', 'credit', r['commission']['drivy_fee'])
      rentals.push ({ 'id' => r['id'], 'actions' => actions })
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

  def calculator(rental_id)
    rental_hash = @data_hash['rentals'].detect { |h| h['id'] == rental_id }
    car_hash = @data_hash['cars'].detect { |h| h['id'] == rental_hash['car_id'] }
    days = (Date.parse(rental_hash['end_date']).mjd - Date.parse(rental_hash['start_date']).mjd) + 1
    basic_price = car_hash['price_per_day']
    daily_price = decreasing_price(days, basic_price)
    km_price = rental_hash['distance'] * car_hash['price_per_km']
    price = daily_price + km_price
    commission = commission(price, days)
    {'price' => price, "commission" => commission}
  end

  def commission(price, days)
    insurance_fee = (price * 0.3) / 2
    assistance_fee = days * 100
    drivy_fee = (price * 0.3) - assistance_fee - insurance_fee
    { "insurance_fee" => insurance_fee.to_i, "assistance_fee" => assistance_fee.to_i, "drivy_fee" => drivy_fee.to_i }
  end

  def generate_actions(who, type, amount)
    { 'who' => who, 'type' => type, 'amount' => amount }
  end

  def owner_payment(price_hash)
    price_hash['price'] - price_hash['commission'].values.sum
  end
end




test = Rental.new(json_path)
test.write_payment_json
