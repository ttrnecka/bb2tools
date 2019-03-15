require_relative '../lib/helpers.rb'

cfg=YAML.load_file(CFG_FILE)

#saved_oi = JSON.parse(File.read("oi_po_matches.json"))
opts = {
    api_key: cfg["api_key"],
}

@api = BB2API.new(opts)

oi_matches = @api.get_matches(:limit=> 10000, :start => "2019-02-01", :league => "REBBL Open Invitational,REBBL Open Invitational 2,REBBL Open Invitational 3,REBBL Open Invitational 4,REBBL Open Invitational 5,REBBL Open Invitational 6")
po_matches = @api.get_matches(:limit=> 10000, :start => "2019-02-01", :league => "REBBL Playoffs", :competition => "REBBL Playoffs X")

oi_matches["matches"].concat po_matches["matches"]
#puts oi_matches

File.open("oi_po_matches.json", 'w') { |file| file.write(oi_matches.to_json) }


