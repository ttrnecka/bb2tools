require 'open-uri'
require 'erb'
require 'json'

class BB2API
  URL = 'http://web.cyanide-studio.com/ws/bb2'
  VALID_OPTS = ["league","competition","status","round","platform","limit","exact","v","name","start","stop","team_id", "order"]
  def initialize(opts={})
    if opts[:api_key].nil?
      raise "Error: API KEY is required!!!"
    else
      @api_key=opts[:api_key]
    end
    #defaults
    @limit=10000
    @exact=1
    
    set_variables(opts)
  end
  
  def get_contests(opts={})
    call_url("contests",opts)
  end

  def get_team(opts={})
    call_url("team",opts)
  end

  def get_teammatches(opts={})
    call_url("teammatches",opts)
  end

  def get_matches(opts={})
    call_url("matches",opts)
  end
  
  def get_matchdetail(uuid)
    full_url = "#{URL}\/match\/?key=#{@api_key}&match_id=#{uuid}"
    puts  full_url
    data = get_url_as_json full_url
  end
  
  private
  
  def call_url(method,opts={})
    base_url = "#{URL}\/#{method}\/?key=#{@api_key}&v=1"
    set_variables(opts)
    param_url = create_url_parameters(opts)
    
    full_url = base_url+param_url
    puts  full_url
    data = get_url_as_json full_url
  end

  def set_variables(opts)
    VALID_OPTS.each do |opt|
      if opts[opt.to_sym] 
        instance_variable_set("@#{opt}", opts[opt.to_sym])
      end 
    end
  end
  
  def create_url_parameters(opts)
    params=""
    VALID_OPTS.each do |opt|
      if tmp = instance_variable_get("@#{opt}")
        params << "&#{opt}=#{ERB::Util.url_encode(tmp.to_s)}"
      end
    end
    params
  end
  
  def get_url_as_json(url)
    #puts url
    raw = open(url,
        "User-Agent" => "Ruby/#{RUBY_VERSION}",
        &:read
    )
    JSON.parse(raw)
  end
end