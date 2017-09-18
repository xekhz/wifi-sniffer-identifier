require 'sqlite3'
require './Debugger.rb'
require 'json'

class DatabaseManagement
  
  @@db = nil ;
  
  # creates table mac_address for detected mac_address and adds the constrain mac unique
  def initialize()
    
    Debugger.set_debugger(true);
    Debugger.debug("USING SQLITE3");
    
    @@db = SQLite3::Database.new ":Detected_MAC" ;
    # when creating the database object creates all the databases that are needed
    #
    # Table that contains the mac address
    _this_query = @@db.prepare("CREATE TABLE IF NOT EXISTS  Mac_Address(
        Id INTEGER PRIMARY KEY ASC, 
        mac TEXT NOT NULL,
        UNIQUE (mac)
        ) ");
    _this_query.execute;
    
    
    # Table that contains the Ssid and a reference to the macaddress
    #
    _this_query = @@db.prepare("CREATE TABLE IF NOT EXISTS  SSID(
            Id INTEGER PRIMARY KEY ASC,
            Id_mac INTEGER,
            Dest_Mac TEXT NOT NULL,
            Ssid TEXT NOT NULL,
            UNIQUE(Id_mac,Ssid,Dest_Mac)
            ) ");
        _this_query.execute;
    
    # Table that contains the Ssid and a reference to the macaddress
    #
    _this_query = @@db.prepare("CREATE TABLE IF NOT EXISTS  SSID_Wigle(
               Id INTEGER PRIMARY KEY ASC,
               Ssid TEXT NOT NULL,
               Lat TEXT NOT NULL,
               Long TEXT NOT NULL,
               FirstTime TEXT NOT NULL,
               LastTime TEXT NOT NULL,
               netid TEXT NOT NULL,
               UNIQUE(Ssid,netid,Lat,Long)
               ) ");
           _this_query.execute;
      
      #
      #
    _this_query = @@db.prepare("CREATE TABLE IF NOT EXISTS  Queried_SSID_Wigle(
               Id   INTEGER PRIMARY KEY ASC,
               Ssid TEXT NOT NULL,
               Time Created_on default CURRENT_DATE,
               UNIQUE(Ssid)
               ) ");
           _this_query.execute;
      
          
  end

  def self.startup_database_system()
    
   
  
  end
    
  def self.create()
  end
  
  def self.connect()
  end
  
  def self.close()
  end
  
  def self.insert_mac_address(macaddress)
     Debugger.debug("function: DatabaseManagement.insert_mac_address > INSERT OR IGNORE INTO Mac_Address(mac) VALUES('#{macaddress}')");
   begin
    _this_query = @@db.prepare("INSERT OR IGNORE INTO Mac_Address(mac) VALUES('#{macaddress}')");
    _this_query.execute;
   rescue Exception => e
     Debugger.debug("ERROR function: DatabaseManagement.insert_mac_address#{e}");
     return nil
   end
  end
  
  # stores ssid along with the mac address that has seen it
  #
  def self.ssid(macaddress,destmacaddress,ssid)

    
    # get id from mac address table
    # insert ssid , and dest mac address
       Debugger.debug("function: DatabaseManagement.ssid #{macaddress}");
       Debugger.debug("function: DatabaseManagement.ssid get mac id");

       
      _this_query = @@db.prepare("select Id from Mac_Address where mac ='#{macaddress}';");
      #_this_query.bind_param 1, macaddress
      _query_result = _this_query.execute; 
      _query_result.each { |row|
      _mac_address_id = nil;
        if row != nil && row != [] && row[0].to_i > 0
        Debugger.debug("function: DatabaseManagement.ssid inserting ssid in table of ssid");
            _mac_address_id = row[0].to_i
            _this_query = @@db.prepare("INSERT OR IGNORE INTO SSID(Id_mac,Dest_Mac,Ssid) 
                                                              VALUES('#{_mac_address_id}','#{destmacaddress}','#{ssid}')");
            begin
            _this_query.execute;
            rescue Exception => e
              Debugger.debug("ERROR function: DatabaseManagement.ssid#{e}");
            end

  end
        
      } 
    end
    
  # makes a query to the sqlite , table wigle to check if ssid is already there 
  def self.check_if_ssid_was_seen_in_wigle_and_stored(ssid)
    retval = false
      begin
        Debugger.debug("QUERING DATABASE SQLITE3 for SSID: #{ssid} function: check_if_ssid_was_seen_in_wigle_and_stored(ssid) ");
    _this_query = @@db.prepare("select count(Ssid) from SSID_Wigle where Ssid = '#{ssid}'");
     rs = _this_query.execute;
     rs.next[0].to_i <= 0 ? retval = false : retval = true
      rescue Exception => e
        Debugger.debug("ERROR function: check_if_ssid_was_seen_in_wigle_and_stored(ssid)  #{e}");
      ensure 
        Debugger.debug("FOUND #{retval}")
        return retval
      end
  end  
    
    # stores the location of the ssid found
    def self.ssid_store_location(hashed_result_set)
      #p hashed_result_set
      json_hash = hashed_result_set 
      # check if it has all the key necessary
      # api v2 wiggle
      # key in response: resultCount, success, results
      # results shoud be an array with and hash table with the keys: trilat, trilong , ssid, firsttime, lasttime
      resultCount = "resultCount"
      success = "success"
      results = "results"
      trilat = "trilat"
      trilong = "trilong"
      ssid = "ssid"
      firsttime = "firsttime"
      lasttime = "lasttime"
      netid = "netid"
       
      if json_hash.has_key?(success) && json_hash.fetch(success).to_s == "true" && json_hash.has_key?(resultCount) &&  json_hash.fetch(resultCount).to_i > 0 
        
        # Cycle through results and store in sqlite
        json_hash.fetch(results).each { |elm| 
          _trilat = elm.fetch(trilat)
          _trilong = elm.fetch(trilong)
          _ssid = elm.fetch(ssid)
          _firsttime = elm.fetch(firsttime)
          _lasttime = elm.fetch(lasttime)
          _netid = elm.fetch(netid)
          begin
            # store location data
           _this_query = @@db.prepare("INSERT OR IGNORE INTO 
                                                    SSID_Wigle( Ssid,Lat,Long,FirstTime,LastTime,netid) 
                                                     VALUES('#{_ssid}','#{_trilat}','#{_trilong}','#{_firsttime}','#{_lasttime}','#{_netid}')");
          _this_query.execute;
          rescue Exception => error
            Debugger.debug("ERROR function: DatabaseManagement.ssid_store_location #{error}");
            return nil
          end
        }
      else
        Debugger.debug("function: ssid_store_store_location(hashed_result_set) problem with the json response from wigle #{hashed_result_set}");
        return nil
      end
    end  
  
    def self.store_localy_ssid(_ssid)
      begin
      # store in local_querie table.
       # check once....... 
       #
       _this_query = @@db.prepare("INSERT OR IGNORE INTO Queried_SSID_Wigle(Ssid) VALUES('#{_ssid}')");  
        _this_query.execute ;
      rescue Exception => error
        Debugger.debug("#{error} funciotn store_localy_ssid")
      end      
    end
    
  def self.check_localy_for_ssid(_url_ssid,max_days = 7) 
    last_checked = -1
    begin
      Debugger.debug("Searching in local database in already_queried function check_localy_for_ssid(_url_ssid,max_days = 7) ")
      _was_seen = false
      # this querie extracts when  ssid in question was last checked in wigle
      _this_query = @@db.prepare("select Time from Queried_SSID_Wigle where Ssid = '#{_url_ssid}'");
      _query_result = _this_query.execute
      
      _query_result.each{ |row| 
      _last_seen_ssid =  DateTime.parse(row[0])
      last_checked = (Date.today - _last_seen_ssid.to_date).to_i
      }
      
           
      if last_checked > max_days
       ################################### TODO ######################################
       # delete ssid from Queried_SSID_Wigle
       ################################### TODO ######################################

        Debugger.debug("more then #{max_days}  check again function check_localy_for_ssid(_url_ssid,max_days = 7) ")
       _was_seen = false
      elsif last_checked == -1
        Debugger.debug("never seen before check again function check_localy_for_ssid(_url_ssid,max_days = 7) ")
        _was_seen = false
      else
       Debugger.debug("was seen in #{last_checked}  check again function check_localy_for_ssid(_url_ssid,max_days = 7) ")
       _was_seen = true
     end
    rescue Exception => error 
      Debugger.debug("function: DatabaseManagement.check_localy_for_ssid(_url_ssid) #{error}");
      _was_seen =false
    ensure
      return _was_seen
    end
  end 

end

# when included in the main script it creates the object and initialize all the tables needed.

DatabaseManagement.new()

## EXAMPLE
#begin
#    
#    db = SQLite3::Database.new ":memory"
#    puts db.get_first_value 'SELECT SQLITE_VERSION()'
#    
#rescue SQLite3::Exception => e 
#    
#    puts "Exception occurred"
#    puts e
#    
#ensure
#    db.close if db
#end