require 'json'
require 'date'

json_path = 'level5/data/input.json'
OPTIONS_PRICE = { 'gps' => 500, 'baby_seat' => 200, 'additional_insurance' => 1000 }

class Rental
  def initialize(json_path)
    file = File.read(json_path)
    @data_hash = JSON.parse(file)
    @options = @data_hash['options']
    @price_hash = generate_price_hash
    @payment_hash = generate_payment_hash
  end



  def write_price_json
    File.write('level5/data/output.json', JSON.pretty_generate(@price_hash))
  end

  def write_payment_json
    File.write('level5/data/output.json', JSON.pretty_generate(@payment_hash))
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
      actions = generate_actions(r)
      options = generate_options(r)
      if options['options'].any?
        options_fees = generate_options_fees(r["id"], options)
        actions = add_options_fees_to_actions(actions, options_fees)
      end
      rentals.push ({ 'id' => r['id'],'options' => options, 'actions' => actions })
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
    days = calc_days(rental_hash['start_date'], rental_hash['end_date'])
    basic_price = car_hash['price_per_day']
    daily_price = decreasing_price(days, basic_price)
    km_price = rental_hash['distance'] * car_hash['price_per_km']
    price = daily_price + km_price
    commission = commission(price, days)
    {'price' => price, "commission" => commission}
  end

  def calc_days(start_date, end_date)
    (Date.parse(end_date).mjd - Date.parse(start_date).mjd) + 1
  end

  def commission(price, days)
    insurance_fee = (price * 0.3) / 2
    assistance_fee = days * 100
    drivy_fee = (price * 0.3) - assistance_fee - insurance_fee
    { "insurance_fee" => insurance_fee.to_i, "assistance_fee" => assistance_fee.to_i, "drivy_fee" => drivy_fee.to_i }
  end

  def generate_actions(r)
      actions = []
      actions << generate_actions_hash('driver', 'debit', r['price'])
      actions << generate_actions_hash('owner', 'credit', owner_payment(r))
      actions << generate_actions_hash('insurance', 'credit', r['commission']['insurance_fee'])
      actions << generate_actions_hash('assistance', 'credit', r['commission']['assistance_fee'])
      actions << generate_actions_hash('drivy', 'credit', r['commission']['drivy_fee'])
  end

  def generate_actions_hash(who, type, amount)
    { 'who' => who, 'type' => type, 'amount' => amount }
  end

  def generate_options(r)
    rental_options = @options.select { |o| o['rental_id'] == r['id'] }
    {'options' => rental_options.map{|r| r['type']}}
  end

  def generate_options_fees(rental_id, options)
    rental_hash = @data_hash['rentals'].detect { |h| h['id'] == rental_id }
    days = calc_days(rental_hash['start_date'], rental_hash['end_date'])
    options_fees = []
    options['options'].each do |o|
      options_fees << {o => OPTIONS_PRICE[o] * days}
    end
    options_fees
  end

  def add_options_fees_to_actions(actions, options_fees)
    p options_fees
    p actions
    options_fees.each do |o|
      actions[0]['amount'] += o.values[0] if o.keys[0] == 'gps' || o.keys[0] == 'baby_seat' || o.keys[0] == 'additional_insurance'
      actions[1]['amount'] += o.values[0] if o.keys[0] == 'gps' || o.keys[0] == 'baby_seat'
      actions[2]['amount'] += o.values[0] if o.keys[0] == 'additional_insurance'
    end
    p actions
  end

  def owner_payment(price_hash)
    payment = price_hash['price'] - price_hash['commission'].values.sum
  end
end




test = Rental.new(json_path)
test.write_payment_json
