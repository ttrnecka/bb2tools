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

class BB2APIProcessor
  UNTRACKED_PARAMS_LIST = [
    "coach",
    "teamname",
    "race",
    "matches"
  ]
  TRACKED_PARAMS_LIST = [
    "score",
    "possessionball",
    "occupationown",
    "occupationtheir",
    "inflictedpasses",
    "inflictedcatches",
    "inflictedinterceptions",
    "inflictedtouchdowns",
    "inflictedcasualties",
    "inflictedtackles",
    "inflictedko",
    "inflictedinjuries",
    "inflicteddead",
    "inflictedmetersrunning",
    "inflictedmeterspassing",
    "inflictedpushouts",
    "sustainedtouchdowns",
    "sustainedexpulsions",
    "sustainedcasualties",
    "sustainedko",
    "sustainedinjuries",
    "sustaineddead",
    "win",
    "draw",
    "loss",
    "points"
  ]
  
  def initialize(opts={})
    @opts = opts
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
  
  def export_team_statistics(file)
    matches_files = Dir.glob File.join(@matches_dirname,"*")
    teams = {}
    top_level_data = JSON.parse(File.read(@matches_file))
    top_level_data["upcoming_matches"].each do |match|
      match['opponents'].each do |oppo|
        id = oppo['team']['id'].to_s.to_sym
        teams[id]||={}
        teams[id]['race'] = oppo['team']['race']
      end
    end
    matches_files.each do |match_file|
      match_data = JSON.parse(File.read(match_file))
      if match_data['match']['teams'][0]['score'] > match_data['match']['teams'][1]['score']
        match_data['match']['teams'][0]['win']=1
        match_data['match']['teams'][0]['draw']=0
        match_data['match']['teams'][0]['loss']=0
        match_data['match']['teams'][0]['points']=3
        match_data['match']['teams'][1]['win']=0
        match_data['match']['teams'][1]['draw']=0
        match_data['match']['teams'][1]['loss']=1
        match_data['match']['teams'][1]['points']=0
      elsif match_data['match']['teams'][0]['score'] == match_data['match']['teams'][1]['score']
        match_data['match']['teams'][0]['win']=0
        match_data['match']['teams'][0]['draw']=1
        match_data['match']['teams'][0]['loss']=0
        match_data['match']['teams'][0]['points']=1
        match_data['match']['teams'][1]['win']=0
        match_data['match']['teams'][1]['draw']=1
        match_data['match']['teams'][1]['loss']=0
        match_data['match']['teams'][1]['points']=1
      else
        match_data['match']['teams'][0]['win']=0
        match_data['match']['teams'][0]['draw']=0
        match_data['match']['teams'][0]['loss']=1
        match_data['match']['teams'][0]['points']=0
        match_data['match']['teams'][1]['win']=1
        match_data['match']['teams'][1]['draw']=0
        match_data['match']['teams'][1]['loss']=0
        match_data['match']['teams'][1]['points']=3
      end 
      
      match_data['match']['teams'][0]['sustainedtouchdowns']=match_data['match']['teams'][1]['inflictedtouchdowns']
      match_data['match']['teams'][1]['sustainedtouchdowns']=match_data['match']['teams'][0]['inflictedtouchdowns']
      
      match_data['match']['teams'].each_with_index do |team,i|
        id = team['idteamlisting'].to_s.to_sym
        teams[id]||={}
        teams[id]['coach'] ||= match_data['coaches'][i]['name']
        teams[id]['teamname'] ||= team['teamname']
        teams[id]['matches'] ||= 0
        teams[id]['matches'] += 1 
        TRACKED_PARAMS_LIST.each do |item|
          teams[id][item] = teams[id.to_sym][item].nil? ? 0+team[item] : teams[id.to_sym][item]+team[item] 
        end
        
        #workaround for inflicted pushouts
        if TRACKED_PARAMS_LIST.include? "inflictedpushouts"
          pushouts = team['roster'].map {|item| item['stats']['inflictedpushouts']}.reduce(:+)
          teams[id]["inflictedpushouts"] = teams[id.to_sym]['inflictedpushouts'].nil? ? 0+pushouts : teams[id.to_sym]['inflictedpushouts']+pushouts 
        end
      end
    end
    CSV.open(file, "w") do |csv|
      full_keys = UNTRACKED_PARAMS_LIST + TRACKED_PARAMS_LIST
      csv << full_keys
      teams.each do |key, team|
        csv << full_keys.map {|k| team[k]}
      end
    end
  end
  
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
end
