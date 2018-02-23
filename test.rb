require './helpers.rb'

file = File.open(File.join(ROOT,"cache","gman","div1","matches","Matchday 1","match_1000434f26.html"))

#tmpfile = open('http://www.bb2leaguemanager.com/Leaderboard/match_detail.php?match_uuid=1000434f26',
#        "User-Agent" => "Ruby/#{RUBY_VERSION}"
#      )
#IO.copy_stream(tmpfile, file)
      
#file = File.open(File.join(ROOT,"cache","gman","div1","match.html"))

#seriously_injured = BB2LMProcessor.get_injured_players_from_match_report(file)

html_doc = Nokogiri::HTML(File.open(file))

team_names = html_doc.xpath("//div[contains(@id,'Roster')]/preceding-sibling::table/tr/td[@class='Teamtitle']//text()")
puts team_names

