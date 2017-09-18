require 'rubygems'
require 'packetfu'
require './Debugger.rb'
require './Tag_Parser.rb'

# fazer metodos de class
# fazer debugger
# variaveis de classe

class Capture_Parser

  def initialize()
    
  end
  
  
  
  $debug = true
  
  # frame control field can be checked here                                                                                                                                                                            
  # http://stackoverflow.com/questions/12407145/interpreting-frame-control-bytes-in-802-11-wireshark-trace                                                                                                             
  # attention to funcion string#unpack("") it converts the binary subtype to integer ( https://i.stack.imgur.com/OGucx.png )                                                                                           
  # in the case of probe request 100 is converted to 4                                                                                                                                                                 
  # and AP beacon is converted to 8                                                                                                                                                                                    
  #                                                                                                                                                                                                                    
  
  $probe  = 64
  $beacon = 128
  
  
  $iee_radio_tap_header_size = 26
  $iee_radio_tap_header_start_byte = 0
  $iee_radio_tap_header_end_byte = 25
  
  $iee_probe_request_size = 28
  
  $iee_probe_request_frame_start_byte = 26
  $iee_lan_management_frame_start_byte = 50
  
  #PROBE REQUEST BYTE MAP
  # src mac address start -> end byte
  $iee_source_mac_start_byte = 10
  $iee_source_mac_end_byte = 15
  # des mac address start -> end byte
  $iie_dest_mac_start_byte = 16
  $iie_dest_mac_end_byte = 21
  
  # frame_sequence start -> end byte
  $iee_frame_sequence_start_byte = 22
  $iee_frame_sequence_end_byte = 23
 
  # END PROBE REQUEST BYTE MAP
  
  #                                                                                                                                                                                                                    
  #                                                                                                                                                                                                                    
  #obtem o tamanho da frame                                                                                                                                                                                            
  def self.get_frame_size(pktdata)
  end
  
  #byte 0 ao byte 25                                                                                                                                                                                                   
  #                                                                                                                                                                                                                    
  #                                                                                                                                                                                                                    
  def self.get_radio_tap_header(pktdata)
    debug(pktdata.slice($iee_radio_tap_header_start_byte..$iee_radio_tap_header_end_byte))
  end
  
  #byte 26 ao byte 44                                                                                                                                                                                                  
  # size 28                                                                                                                                                                                                            
  #                                                                                                                                                                                                                    
  def self.get_probe_request(pktdata)
   
    probe_struct = pktdata.slice($iee_probe_request_frame_start_byte..$iee_probe_request_frame_start_byte+$iee_probe_request_size)
  
    return probe_struct
  
  end
  def self.get_frame_sequence_number(pr)
   
    # first 4 atre opted-out , they are from fragment-number 0000
    # must do some tricks to build the correct binary information
    frame_seq_number_start = pr.slice($iee_frame_sequence_start_byte..$iee_frame_sequence_start_byte).unpack("B*").first
    frame_seq_number_start_reverse = frame_seq_number_start.reverse[4..8].reverse
    #DONE
    frame_seq_number_end = pr.slice($iee_frame_sequence_end_byte..$iee_frame_sequence_end_byte).unpack("B*").first
    frame_sequence_number_join = frame_seq_number_end.to_s+frame_seq_number_start_reverse.to_s
    Debugger.debug("FRAME_SEQUENCE_NUMBER: #{frame_sequence_number_join.to_i(2)}")
      return frame_sequence_number_join.to_i(2) # convert from bin to dec
  end
  
  def self.get_source_mac_address(probe_request_structure)
    source_mac = nil
  
    source_mac = probe_request_structure.slice($iee_source_mac_start_byte..$iee_source_mac_end_byte).unpack("H*").first
    Debugger.debug("SOURCE MAC:#{source_mac}")
  
    return source_mac
  end
  
  def self.get_dest_mac_address(probe_request_structure)
    dest_mac = nil
  
    dest_mac = probe_request_structure.slice($iie_dest_mac_start_byte..$iie_dest_mac_end_byte).unpack("H*").first
    Debugger.debug("DEST MAC:#{dest_mac}")
  
    return dest_mac
  end

  def self.check_if_is_probe_or_beacon_request(probe_request_structure)
  
    # probe request as the following structure ( https://i.stack.imgur.com/OGucx.png )                                                                                                                                 
    #         subtype | type | version                                                                                                                                                                                 
    #  Probe    0100     00       00    => Binary 1000000  | DEC 64                                                                                                                                                    
    #  Beacon   1000     00       00    => Binary 10000000 | DEC 128                                                                                                                                                   
  
    request_struct = probe_request_structure.slice(0..0)
    request = request_struct.unpack("C*").first.to_i
          Debugger.debug("PROBE REQUEST: DECIMAL: #{request} BINARY: #{request_struct.unpack('B*').first}")
  
    if request.to_i == $probe.to_i
      return "probe"
    end
  
    if request.to_i == $beacon.to_i
      return "beacon"
    end
    return nil
  end
  
  
  
  #                                                                                                                                                                                                                    
  #byte 45 -> ate ao fim                                                                                                                                                                                               
  #                                                                                                                                                                                                                    
  def self.get_management_frame(pktdata)
    management_struct = pktdata.slice(45..-1)
    p management_struct ;
  end

  def self.get_ssid_size(pkt_data)
  
    # the first 2 bytes of the iee_lan_management_frame are the size of the SSID                                                                                                                                       
    # checked ate https://rubyfu.net/content/en/module_0x3__network_kung_fu/ssid_finder.html                                                                                                                           
    # https://apidock.com/ruby/String/unpack                                                                                                                                                                           
  
          ssid_size = 0
          ssid_start = $iee_lan_management_frame_start_byte
          ssid_size = pkt_data.slice($iee_lan_management_frame_start_byte+1..$iee_lan_management_frame_start_byte+1).unpack("C*").first.to_i
          return ssid_size
  
  end
  #                                                                                                                                                                                                                    
  # recebe packet data -> retorna ssid                                                                                                                                                                                 
  def self.get_ssid(pkt_data)
    # the first 2 bytes of the IEE 802.11q wireless lan management frame contains the size, in bytes, of the SSID                                                                                                      
    # SSID starts at byte 50                                                                                                                                                                                           
  
    ssid_start = $iee_lan_management_frame_start_byte
    ssid = nil
    # the first 2 bytes of the iee_lan_management_frame are the size of the SSID                                                                                                                                       
    # checked ate https://rubyfu.net/content/en/module_0x3__network_kung_fu/ssid_finder.html                                                                                                                           
    # https://apidock.com/ruby/String/unpack                                                                                                                                                                           
  
    ssid_size = get_ssid_size(pkt_data)
    ssid = "#{pkt_data.slice($iee_lan_management_frame_start_byte+2..$iee_lan_management_frame_start_byte+2+ssid_size-1).unpack('a*').first}"
  
    if ssid_size < 1
      # BROADCAST                                                                                                                                                                                                      
      ssid = "*"
    end
    Debugger.debug("SSID SIZE:#{ssid_size} SSID:#{ssid}")
    return ssid 
  end
  
  
  # scrolls parameters                                                                                                                                                                                                 
  # returns an hastable with parameters                                                                                                                                                                                
  def self.get_tag_parameters(pkg_data)
          _return_parameters_array = Array.new() 
          packet_size = pkg_data.size  # size in bytes                                                                                                                                                                 
          lan_management_frame_size = packet_size - $iee_radio_tap_header_size - $iee_probe_request_size
  
          if lan_management_frame_size > 0
                  # first parameter tag                                                                                                                                                                                
  
                  _first_parameter_starts = $iee_lan_management_frame_start_byte+2+get_ssid_size(pkg_data)
                  _parameter_starts_at =  _first_parameter_starts
  
                  while _parameter_starts_at < (lan_management_frame_size+$iee_lan_management_frame_start_byte-1)
                          # Debugger.debug("COMPARING: #{_parameter_starts_at} < #{(lan_management_frame_size+$iee_lan_management_frame_start_byte)}")
                          tag_number = pkg_data.slice(_parameter_starts_at.._parameter_starts_at).unpack('C')
                          tag_size =  pkg_data.slice(_parameter_starts_at+1.._parameter_starts_at+1).unpack('C').first.to_i
                          tag_parameter = pkg_data.slice(_parameter_starts_at+2.._parameter_starts_at+2+tag_size-1).unpack("M*")
                         # Debugger.debug("Parameter starts at Byte number: #{_parameter_starts_at} Tag Number: #{tag_number} Tag size: #{tag_size} DATA [ FROM BYTE: #{_parameter_starts_at+2} TO BYTE: #{_parameter_starts_at+2+tag_size-1} #{tag_parameter} ]")
                         Debugger.debug("Tag Number: #{tag_number} Tag size: #{tag_size} ")

                         case tag_number.first
                              when 221
                              #Tag_parser.tag_221(tag_parameter.first)
                                Debugger.debug("Entering tag 221 mode")
                                _return_parameters_array << Tag_Parser.tag_221(tag_parameter.first,tag_size)
                                                                
                         else
                           puts "NOTHING IMPLEMENTD FOR: TAG #{tag_number.first}"
                         end
                         
  
                          _parameter_starts_at = _parameter_starts_at + tag_size + 2
  
                  end
          end
          
          return _return_parameters_array
  
  end

   
end


