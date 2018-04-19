require_relative './lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)


opts = {
  league: "ReBBL World Cup 2018",
  dirs: ["data","REBBL","wc2018"],
  exact: 0,
  reload_contest: false,
  api_key: cfg["api_key"],
  status: "played"
}

processor = BB2APIProcessor.new(opts)
processor.collect_league_matches_with_detail
processor.export_team_statistics "rebbl_wc2018_teams.csv"

