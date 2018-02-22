require 'nokogiri'
#require 'open-uri'
require 'fileutils'
#require "http"
require 'uri'
require 'net/http'

ROOT = File.expand_path(File.dirname(__FILE__))
CFG_FILE = File.join(ROOT,"config","config.yml")

def create_dir(dirname)
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end


class BB2LMProcessor
  class << self
    def load_file(file)
      Nokogiri::HTML(File.open(file))
    end
    
    def get_players_from_match_report(report_file)
      html_doc = load_file(report_file)
      
      #pull names
      players = html_doc.xpath("//div[contains(@id,'Roster')]/table/tr/td[2]//text()").map {|p| p.text() }

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

      # put all into the same array
      players.zip(positions,player_skills,game_injuries)
    end
    
    def get_injured_players_from_match_report(report_file,opts={})
      injury_index = 3
      players = get_players_from_match_report(report_file)
      injured = players.select {|p| !p[3].empty? }
      if opts[:no_bh]
        injured = injured.select {|p| !p[3].match(/BadlyHurt/) }
      end
      injured
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