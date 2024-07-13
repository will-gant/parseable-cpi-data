from flask import Flask, jsonify
import requests
from datetime import datetime
import calendar

app = Flask(__name__)

@app.route('/health')
def health():
    return 'OK', 200

@app.route('/')
def root():
    url = 'https://www.ons.gov.uk/economy/inflationandpriceindices/timeseries/d7bt/mm23/data'
    response = requests.get(url)
    data = response.json()
    
    cpi_data = []
    
    for item in data['months']:
        try:
            year = int(item['year'])
            month = item['month']
            month_number = list(calendar.month_name).index(month)
            last_day = calendar.monthrange(year, month_number)[1]
            date_iso = datetime(year, month_number, last_day).isoformat()
            value = float(item['value'])
            cpi_data.append({'date': date_iso, 'value': value})
        except (ValueError, IndexError):
            continue
    
    return jsonify({'cpi': cpi_data})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
