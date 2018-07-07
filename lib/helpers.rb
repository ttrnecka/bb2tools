require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'csv'
require_relative './bb2_api.rb'


ROOT = File.expand_path("..",File.dirname(__FILE__))
CFG_FILE = File.join(ROOT,"config","config.yml")

def create_dir(dirname)
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end

def directory_exists?(directory)
  File.directory?(directory)
end

class BB2LMProcessor
  class << self
    def load_file(file)
      Nokogiri::HTML(File.open(file))
    end
    
    def get_players_from_match_report(report_file)
      html_doc = load_file(report_file)
      
      tmp_split = report_file.split("/")
      league = tmp_split[-5].to_s.upcase
      division = tmp_split[-4].to_s.upcase
      matchday = tmp_split[-2].to_s.upcase
      
      #pull header
      headers = html_doc.xpath("//td[.//a[@class='teamlink']]//font").map {|p| p.text.gsub(/TV [0-9]{4}\s*/,"") }
      
      #pull teams
      #teams = html_doc.xpath("//div[contains(@id,'Roster')]/preceding-sibling::table/tr/td[@class='Teamtitle']//text()").map {|p| p.text() }
      
      #pull races
      #races = html_doc.xpath("//div[contains(@id,'Roster')]/preceding-sibling::table/tr/td[@class='Teamtitle']/following-sibling::font//text()").map {|p| p.text() }
      
      #pull coaches
      #coaches = html_doc.xpath("//div[contains(@id,'Roster')]/preceding-sibling::table/tr/td[@class='Teamtitle']/following-sibling::font/following-sibling::font//text()").map {|p| p.text() }
      
      #pull Team A names
      playersA = html_doc.xpath("//div[contains(@id,'RosterA')]/table/tr/td[2]//text()").map {|p| [league, division, matchday, headers[0],headers[1],headers[2], p.text()] }
      playersB = html_doc.xpath("//div[contains(@id,'RosterB')]/table/tr/td[2]//text()").map {|p| [league, division, matchday, headers[3],headers[4],headers[5], p.text()] }

      #pull position   
      positions = html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[3]//text()").map {|p| p.text() }
      
      #pull skills
      player_skills = html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[11]").map do |el|
        imgs = el.xpath(".//img/@title")  
        imgs.empty? ? "" : imgs.map {|i| i.value }.join(",")
      end
  
      #pull total SPPs
      total_spp =  html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[10]").map do |el| 
        el.text
      end
      #pull all injuries
      all_injuries =  html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[12]").map do |el| 
        imgs = el.xpath(".//img/@title")
        imgs.empty? ? "" : imgs.map {|i| i.value }.join(",")
      end
      
      #pull game injuries
      game_injuries =  html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[13]").map do |el| 
        imgs = el.xpath(".//img/@title")
        imgs.empty? ? "" : imgs.map {|i| i.value }.join(",")
      end
      
      players = playersA.concat playersB
      # put all into the same array
      players = players.zip(positions,player_skills,total_spp,all_injuries,game_injuries)
      
      headers = [:league, :division, :matchday, :team, :race, :coach, :name, :position, :skills, :spp,:all_injuries, :game_injuries]
      players.map! {|p| p.flatten}.map! do |p|
        Hash[headers.collect.with_index { |v,i| [v, p[i]] }]
      end
    end
    
    def get_injured_players_from_match_report(report_file,opts={})
      players = get_players_from_match_report(report_file)
      injured = players.select {|p| !p[:game_injuries].empty? }
      if opts[:no_bh]
        injured = injured.select {|p| !p[:game_injuries].match(/BadlyHurt/) }
      end
      injured
    end
    
    def get_leveledup_players_from_match_report(report_file,opts={})
      players = get_players_from_match_report(report_file)
      levels = players.select {|p| p[:skills].match(/SkillUp/) }
    end
    
    def get_match_links_from_fixture(fixture_file,opts={})
      html_doc = load_file(fixture_file)
      
      tables = html_doc.xpath("//table/tr[td[@class='round_title']]")
      results = {}
      tables.each do |t|
        day = t.text.to_sym
        results[day] = t.xpath("./following-sibling::table/tr/td/a[contains(@href,'match_detail')]/@href").map {|href| href.value}
      end

      results
    end
  end
end

