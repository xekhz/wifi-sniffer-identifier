require './Capture_Parser.rb'
require './Tag_Parser.rb'
require 'rubygems'
require 'packetfu'
require './Data_parser.rb'
require './DatabaseManagement.rb'
require './LocationTracer.rb' 
class Main
  
  #each key is macaddress
  @@device_info = Hash.new()
  
  def initialize
  end
  
  
  def self.show_device_info
    p @@device_info
    return @@device_info
  end
  
  def self.run

      Debugger.set_debugger(false)
        
    # Set interface (Default: en0)                                                                                                                                                                                       
    #iface = ARGV[0] || "teste"                                                                                                                                                                                          
    file_to_open = ARGV[0] || "teste"
    
    # Set interface (Default: en0)                                                                                                                                                                                       
    #iface = ARGV[0] || "teste"                                                                                                                                                                                          
    #file_to_open = ARGV[0] || "teste2"
  
  cap = PacketFu::PcapFile.read("#{file_to_open}.pcap")
  i = 0
  cap.each do |pkt|
          Debugger.debug("---------------------")
          Debugger.debug("packet number: #{i} ")
  
          
    pr =  Capture_Parser.get_probe_request(pkt.data)
  
    if Capture_Parser.check_if_is_probe_or_beacon_request(pr) == "probe"
         
         _source_mac_address = nil || Capture_Parser.get_source_mac_address(pr)
         _dest_mac_address = nil   || Capture_Parser.get_dest_mac_address(pr)
         _seq_number = nil         || Capture_Parser.get_frame_sequence_number(pr)
         _ssid = nil               || Capture_Parser.get_ssid(pkt.data)
         _parameters = nil         || Capture_Parser.get_tag_parameters(pkt.data)
        
         Debugger.debug("SOURCE_MAC: #{Capture_Parser.get_source_mac_address(pr)} DEST_MAC: #{Capture_Parser.get_dest_mac_address(pr)} SSID:#{Capture_Parser.get_ssid(pkt.data)}")

         if @@device_info[_source_mac_address] == nil
            @@device_info[_source_mac_address] = []
         end
          @@device_info[_source_mac_address] << { "dest_mac"=>_dest_mac_address, "seq_number" =>_seq_number ,"ssid"=>_ssid, "parameters"=>_parameters }
      # @@device_info.store(_source_mac_address, [{ "dest_mac"=>_dest_mac_address, "ssid"=>_ssid, "parameters"=>nil }] )
          
          
    end
    
    i = i+1
    if (i > 999999 )
       return
    end
    
  end
  end
    
  
end

Main.run
p ""
p ""
p "##################################################################################################"
d = Main.show_device_info()
p "##################################################################################################"
Data_parser.extract_insert_mac_address_table(d)
Data_parser.extracts_and_insert_ssid_table(d)
Data_parser.extracts_ssid_and_stores(d,"location")




