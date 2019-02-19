require_relative './lib/helpers.rb'
require_relative './rebbl_minors6_collector.rb'
#require_relative './rebbl_rampup_collector.rb'

cfg=YAML.load_file(CFG_FILE)

rampup_teams = []

ai_teams = [
 
]

folder1 = File.join(["data","minors","season6"])
folder2 = File.join(["data","REBBL","Rampup10"])

opts = {
  folders: [folder1],
  #team_filter: lambda {|team| rampup_teams.include? team }
  ignore_teams: ai_teams,
  ignore_leagues: [],
  rampup_teams: rampup_teams
}


processor = BB2DataProcessor.new(opts)
processor.export_team_statistics "rebbl_minors6_teams.csv"
processor.export_player_statistics "rebbl_minors6_players.csv"
processor.export_game_statistics "rebbl_minors6_games.csv"
processor.export_player_tts "rebbl_minors6_tts.csv"

