module Api
  module V1
    class WeatherController < ApplicationController
      def show
        location = params[:location]
        start_date = params[:start_date]
        end_date = params[:end_date]

        weather_data = WeatherService.fetch_weather(location, start_date, end_date)

        render json: weather_data
      end
    end
  end
end
