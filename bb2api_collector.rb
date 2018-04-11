require './helpers.rb'
require './bb2_api.rb'

cfg=YAML.load_file(CFG_FILE)

api_key = cfg["api_key"]

bb2 = BB2API.new(api_key: api_key)

puts bb2.get_contests(league:"REBBL - GMan", round:2, limit:1, status: "played")

