require 'open-uri'
require 'openssl'
require 'json'

class RebblNet
  URL = 'https://rebbl.net/api/v1/standings/rampup/rel'
 
  def self.get_oi_signups(format="raw")
    if format=="raw"
      get_url("#{URL}")
    else
      get_url_as_json("#{URL}")
    end
  end
  private
  
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
        params << "&#{opt}=#{URI::encode(tmp.to_s)}"
      end
    end
    params
  end
  
  def self.get_url_as_json(url)
    JSON.parse(get_url(url))
  end

  def self.get_url(url)
    puts url
    raw = open(url,
      {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE},
        &:read
    )
  end
end