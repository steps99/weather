import React, { useState } from 'react';
import { Line } from 'react-chartjs-2';
import 'chart.js/auto';
import 'bootstrap/dist/css/bootstrap.min.css';

function WeatherForm() {
  const [location, setLocation] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [weatherData, setWeatherData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchWeather = async () => {
    if (!validateDates(startDate, endDate)) {
      return;
    }

    setLoading(true);
    setError('');
    setWeatherData(null);

    try {
      const response = await fetch(`http://localhost:3000/api/v1/weather?location=${location}&start_date=${startDate}&end_date=${endDate}`);
      const data = await response.json();
      if (data.error) {
        setError(data.error);
      } else {
        setWeatherData(data);
      }
    } catch (err) {
      setError('Failed to fetch weather data');
    }

    setLoading(false);
  };

  const validateDates = (start, end) => {
    const startDate = new Date(start);
    const endDate = new Date(end);
    const today = new Date();

    if (startDate > endDate) {
      setError('Start date cannot be later than end date.');
      return false;
    }

    if (startDate > today || endDate > today) {
      setError('Dates cannot be in the future.');
      return false;
    }

    return true;
  };

  const getChartData = () => {
    if (!weatherData || weatherData.error) return null;

    const labels = weatherData.weather_data.hourly.time.map(time => new Date(time).toLocaleString());
    const temperatures = weatherData.weather_data.hourly.temperature_2m;

    return {
      labels,
      datasets: [
        {
          label: 'Temperature (°C)',
          data: temperatures,
          fill: false,
          borderColor: 'rgba(75, 192, 192, 1)',
          tension: 0.1
        }
      ]
    };
  };

  return (
    <div className="container mt-5">
      <h1 className="mb-4">Weather Information</h1>
      <form onSubmit={(e) => { e.preventDefault(); fetchWeather(); }}>
        <div className="mb-3">
          <label className="form-label">Location:</label>
          <input type="text" className="form-control" value={location} onChange={(e) => setLocation(e.target.value)} required />
        </div>
        <div className="mb-3">
          <label className="form-label">Start Date:</label>
          <input type="date" className="form-control" value={startDate} onChange={(e) => setStartDate(e.target.value)} required />
        </div>
        <div className="mb-3">
          <label className="form-label">End Date:</label>
          <input type="date" className="form-control" value={endDate} onChange={(e) => setEndDate(e.target.value)} required />
        </div>
        <button type="submit" className="btn btn-primary">Get Weather</button>
      </form>
      {loading && <div className="alert alert-info mt-3">Loading...</div>}
      {error && <div className="alert alert-danger mt-3">{error}</div>}
      {weatherData && !error && (
        <div className="mt-5">
          <h2>Weather Data</h2>
          <div className="mb-4">
            <h3>Temperature Over Time</h3>
            <Line data={getChartData()} />
          </div>
          <div>
            <h3>Weather Data Table</h3>
            <table className="table table-striped">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Temperature (°C)</th>
                  <th>Precipitation (mm)</th>
                </tr>
              </thead>
              <tbody>
                {weatherData.weather_data.hourly.time.map((time, index) => (
                  <tr key={`${time}-${index}`}>
                    <td>{new Date(time).toLocaleString()}</td>
                    <td>{weatherData.weather_data.hourly.temperature_2m[index]}</td>
                    <td>{weatherData.weather_data.hourly.precipitation[index]}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

export default WeatherForm;
