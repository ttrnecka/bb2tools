require_relative './lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)

leagues = cfg["leagues"]

matchdays = [12]
injured_players = []
leagues.each_pair do |league,divisions|
  if !directory_exists? File.join(ROOT,"cache",league)
    puts "League #{league} has no data ... skipping"
    next
  end
  
  divisions.each_pair do |div, dlink|
    if !directory_exists?(File.join(ROOT,"cache",league,div)) || !directory_exists?(File.join(ROOT,"cache",league,div,"matches"))
      puts "Division #{league} #{div} has no data ... skipping"
      next
    end
    
    matchdays.to_a.each do |mday|
      if (matches=Dir[File.join(ROOT,"cache",league,div,"matches","Matchday #{mday}","*")]).empty?
        puts "Matchday #{mday} has no data ... skipping"
      end
      matches.each do |match|
        injured_players = injured_players.concat BB2LMProcessor.get_injured_players_from_match_report(match, no_bh:true)
      end
    end
  end  
end

keys = injured_players[0].keys
CSV.open("injured.csv", "w") do |csv|
  csv << keys
  injured_players.each do |player|
    csv << keys.map {|k| player[k]}
  end
end
