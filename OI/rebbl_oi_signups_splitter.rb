require_relative '../lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)
@processed_file="processed.yml"
if  File.exists? @processed_file
    @processed=YAML.load_file(@processed_file) 
else
    @processed = []
end
    
opts = {
    api_key: cfg["api_key"],
}

splitter = [10,19]
match_inc = 0

teams = {
    :seasoned => [],
    :fresh => [],
    :eg => []
}
# file obtained from https://rebbl.net/api/v1/oi
oi_file = "oi.csv"

@api = BB2API.new(opts)

oi_text = File.read(oi_file).gsub(/\\"/,'""').gsub(/\\t/,'')

def process_row(row)
    row = row.to_hash
    puts "getting #{row["team name"]} info"
    # pulls the data from cache if exists
    if (team=@processed.select {|r| r["team name"]==row["team name"]}).length>0 
        puts "found cached"
        row = team[0]
    else
    # else pull from API and store in cache
        puts "pulling from API"
        team = @api.get_team(:name => row["team name"], :order => "CreationDate")
        team_uuid = team["team"]["id"]
        matches = @api.get_teammatches(:team_id => team_uuid, :start => "20150101"  )
        last_match_uuid = matches["matches"].map {|m| m["uuid"]}.sort.last
        match_data = @api.get_matchdetail(last_match_uuid)
        row["last match time"]=team["team"]["datelastmatch"]
        row["last division"]="#{match_data["match"]["leaguename"]} #{match_data["match"]["competitionname"]}"
        row["matches count"] = matches["matches"].count
        @processed << row
        #saves
        puts "saving cached file"
        File.write(@processed_file, @processed.uniq.to_yaml)
    end
    return row
end

CSV.parse(oi_text, :headers => true) do |row|
    @headers = row.headers + ["last match time","last division","matches count"]
    row = process_row row
    puts row["matches count"]
    case row["matches count"]
    when 0..(splitter[0]+match_inc)
        teams[:eg] << row.to_hash
    when (splitter[0]+match_inc)..(splitter[1]+match_inc)
        teams[:fresh] << row.to_hash
    else
        teams[:seasoned] << row.to_hash
    end
end

  CSV.open("OI_seasoned.csv", "w") do |csv|
    csv << @headers
    teams[:seasoned].each do |team|
      csv << @headers.map {|k| team[k]}
    end
  end

  CSV.open("OI_fresh.csv", "w") do |csv|
    csv << @headers
    teams[:fresh].each do |team|
        csv << @headers.map {|k| team[k]}
    end
  end

  CSV.open("OI_eg.csv", "w") do |csv|
    csv << @headers
    teams[:eg].each do |team|
        csv << @headers.map {|k| team[k]}
    end
  end
  