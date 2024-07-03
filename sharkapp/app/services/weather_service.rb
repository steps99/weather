require 'open-uri'
require 'json'
require 'csv'

class WeatherService
  def self.fetch_weather(location, start_date, end_date)
    start_datetime = start_date.to_date.beginning_of_day
    end_datetime = end_date.to_date.end_of_day

    weather_records = WeatherRecord.where(location: location, date: start_datetime..end_datetime)

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

    weather_records = WeatherRecord.where(location: location, date: start_datetime..end_datetime)
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
    weather_data['hourly']['time'].each_with_index do |time_iso8601, index|
      timestamp = DateTime.parse(time_iso8601)
      WeatherRecord.create!(
        location: location,
        date: timestamp.to_datetime,
        temperature_max: weather_data['hourly']['temperature_2m'][index],
        precipitation: weather_data['hourly']['precipitation'][index]
      )
    end
  end

  def self.format_weather_data(weather_records)
    ordered_records = weather_records.order(:date)
    {
      location: weather_records.first.location,
      start_date: ordered_records.first.date.to_date,
      end_date: ordered_records.last.date.to_date,
      weather_data: {
        hourly: {
          time: ordered_records.pluck(:date),
          temperature_2m: ordered_records.pluck(:temperature_max),
          precipitation: ordered_records.pluck(:precipitation)
        }
      }
    }
  end
end
