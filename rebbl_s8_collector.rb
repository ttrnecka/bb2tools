require_relative './lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)


opts = {
  league: "REBBL",
  competition: "Season 8",
  dirs: ["data","REBBL","season8"],
  exact: 0,
  reload_contest: false,
  api_key: cfg["api_key"],
  status: "played"
}

processor = BB2APIProcessor.new(opts)
processor.collect_league_matches_with_detail
processor.export_team_statistics "rebbl_s8_teams.csv"

