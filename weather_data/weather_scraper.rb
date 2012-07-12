require 'open-uri'
require 'nokogiri'

# Author: Craig Russell
# Email:  craig@craig-russell.co.uk
#
# Scrapes weather data between two dates for a given location

# Location Code
# Search here for your nearest data source
# http://www.wunderground.com/history/airport/
LOCATION_CODE = 'EGXT'

# Start and end dates to scrape between (YYYY, MM, DD)
DATE_S = Date.new(2012, 1, 1)
DATE_E = Date.new(2012, 1, 5)

# The output data file
FILE_NAME = 'weather_data.csv'

#------------------------------------------------------------------------------#

# An array to hold the results
results = []

# String of field headings
headings = ''

# Loop over dates
(DATE_S..DATE_E).each do |d|

  # Get date in correct format
  # See: http://www.ruby-doc.org/core-1.9.3/Time.html#method-i-strftime
  date = d.strftime('%Y/%-m/%-e')

  # Build URL
  url = "http://www.wunderground.com/history/airport/#{LOCATION_CODE}/#{date}/DailyHistory.html"

  # Fetch document
  puts "Fetching weather data for #{d.strftime('%-e %b %Y')}..."
  doc = Nokogiri::HTML(open(url))

  # Extract figures from page
  weather  = doc.css('#historyTable span.b')
  daylight = doc.css('#astro_contain td')

  # Hash to store data for the day
  day_data                  = {}
  day_data[:date]           = d.strftime('%Y-%m-%d')
  day_data[:mean_temp]      = weather[0].content.strip
  day_data[:max_temp]       = weather[1].content.strip
  day_data[:min_temp]       = weather[4].content.strip
  day_data[:dew_point]      = weather[7].content.strip
  day_data[:precipitation]  = weather[8].content.strip
  day_data[:wind_speed]     = weather[9].content.strip
  day_data[:max_wind_speed] = weather[10].content.strip
  day_data[:visibility]     = weather[11].content.strip
  day_data[:sun_rise]       = daylight[1].content.strip
  day_data[:sun_set]        = daylight[2].content.strip
  day_data[:day_length]     = daylight[18].content.strip

  # Store headings and results
  headings = day_data.map{ |k,v| k }.join(',')
  results << day_data.map{ |k,v| v }.join(',')
end

# Save results in a file
puts "Writing data to file '#{FILE_NAME}'..."
File.open(FILE_NAME,'w')do |f| 
  f.puts "#{headings}\n"
  f.puts results.join("\n")
end