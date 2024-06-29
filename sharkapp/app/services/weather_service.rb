require 'open-uri'
require 'json'
require 'csv'

class WeatherService
  def self.fetch_weather(location, start_date, end_date)
    weather_records = WeatherRecord.where(location: location, date: start_date..end_date)

    if weather_records.exists?
      return format_weather_data(weather_records)
    end

    latitude, longitude = get_coordinates(location)

    if latitude.nil? || longitude.nil?
      return { error: 'Location not found' }
    end

    url = "https://archive-api.open-meteo.com/v1/era5?latitude=#{latitude}&longitude=#{longitude}&start_date=#{start_date}&end_date=#{end_date}&hourly=temperature_2m,precipitation"

    response = URI.open(url)
    weather_data = JSON.parse(response.read)

    store_weather_data(location, weather_data)

    weather_records = WeatherRecord.where(location: location, date: start_date..end_date)
    format_weather_data(weather_records)
  end

  private

  def self.get_coordinates(location)
    csv_file_path = Rails.root.join('lib', 'assets', 'worldcities.csv')
    CSV.foreach(csv_file_path, headers: true) do |row|
      if row['city_ascii'].casecmp(location).zero?
        return [row['lat'].to_f, row['lng'].to_f]
      end
    end
    [nil, nil]
  end

  def self.store_weather_data(location, weather_data)
    weather_data['hourly']['time'].each_with_index do |time, index|
      WeatherRecord.create!(
        location: location,
        date: Date.parse(time),
        temperature_max: weather_data['hourly']['temperature_2m'][index],
        temperature_min: weather_data['hourly']['temperature_2m'][index],
        precipitation: weather_data['hourly']['precipitation'][index]
      )
    end
  end

  def self.format_weather_data(weather_records)
    {
      location: weather_records.first.location,
      start_date: weather_records.minimum(:date),
      end_date: weather_records.maximum(:date),
      weather_data: {
        hourly: {
          time: weather_records.pluck(:date),
          temperature_2m: weather_records.pluck(:temperature_max),
          precipitation: weather_records.pluck(:precipitation)
        }
      }
    }
  end
end
