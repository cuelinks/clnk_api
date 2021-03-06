module ClnkApi
  class Link 
    include HTTParty
    base_uri 'http://api.clnk.in'
    attr_accessor :long_url, :short_url, :short_code,:api_key,:clicks, :bulk_urls
    def initialize(api_key)
      @api_key = api_key
    end

    def validate_url(urls)
      case urls.class.to_s
      when "String"
        raise ClnkApi::General.new("Url is invalid.") unless  urls =~ /\A#{URI::regexp(['http', 'https'])}\z/
      when "Array"
        urls.each do |url|
          raise ClnkApi::General.new("Url is invalid.") unless  url =~ /\A#{URI::regexp(['http', 'https'])}\z/
        end
      when "Hash"
        urls.each do |k, url|
          raise ClnkApi::General.new("Url is invalid.") unless  url =~ /\A#{URI::regexp(['http', 'https'])}\z/
        end
      end
      
    end

    def info(url)
      validate_url(url)
      self.short_url = url
      options = {:query=>{ :short_url=> url,:access_token=> @api_key} }
      response = self.class.get("/api/v1/links/info", options)
      handle_response(response)
    end

    def expand(short_code)
      self.short_code = short_code
      options = {:query=>{ :short_code=> short_code,:access_token=> @api_key} }
      response = self.class.get("/api/v1/links/expand", options)
      handle_response(response)
    end

    def shorten(url)
      validate_url(url)
      long_url = url
      options = {:body=>{ :long_url=> long_url,:access_token=> @api_key} }
      response = self.class.post("/api/v1/links/shorten", options)
      handle_response(response)
    end

    def bulk_shorten(urls)
      validate_url(urls)
      options = {:body=>{:urls=> urls.to_json,:access_token=>@api_key} }
      response = self.class.post("/api/v1/links/bulk_shorten", options)
      handle_bulk_response(response)
    end

    def handle_response(response)
      raise_errors(response)
      build_response(response)
    end

    def handle_bulk_response(response)
      raise_errors(response)
      bulk_response(response)
    end

    def raise_errors(response)
      code = response.code.to_i
      case code
      when 400
        raise ClnkApi::General.new("Parameter check failed. This error indicates that a required parameter is missing or a parameter has a value that is out of bounds.")
      when 401
        raise ClnkApi::Unauthorized.new
      when 404
        raise ClnkApi::NotFound.new
      when 500
        raise ClnkApi::InformClnk.new
      when 503
        raise ClnkApi::Unavailable.new
      end
    end

    def build_response(response)
      unless response.body.strip.empty?
        url_data = MultiJson.load(response.body)["data"] || {} rescue {}
        self.long_url ||= url_data["long_url"]
        self.short_url ||= url_data["short_url"]
        self.short_code ||= url_data["short_code"]
        self.clicks ||= url_data["clicks"]
      end
    end

    def bulk_response(response)
      self.bulk_urls = response.body
    end

  end
end

