class CreateWeatherRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :weather_records do |t|
      t.string :location
      t.datetime :date
      t.float :temperature_max
      t.float :precipitation

      t.timestamps
    end
  end
end
