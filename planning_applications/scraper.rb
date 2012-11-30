#
# author: Craig Russell
# email: craig@craig-russell.co.uk
#
# Scraper to extract planning application data from Hammersmith & Fulham web site
# in response to question posted on discussion forum
# https://groups.google.com/d/topic/scraperwiki/N1Cz64aKtMA/discussion
#
# There is no directory listing of all applications on the site.
# Though there is a form to list for applications by week
# http://www.apps.lbhf.gov.uk/PublicAccess/tdc/DcApplication/weeklylist_searchform.aspx
#
# I noticed that the dates can be changed to search within a wider time period
# Adjust the START_DATE and END_DATE configuration params as you like
#
# The search form does refuse to return a large number of results.
# If this happens try searching over a smaller date range.
#
# You can also search by validated or decided applications
# Adjust the APPLICATION_TYPE param to change this
#
# The results will be written out in CSV format to the end of OUTPUT_FILE
#
# If you have trouble with either of the dependancies have a look at the documentation on their sites.
# I built this using ruby 1.9.3

### Dependencies ###

require 'httpclient' # https://github.com/nahi/httpclient
require 'nokogiri'   # http://nokogiri.org/


### Configuration ###

# Start and end dates for search period
# must be in DD/MM/YYYY format
START_DATE = '01/11/2012'
END_DATE   = '01/12/2012'

# Application type
# DEC = decided applications
# VAL = validated applications
APPLICATION_TYPE = 'DEC'

# The data file to write to
OUTPUT_FILE = 'planning_addresses.csv'


### Methods ###

# Save records from a NokoGiri doc to file
def save_records(doc, file)
  doc.css('.cResultsForm tr').each do |tr|
    line = tr.css('td').map{ |td| "\"#{td.content.gsub(/"/,'').strip}\""}.join(',')
    file.write "#{line}\n" unless line.empty?
  end
end

# Wrapper for querying the form and parsing the response
def post_to_form(params)
  http = @client.post SEARCH_URL, params
  # Drop carridge returns, line breaks and tabs so NokoGiri can parse it correctly
  Nokogiri::HTML http.content.gsub(/[\r\n\t]/, ' ')
end

### MAIN ###

# The search form URL
SEARCH_URL = "http://www.apps.lbhf.gov.uk/PublicAccess/tdc/DcApplication/application_searchresults.aspx"

# Create and configure a HTTP Client
@client = HTTPClient.new
@client.set_cookie_store('cookie.dat')

# Open a file to write to
@output_file = file = File.open(OUTPUT_FILE, 'a')

# Search for properties on this steeet
doc = post_to_form :selWeeklyListRange => "#{START_DATE}|#{END_DATE}",
                   :searchType => 'WEEKLY',
                   :weekType => APPLICATION_TYPE

begin

  # Get number of results and pages
  meta_text = doc.css('.cFormContent').first.content.gsub(/[^a-zA-Z0-9 ]/, ' ').split(' ')
  num_results = meta_text[0].to_i
  num_pages   = meta_text[8].to_i
  puts "Found #{num_results} results over #{num_pages} pages"

  # Save the records on the first page to file
  puts "Saving page 1 of results"
  save_records doc, @output_file

  # Get subsequent pages of records and save them
  page = 2
  while (page <= num_pages)
    puts "Saving page #{page} of results"
    doc = post_to_form :currentpage => page, :pagesize => 10, :module => 'P3'
    save_records doc, @output_file
    page += 1
  end

rescue Exception
  puts "The search failed. There are probably too many results."
  puts "Try searching over a shorter time period."
end

# Close the file
@output_file.close