module BBDirs
  private
  def set_league_dir(opts)
    dir_array = opts[:dirs] || @opts[:dirs]
    raise 'No \'dirs\' option specified' if dir_array.nil?
    #set directories if they do not exist
    create_dir @dirname = File.join(ROOT,*dir_array)
    #puts @dirname
    create_dir @matches_dirname = File.join(@dirname,"matches")
    @matches_file = File.join(@dirname,"matches.json")
  end
  
  def get_matches_dir(folder)
    File.join(ROOT,folder,"matches")
  end
end

class BB2DataProcessor
  include BBDirs
  
  def initialize(opts={})
    @opts = opts
    #set_league_dir opts
    raise "No folders options was given" if !@opts[:folders] || @opts[:folders].empty?
  end
  
  def export_player_statistics(file)
    players = {}
    @opts[:folders].each do |folder|
      matches_files = Dir.glob File.join(get_matches_dir(folder),"*")
      matches_files.each do |match_file|
        match = BB2Match.new(match_file)
        next if @opts[:ignore_leagues] && @opts[:ignore_leagues].include?(match.league)
        match.teams.each_with_index do |team,i|
          next if @opts[:ignore_teams] && @opts[:ignore_teams].include?(team['teamname'])
          team['roster'].each do |player|
            id = (player['id'].nil? ? player['name'] : player['id']).to_s.to_sym
            players[id]||={}
            stats = player['stats']
            # track last match data
            players[id]['last_update'] = match.played_at
            BB2Match::PLAYER_PARAM_LIST_STATIC.each do |item|
              next if match.played_at < players[id]['last_update'] 
              players[id][item] = player[item].kind_of?(Array) ? players[id][item] = player[item].join(",") : player[item].nil? ? "" : player[item]
            end
            BB2Match::PLAYER_PARAM_LIST_DYNAMIC.each do |item|
              players[id][item] = players[id.to_sym][item].nil? ? 0+stats[item] : players[id.to_sym][item]+stats[item] 
            end
          end
        end
      end
    end
    CSV.open(file, "w") do |csv|
      full_keys = BB2Match.player_params + ["last_update"]
      csv << full_keys
      players.each do |key, player|
        csv << full_keys.map {|k| player[k]}
      end
    end
  end
  
  def export_team_statistics(file)
    teams = {}
    @opts[:folders].each do |folder|
      matches_files = Dir.glob File.join(get_matches_dir(folder),"*")
      matches_files.each do |match_file|
        match = BB2Match.new(match_file)
        next if @opts[:ignore_leagues] && @opts[:ignore_leagues].include?(match.league)
        match.teams.each_with_index do |team,i|
          next if @opts[:ignore_teams] && @opts[:ignore_teams].include?(team['teamname'])
          id = team['idteamlisting'].to_s.to_sym
          teams[id]||={}
          teams[id]['last_update'] = teams[id]['last_update'] && teams[id]['last_update']>match.played_at ? teams[id]['last_update'] : match.played_at
          BB2Match::TEAM_PARAM_LIST_STATIC.each do |item| 
              next if match.played_at < teams[id]['last_update'] 
              teams[id][item] = team[item]
          end
          BB2Match::TEAM_PARAM_LIST_DYNAMIC.each do |item|
            teams[id][item] = teams[id.to_sym][item].nil? ? 0+team[item] : teams[id.to_sym][item]+team[item] 
          end
        end
      end
    end
    
    CSV.open(file, "w") do |csv|
      full_keys = BB2Match.team_params + ["last_update"]
      csv << full_keys
      teams.each do |key, team|
        csv << full_keys.map {|k| team[k]}
      end
    end
  end
  
  def export_game_statistics(file)
    games = {}
    @opts[:folders].each do |folder|
      matches_files = Dir.glob File.join(get_matches_dir(folder),"*")
      matches_files.each do |match_file|
        match = BB2Match.new(match_file)
        next if @opts[:ignore_leagues] && @opts[:ignore_leagues].include?(match.league)
        next if @opts[:ignore_teams] && @opts[:ignore_teams].include?(match.team_home['teamname'])
        next if @opts[:ignore_teams] && @opts[:ignore_teams].include?(match.team_visitor['teamname'])
        id = match.data['uuid']
        games[id]||={}
        games[id][:league] = match.data['match']['leaguename']
        games[id][:competition] = match.data['match']['competitionname']
        games[id][:played_at] = match.played_at
        # home
        games[id][:home_coach] = match.coach_home['coachname']
        games[id][:home_team] = match.team_home['teamname']
        games[id][:home_score] = match.team_home['score']
        # home
        games[id][:visitor_coach] = match.coach_visitor['coachname']
        games[id][:visitor_team] = match.team_visitor['teamname']
        games[id][:visitor_score] = match.team_visitor['score']
      end
    end
    
    CSV.open(file, "w") do |csv|
      full_keys = [:league,:competition,:played_at, :home_coach,:home_team,:home_score,:visitor_score,:visitor_team,:visitor_coach]
      csv << full_keys
      games.each do |key, team|
        csv << full_keys.map {|k| team[k]}
      end
    end
  end
