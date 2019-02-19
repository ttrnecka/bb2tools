require_relative './lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)


opts = {
  league: "ReBBL Open Invitational",
  competition: "",
  ignore_leagues: [],
  dirs: ["data","REBBL","OI"],
  exact: 0,
  reload_contest: false,
  api_key: cfg["api_key"],
  status: "played"
}

collector = BB2APICollector.new(opts)
collector.collect_league_matches_with_detail

folder1 = File.join(opts[:dirs])
opts = {
  folders: [folder1],
  #team_filter: lambda {|team| rampup_teams.include? team }
  ignore_teams: [],
  ignore_leagues: [],
  rampup_teams: []
}

processor = BB2DataProcessor.new(opts)
processor.export_team_statistics "rebbl_oi_teams.csv"
processor.export_player_statistics "rebbl_oi_players.csv"
processor.export_game_statistics "rebbl_oi_games.csv"

