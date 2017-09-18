class Debugger
  
  $flag = false
  
  def initialize
  end
  
  
  def self.set_debugger(flag = $flag)
    $flag = flag
  end
  
  def self.debug(msg)
     if $flag
       p "#{msg}\n"
     end
   
   end

end