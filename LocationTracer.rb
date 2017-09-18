require './Debugger.rb'
require 'curb'
require 'uri'

class LocationTracer

# curb example : https://stackoverflow.com/questions/16445384/doing-a-post-with-ruby-curb-with-basic-authentication
# curb manual : https://github.com/taf2/curb  
  
# class responsabel to query wiglle and extrat the possible locations of the ssid
 @api_name=nil
 @api_token=nil
 # wigle v2 API  : https://wigle.net/account
 # interactive documentations : https://api.wigle.net/swagger
 # 
 @@link_to_api="https://api.wigle.net/"
 
 @@get_api_to_user_info = "#{@@link_to_api}/api/v2/profile/user"
 @@get_ssid_location = "#{@@link_to_api}/api/v2/network/search"
 
 def initialize
   
   # xekhz username and toke
   @api_name = 'AID951bc9d4ed0cf78d61f118c9d96b09db'
   @api_token = '9a921f80b926d375abc6592c25f5b172'
   
 end
 
 def initialize(api_name='AID951bc9d4ed0cf78d61f118c9d96b09db',api_token='9a921f80b926d375abc6592c25f5b172')
   @api_name = api_name 
   @api_token = api_token
  end

  # gets ssid as input for to query wigle database
  def searchFor(ssid)
    #convering string ssid to url ssid
    _url_ssid = URI.escape(ssid)
    
    #check if SSID was already queried in wigle database
    already_queried = false || DatabaseManagement.check_localy_for_ssid(ssid) 
    
    if ! already_queried       
      # not queried ....... querie now
      #harcoded for version v2
      Debugger.debug "Not queried..will querie now..#{_url_ssid}"
      _wigle_ssid_search = "#{@@get_ssid_location}/?onlymine=false&freenet=false&paynet=false&ssid=#{_url_ssid}"
      _wigle_data = ""
      if ! @api_token || ! @api_name  
        Debugger.set_debugger(true);   
        Debugger.debug "Please create object with api crentials new(api_name,api_token)"
        raise "NO CREDENTIANLS FOR WIGLE"
      end
      return get_wigle_with_curl(_wigle_ssid_search) 
    end
    return "{}"
  end
  
  def get_wigle_with_curl(link)
    
    curl_query = Curl::Easy.new(link);
    curl_query.http_auth_types = :basic
    curl_query.username = @api_name
    curl_query.password = @api_token
    curl_query.headers["Accept"] = "application/json"
    curl_query.headers["Content-Type"] = "multipart/form-data"
    _wigle_data = ""
      begin  
      curl_query.get
      if curl_query.response_code.to_i == 200 
        _wigle_data = curl_query.body_str
      else
        Debugger.set_debugger(true);
        Debugger.debug "Error getting curl response from wigle response code : #{curl_query.response_code.to_i}"
      end
    rescue Exception => error
      Debugger.set_debugger(true);
      Debugger.debug "Error getting curl response from wigle : #{error}"
    ensure
      return _wigle_data
      # TEST OUTPUT 
      #return '{"search_after":33345213,"totalResults":1,"resultCount":1,"last":1,"success":true,"results":[{"trilat":37.10288620000000037180143408477306365966796875,"trilong":-8.3644580800000003506511347950436174869537353515625,"ssid":"WiFi_RosaMar","qos":0,"transid":"20150908-00275","firsttime":"2015-09-09T03:23:11.000Z","lasttime":"2015-09-08T20:23:11.000Z","lastupdt":"2015-09-08T20:23:25.000Z","netid":"D4:CA:6D:6C:86:9B","name":null,"type":null,"comment":null,"wep":"?","channel":1,"bcninterval":0,"freenet":"?","dhcp":"?","paynet":"?","userfound":false}],"first":1}'          
    end
    
  end

  end

  
# testing example
#username = 'AID951bc9d4ed0cf78d61f118c9d96b09db'
#password = '9a921f80b926d375abc6592c25f5b172'
#lt = LocationTracer.new(username,password);
#WiFi_RosaMar
#Sharknet
#Brussels Airport
#print lt.searchFor("WiFi_RosaMar")


