require 'yaml'
require 'nokogiri'
require 'open-uri'
require './helpers.rb'

cfg=YAML.load_file(CFG_FILE)

leagues = cfg["leagues"]

puts "Pulling fixtures"
leagues.each_pair do |league,divisions|
  #create the league directory
  create_dir File.join(ROOT,"cache",league)
  
  puts "\tPulling #{league.upcase}"
  
  divisions.each_pair do |div, dlink|
    #create the div directory
    create_dir dirname = File.join(ROOT,"cache",league,div)
    
    fixtures_file = File.join(dirname,"fixtures.html")
    if dlink.nil?
      puts "\t\tPulling #{div.upcase} ... Cancelled - no link provided"
      next 
    end
    if !File.exists?(fixtures_file) || File.mtime(fixtures_file) - Time.now > 86400
      print "\t\tPulling #{div.upcase}"
      tmpfile = open(dlink,
        "User-Agent" => "Ruby/#{RUBY_VERSION}"
      )
      IO.copy_stream(tmpfile, fixtures_file)
      puts " ... Done"
    else
      puts "\t\tPulling #{div.upcase} ... Cancelled - recent file exists" 
    end
  end  
end