require_relative './lib/helpers.rb'
require_relative './rebbl_s9_collector.rb'
require_relative './rebbl_rampup_collector.rb'

cfg=YAML.load_file(CFG_FILE)

rampup_teams = [
  "hell orcs",
"The Bashin' Lizzies",
"Cravin Skaven",
"Mineros De Ayotzinapan",
"The Klub Scouts",
"Altos Punanis",
"Snake Kitties",
"Heimdall's Elite",
"The Primetime Bandits",
"Ironbound Miners",
"Ye Olde Crow Medicine Co.",
"Darkwold Hunters",
"Jinny's sugardaddies",
"Forocoches [REBBL]",
"Rulers of Transylvania",
]

ai_teams = [
  "Tipsy  Axes",
  "Jolly  Raiders",
]

folder1 = File.join(["data","REBBL","season9"])
folder2 = File.join(["data","REBBL","Rampup"])

opts = {
  folders: [folder1, folder2],
  #team_filter: lambda {|team| rampup_teams.include? team }
  ignore_teams: ai_teams,
  ignore_leagues: []
}


processor = BB2DataProcessor.new(opts)
#processor.export_team_statistics "rebbl_s9_teams.csv"
#processor.export_player_statistics "rebbl_s9_players.csv"
processor.export_game_statistics "rebbl_s9_games.csv"