end

class BB2APICollector
  include BBDirs
  def initialize(opts={})
    @opts = opts
    set_league_dir opts
    @agent = BB2API.new(@opts)
  end
  
  def collect_league_matches_with_detail(opts={})
    collect_matches(opts)
    matches_data = JSON.parse(File.read(@matches_file))

    #puts matches_data
    matches = matches_data["upcoming_matches"]
    
    matches.map do |match|
      uuid =  match['match_uuid']
      match_file = File.join(@matches_dirname,"#{uuid}.json")
      if !File.exists? match_file
        puts "Getting match data for #{uuid}"
        match_data = @agent.get_matchdetail uuid
        File.open(match_file, 'w') do |file|
          file.puts match_data.to_json
        end
        puts "Stored match data for #{uuid}"
      else
        puts "Getting match data for #{uuid} skipped - file exists"
      end
    end
  end
  
  def collect_matches(opts)
    set_league_dir opts
    #get all matches
    if @opts[:reload_contest]
      puts "Getting fresh contest data"
      data = @agent.get_contests(status: @opts[:status])
      #store the data
      File.open(@matches_file, 'w') do |file|
        file.puts data.to_json
      end
      puts "Contest data stored"
    end
  end
end

class BB2Match
  attr_reader :data
  
  TEAM_PARAM_LIST_STATIC = [
    "league","competition","coach", "teamname", "race"
  ]
  TEAM_PARAM_LIST_DYNAMIC = [
    "matches", "score", "possessionball", "occupationown", "occupationtheir", "inflictedpasses", "inflictedcatches", "inflictedinterceptions", "inflictedtouchdowns",
    "inflictedcasualties", "inflictedtackles", "inflictedko", "inflictedinjuries", "inflicteddead", "inflictedmetersrunning", "inflictedmeterspassing", "inflictedpushouts",
    "sustainedtouchdowns", "sustainedexpulsions", "sustainedcasualties", "sustainedko", "sustainedinjuries", "sustaineddead", "win", "draw", "loss", "points","xp_gain","levelups"
  ]
  
  PLAYER_PARAM_LIST_STATIC = [
    "league","competition","coach", "teamname", "race", "number", "type", "name", "skills", "casualties_state", "casualties_sustained"
  ]
  
  PLAYER_PARAM_LIST_DYNAMIC = [
    "matches","inflictedcasualties", "inflictedstuns", "inflictedpasses", "inflictedmeterspassing", "inflictedtackles", "inflictedko", "inflicteddead", "inflictedinterceptions", 
    "inflictedpushouts", "inflictedcatches", "inflictedinjuries", "inflictedmetersrunning", "inflictedtouchdowns", "sustainedinterceptions", "sustainedtackles", 
    "sustainedinjuries", "sustaineddead", "sustainedko", "sustainedcasualties", "sustainedstuns","xp","xp_gain","levelups"
  ]
  
  RACES = [
    "0","Human","Dwarf","Skaven","Orc","Lizardman","Goblin","WoodElf","Chaos","DarkElf","Undead","Halfling","Norse","Amazon","ProElf","HighElf","Khemri","Necromantic",
    "Nurgle","Ogre","Vampire","ChaosDwarf","Underworld","23","Bretonnia","Kislev"
  ]
  
  def self.team_params
    TEAM_PARAM_LIST_STATIC + TEAM_PARAM_LIST_DYNAMIC
  end
  
  def self.player_params
    PLAYER_PARAM_LIST_STATIC + PLAYER_PARAM_LIST_DYNAMIC
  end
  
  def initialize(file)
    @data = load_file file
    process_extra
  end
  
  def team_home
    teams[0]
  end
  
  def team_visitor
    teams[1]
  end
  
  def teams
    @data['match']['teams']
  end
  
  def coach_home
    coaches[0]
  end
  
  def coach_visitor
    coaches[1]
  end
  
  def coaches
    @data['match']['coaches']
  end
  
  def players_home
    team_home['roster']
  end
  
  def players_visitor
    team_visitor['roster']
  end
  
  def played_at
    @data['match']['started']
  end
  
  def league
    @data['match']['leaguename']
  end
 
  def competition
    @data['match']['competitionname']
  end 
  
  private
  def load_file(file)
    raise "Match file #{file} does not exists" if !File.exist? file
    JSON.parse(File.read(file))
  end
  
  def process_extra
    process_players
    process_team
  end 
  
  def process_team
    if team_home['score'] > team_visitor['score']
      tmp_team_home_data = { 'win' => 1, 'draw' => 0, 'loss' => 0, 'points' => 3 }
      tmp_team_visitor_data = { 'win' => 0, 'draw' => 0, 'loss' => 1, 'points' => 0 }
    elsif team_home['score'] == team_visitor['score']
      tmp_team_home_data = { 'win' => 0, 'draw' => 1, 'loss' => 0, 'points' => 1 }
      tmp_team_visitor_data = { 'win' => 0, 'draw' => 1, 'loss' => 0, 'points' => 1 }
    else
      tmp_team_home_data = { 'win' => 0, 'draw' => 0, 'loss' => 1, 'points' => 0 }
      tmp_team_visitor_data = { 'win' => 1, 'draw' => 0, 'loss' => 0, 'points' => 3 }
    end 
      
    tmp_team_home_data['sustainedtouchdowns']=team_visitor['inflictedtouchdowns']
    tmp_team_visitor_data['sustainedtouchdowns']=team_home['inflictedtouchdowns']
    tmp_team_home_data['matches']=1
    tmp_team_visitor_data['matches']=1
    tmp_team_home_data['race']=RACES[team_home['idraces']]
    tmp_team_visitor_data['race']=RACES[team_visitor['idraces']]
    
    #workaround for inflicted pushouts bug
    teams.each_with_index do |team,i|
      #workaround for inflicted pushouts bug
      team["inflictedpushouts"] = team['roster'].map {|item| item['stats']['inflictedpushouts']}.reduce(:+)
      # league and division
      team["league"] = @data['match']['leaguename']
      team["competition"] = @data['match']['competitionname']
      team['coach'] = coaches[i]['coachname']
      #levelups
      team["levelups"] = team['roster'].map {|item| item['stats']['levelups']}.reduce(:+)
      #xp_gain
      team["xp_gain"] = team['roster'].map {|item| item['stats']['xp_gain']}.reduce(:+)
      
    end
   
    team_home.merge! tmp_team_home_data
    team_visitor.merge! tmp_team_visitor_data
  end
  
  def process_players
    players_home.each do |player|
      player['coach'] = coach_home['coachname']
      player['teamname'] = team_home['teamname']
      player['stats']['matches'] = 1
      player['stats']['levelups'] = levels_up(player)
      player['stats']['xp_gain'] = player['xp_gain']
      player['stats']['xp'] = player['xp']
      player['race']=RACES[team_home['idraces']]
      player["league"] = @data['match']['leaguename']
      player["competition"] = @data['match']['competitionname']
    end
    
    players_visitor.each do |player|
      player['coach'] = coach_visitor['coachname']
      player['teamname'] = team_visitor['teamname']
      player['stats']['matches'] = 1
      player['stats']['levelups'] = levels_up(player)
      player['stats']['xp_gain'] = player['xp_gain']
      player['stats']['xp'] = player['xp']
      player['race']=RACES[team_visitor['idraces']]
      player["league"] = @data['match']['leaguename']
      player["competition"] = @data['match']['competitionname']
    end
  end
  
  def levels_up (player)
    new_level = lookup_level(player['xp'].to_i+player['xp_gain'].to_i)
    levelups = new_level - player['level'].to_i
    #fix for level 2 journeyman
    levelups = 0 if levelups < 0 
    return levelups
  end
  
  def lookup_level(spp)
    case
    when spp < 6
      return 1
    when spp < 16
      return 2
    when spp < 31
      return 3
    when spp < 51
      return 4
    when spp < 76
      return 5
    when spp < 176
      return 6
    else return 7
    end
  end
end