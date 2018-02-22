require 'yaml'
require 'nokogiri'
require 'open-uri'
require './helpers.rb'

cfg=YAML.load_file(CFG_FILE)

leagues = cfg["leagues"]

leagues.each_pair do |league,divisions|
  #create the league directory
  create_dir File.join(ROOT,"cache",league)
  
  puts "Pulling #{league.upcase}"
  
  divisions.each_pair do |div, dlink|
    #create the div directory
    create_dir dirname = File.join(ROOT,"cache",league,div)
    
    puts "\tPulling fixture"
    
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
      sleep 0.5
    else
      puts "\t\tPulling #{div.upcase} ... Cancelled - recent file exists" 
    end
    
    puts "\t\tPulling new matches"
    match_links = BB2LMProcessor.get_match_links_from_fixture(fixtures_file)
    
    create_dir dirname = File.join(ROOT,"cache",league,div,"matches")
    match_links.each_pair do |day,matches|
      create_dir dirname = File.join(ROOT,"cache",league,div,"matches",day.to_s)
      puts "\t\t  Pulling #{day}"
      matches.each do |mlink|
        match_uuid = mlink.match(/match_uuid=(.*)/)
        match_file = File.join(dirname,"match_#{$1}.html")
        if !File.exists?(match_file)
          print "\t\t    Pulling match #{$1}"
          full_match_link = "http://www.bb2leaguemanager.com/Leaderboard/#{mlink}"
          tmpfile = open(full_match_link,
            "User-Agent" => "Ruby/#{RUBY_VERSION}"
          )
          IO.copy_stream(tmpfile, match_file)
          puts " ... Done"
          sleep 0.5
        else
          puts "\t\t    Pulling match #{$1} ... Cancelled - file exists" 
        end
      end
    end
  end  
end