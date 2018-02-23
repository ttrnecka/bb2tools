require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'csv'


ROOT = File.expand_path(File.dirname(__FILE__))
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
      
      #pull teams
      teams = html_doc.xpath("//div[contains(@id,'Roster')]/preceding-sibling::table/tr/td[@class='Teamtitle']//text()").map {|p| p.text() }
      #pull Team A names
      playersA = html_doc.xpath("//div[contains(@id,'RosterA')]/table/tr/td[2]//text()").map {|p| [league, division, matchday, teams[0], p.text()] }
      playersB = html_doc.xpath("//div[contains(@id,'RosterB')]/table/tr/td[2]//text()").map {|p| [league, division, matchday, teams[1], p.text()] }

      #pull position   
      positions = html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[3]//text()").map {|p| p.text() }
      
      #pull skills
      player_skills = html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[11]").map do |el|
        imgs = el.xpath(".//img/@title")  
        imgs.empty? ? "" : imgs.map {|i| i.value }.join(",")
      end
  
      #pull game injuries
      game_injuries =  html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[13]").map do |el| 
        img = el.xpath(".//img/@title").first
        img.nil? ? "" : img.value
      end
      
      players = playersA.concat playersB
      # put all into the same array
      players = players.zip(positions,player_skills,game_injuries)
      
      headers = [:league, :division, :matchday, :team, :name, :position, :skills, :game_injuries]
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