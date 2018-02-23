require './helpers.rb'

cfg=YAML.load_file(CFG_FILE)

leagues = cfg["leagues"]

matchdays = [1]
leveled_players = []
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
        leveled_players = leveled_players.concat BB2LMProcessor.get_leveledup_players_from_match_report(match)
      end
    end
  end  
end

keys = leveled_players[0].keys
CSV.open("levelups.csv", "w") do |csv|
  csv << keys
  leveled_players.each do |player|
    csv << keys.map {|k| player[k]}
  end
end
