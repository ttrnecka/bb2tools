require_relative './lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)


opts = {
  league: "Rampup",
  competition: "",
  ignore_leagues: [],
  dirs: ["data","REBBL","Rampup"],
  exact: 0,
  reload_contest: true,
  api_key: cfg["api_key"],
  status: "played"
}

collector = BB2APICollector.new(opts)
collector.collect_league_matches_with_detail

#processor = BB2DataProcessor.new(opts)
#processor.export_team_statistics "rebbl_rampup_teams.csv"
#processor.export_player_statistics "rebbl_rampup_players.csv"