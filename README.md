Commands to run project:

npm start
rails server

Generate data model:

rails generate model WeatherRecord location:string date:date temperature_max:float temperature_min:float precipitation:float
rake db:migrate

