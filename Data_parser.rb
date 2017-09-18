
# this class pickup the hash table or another format implemented
# breaks the data and insert it into databases..
#

class Data_parser
  # definition of the broadcast address and ssid to exlude from inserting the database
  @@broadcast_address = 'ffffffffffff'
  @@broadcast_ssid = '*'

  def initialize
  end
  
  
  # reads the hashtable and extracts all the macc adresses 
  def self.extract_insert_mac_address_table(hashed_data)
    Debugger.set_debugger(true);
    hashed_data.each{ |k,v|
        Debugger.debug "mac_address_detected: #{k}"
        insert_mac_address_database(k); 
    }
  
  end
  
  
  
  def self.insert_mac_address_database(macaddress)
    
    DatabaseManagement.insert_mac_address(macaddress);
 
  end
  
  
  
  
  
  # reads the hashtable and for each mac adress extracts the ssid
  #
  #
  def self.extracts_and_insert_ssid_table(hashed_data)
    _dest_mac = nil ;
    _dest_ssid = nil ;
    
    Debugger.set_debugger(true);
    hashed_data.each{ |k,v|
        # k is the macaddress and is a key of the hastable
           Debugger.debug "extrating SSID for: #{k}"
              v.each{ |array_element|
             
              # if dest mac exists and is a key get data   
              if array_element.has_key?("dest_mac");
                  _dest_mac = array_element.fetch("dest_mac");
              end
           
              # ssid key exists  get data        
              if array_element.has_key?("ssid");
                  _dest_ssid = array_element.fetch("ssid");
              end

              if _dest_mac != @@broadcast_address || _dest_ssid != @@broadcast_ssid
                DatabaseManagement.ssid(k,_dest_mac,_dest_ssid);
             end
           
                  }
           }
    
  end
  
  
  # store parameter commands the action
  # if it is
  # database
  # it will store in the sqlite3 ssid and mac addresses
  # if it is 
  # location
  # it will query wigle to store the location of the ssid. 
  #
  def self.extracts_ssid_and_stores(hashed_data,store=nil)
     _dest_mac = nil ;
     _dest_ssid = nil ;
     
     Debugger.set_debugger(true);
     hashed_data.each{ |k,v|
         # k is the macaddress and is a key of the hastable
            Debugger.debug "extrating SSID for: #{k}"
               v.each{ |array_element|
              
               # if dest mac exists and is a key get data   
               if array_element.has_key?("dest_mac");
                   _dest_mac = array_element.fetch("dest_mac");
               end
            
               # ssid key exists  get data        
               if array_element.has_key?("ssid");
                   _dest_ssid = array_element.fetch("ssid");
               end
 
               case store
                when "database"
                     if _dest_mac != @@broadcast_address || _dest_ssid != @@broadcast_ssid 
                      DatabaseManagement.ssid(k,_dest_mac,_dest_ssid);
                     end
                when "location"
                  if  _dest_mac != @@broadcast_address || _dest_ssid != @@broadcast_ssid
                    # check if it is already in database
                    # if it is query the sqlite not the wigle database
                    # need to do the force update locations....
                    
                    #Check if it is in sqlite database
                    if DatabaseManagement.check_if_ssid_was_seen_in_wigle_and_stored(_dest_ssid)
                      begin              
                        Debugger.debug "Already in database sqlite3_wigle #{_dest_ssid}"                           
                      rescue Exception=> e
                        Debugger.debug "ERROR DAta_parser.extracts_ssid_and_stores #{e}"
                      end                      
                    else
                       # stores the results from wigle
                      lt = LocationTracer.new;
                       _wigle_json_data = lt.searchFor(_dest_ssid)                      
                        # puts JSON.parse(_wigle_json_data) 
                        #DATABASEMANAGEMET 
                      if _wigle_json_data != nil
                        DatabaseManagement.ssid_store_location(JSON.parse(_wigle_json_data))
                      end
                    end
                    # storin localy what whe are seen and checked   
                    DatabaseManagement.store_localy_ssid(_dest_ssid)
                    
                  end
               when "location-force-update"
                 #
                 #
                 # FORCES THE UPDATE IN THE SQLITE 3 database
                 #
                  
               else
                 p [k,_dest_mac,_dest_ssid]
               end
               
              
               
               
            
                   }
            }
     
   end
  
  
  def self.get_parameters
  end
  
  def self.get_seq_number
  end
  
  def self.get_dest_mac
    
  end

  #
  # gets ssid locations via wigle database, parses the data and inserts in the database.
  #
  def self.get_last_seen_ssid_in_json()
    
    
  end
  
end


