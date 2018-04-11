require '../helpers.rb'
require '../bb2_api.rb'

cfg=YAML.load_file(CFG_FILE)
api_key = cfg["api_key"]
league = "ReBBL World Cup 2018"
dir="REBBL"
exact = 0
reload_contests=true

#create api wrapper
bb2 = BB2API.new(api_key: api_key, exact: exact, league: league)

#set directories if they do not exist
create_dir dirname = File.join(ROOT,"wc2018",dir)
create_dir matches_dirname = File.join(dirname,"matches")

matches_file = File.join(dirname,"matches.json")


if reload_contests
  puts "Getting fresh contest data"
  data = bb2.get_contests(status: "played")
  #store the data
  File.open(matches_file, 'w') do |file|
    file.puts data.to_json
  end
  puts "Contest data stored"
end#get played matches

#read the file
matches_data = JSON.parse(File.read(matches_file))

#puts matches_data
matches = matches_data["upcoming_matches"]

matches.map do |match|
  uuid =  match['match_uuid']
  match_file = File.join(matches_dirname,"#{uuid}.json")
  if !File.exists? match_file
    puts "Getting match data for #{uuid}"
    match_data = bb2.get_matchdetail uuid
    File.open(match_file, 'w') do |file|
      file.puts match_data.to_json
    end
    puts "Stored match data for #{uuid}"
  else
    puts "Getting match data for #{uuid} skipped - file exists"
  end
end

