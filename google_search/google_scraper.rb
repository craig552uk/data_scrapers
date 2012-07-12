#
# Author: Craig Russell
# Email:  craig@craig-russell.co.uk
#
# A very simple scraper that fetches the titles of the first 10 results of a 
# Google search and saves them to a file
#

require 'open-uri'  # For fetching web pages
require 'nokogiri'  # For scraping the contents

# The output file
FILE_NAME = 'google_results.csv'

# An array to hold the results
results = []

# Fetch the HTML document
doc = Nokogiri::HTML(open('http://www.google.com/search?q=data%20mining'))

# Extract each result text and add to results array
doc.css('h3.r a').each{ |link| results << link.content }

# Save results in a file
File.open(FILE_NAME,'w'){ |f| f.puts results.join("\n") }