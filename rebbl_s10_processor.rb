require_relative './lib/helpers.rb'
require_relative './rebbl_s10_collector.rb'
require_relative './rebbl_rampup_collector.rb'

cfg=YAML.load_file(CFG_FILE)

rampup_teams = []

ai_teams = [
 
]

folder1 = File.join(["data","REBBL","season10"])
folder2 = File.join(["data","REBBL","Rampup10"])

opts = {
  folders: [folder1, folder2],
  #team_filter: lambda {|team| rampup_teams.include? team }
  ignore_teams: ai_teams,
  ignore_leagues: ["ReBBL Playoffs"],
  rampup_teams: rampup_teams
}


processor = BB2DataProcessor.new(opts)
processor.export_team_statistics "rebbl_s10_teams.csv"
processor.export_player_statistics "rebbl_s10_players.csv"
processor.export_game_statistics "rebbl_s10_games.csv"
processor.export_player_tts "rebbl_s10_tts.csv"

