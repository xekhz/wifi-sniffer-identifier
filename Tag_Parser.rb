
#
# Classe responsavel por fazer o parsing dos campos VENDOR SPECIFIC
#
#

# filtro para determinar se ha oui difenrentes ruby Main.rb| grep TAG | grep OUI | cut -d ":" -f 3 | cut -d " " -f 1 | sort | uniq
# data element type: 1021 manufacturer
#                    1023 model
#                     1024 model
#                     1011 device name

class Tag_Parser

  def initialize()
  end

  
  def oui_0017f2
  
  end
  
  
  def self.oui_default(_oui,_vendor_spec_oui_type,tag_data,_byte_number,stop_byte)
  
      while tag_data.slice(_byte_number.._byte_number)!=nil && _byte_number < stop_byte -1 
        # DATA ELEMENT TYPE 2 BYTES SIZE 
        _data_element_type = tag_data.slice(_byte_number.._byte_number+1).unpack("H*").first
        # DATA ELEMENT SIZE 2 BYTES
        _data_element_size = tag_data.slice(_byte_number+2.._byte_number+3).unpack("H*").first
        _data_element_size = _data_element_size.to_i(16)
        # DATA
        _data = tag_data.slice(_byte_number+3.._byte_number+3+_data_element_size).unpack("H*").first
        Debugger.debug("OUI:#{_oui} VENDOR_SPECIFIC:#{_vendor_spec_oui_type} DATA_ELEMENT_TYPE:#{_data_element_type} DATA_ELEMENT_SIZE:#{_data_element_size} DATA:#{_data} ")
        _byte_number = _byte_number+3+_data_element_size+1
        Debugger.debug("BYTE_NUMBER: #{_byte_number}");
      end 
      return { 'data_element_type' => _data_element_type , 'data_element_size' =>_data_element_size , 'data'=>_data }
  
    end
  
  def self.oui_0050f2(_oui,_vendor_spec_oui_type,tag_data,_byte_number,stop_byte)
    _return_array = Array.new()
    while tag_data.slice(_byte_number.._byte_number)!=nil && _byte_number < stop_byte -1 
      # DATA ELEMENT TYPE 2 BYTES SIZE 
      _data_element_type = tag_data.slice(_byte_number.._byte_number+1).unpack("H*").first
      # DATA ELEMENT SIZE 2 BYTES
      _data_element_size = tag_data.slice(_byte_number+2.._byte_number+3).unpack("H*").first
      _data_element_size = _data_element_size.to_i(16)
      # DATA
      _data = tag_data.slice(_byte_number+3.._byte_number+3+_data_element_size).unpack("M*").first
      Debugger.debug("OUI:#{_oui} VENDOR_SPECIFIC:#{_vendor_spec_oui_type} DATA_ELEMENT_TYPE:#{_data_element_type} DATA_ELEMENT_SIZE:#{_data_element_size} DATA:#{_data} ")
      _byte_number = _byte_number+3+_data_element_size+1
      #Debugger.debug("BYTE_NUMBER: #{_byte_number}");
      _return_array << { 'data_element_type' => _data_element_type , 'data_element_size' =>_data_element_size , 'data'=>_data }

    end 
    
    return _return_array
  end
  
 def self.tag_221(tag_data,stop_byte)
   _return_hash221 = Hash.new()
  # NUMBER | Length | OUI                   DATA
  # 1 byte | 1 byte | 3 bytes | length Bytes - OUI BYTES  
  # 
  _oui_size = 3
    
  _oui = tag_data.slice(0.._oui_size-1).unpack("H*").first
  #
  #
  # ESTE SLICE DEPENDE DO OUI TENHO DE FAZER UMA TABELA PARA CONSULTA
  # vendor specific broadcom apple... e outros..
  # se o vendor n estiver ja analizado cospe a informacao.
  _vendor_spec_oui_type = tag_data.slice(_oui_size.._oui_size).unpack("H*").first
  
  
  #start cycling throw parameters if OUI is known
  _byte_number = _oui_size +1 
    case _oui
      when "0050f2"
      _return_hash221 = oui_0050f2(_oui,_vendor_spec_oui_type,tag_data,_byte_number,stop_byte)
      #when "0017f2"
      #when "001018"
      #when "00904c"
      #when "506f9a"
      else
       Debugger.debug("NOTHING IMPLEMENTED FOR OUI:#{_oui}")
      oui_default(_oui,_vendor_spec_oui_type,tag_data,_byte_number,stop_byte)
    end

   Debugger.debug("")
   
   
   _return_hash221 = {'oui'=>_oui, 'vendor_specific_oui_type'=>_vendor_spec_oui_type, 'tags'=>_return_hash221  }
   
   return  _return_hash221 
 end 
  

end