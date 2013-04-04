require 'yaml'
require 'net/netconf/jnpr'

require 'JunosNC/facts'
require 'JunosNC/srx'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  include JunosNC::Facts
  
  # overload the open method to the Junos device and then
  # create provider objects starting with Facts ...
  
  def open
    super
    JunosNC::Facts::Provider( self )    
    JunosNC::SRX::Zones::Provider( self, :zones )  
    JunosNC::SRX::Policies::Provider( self, :spols )
  end
  
end

host = MyLogins::HOSTS[ ARGV[0] ]

JunosDevice.new( host ) do |ndev|
  
#  ndev.spols.create_big_from_yaml! "foo.yaml"  :replace=>true 
    
  from_zone_name = "PII-SOX-BZ-ST1"
  to_zone_name = "OUTSIDE-BZ-ST1"
  
  from_zone = ndev.zones[ from_zone_name ]
  to_zone = ndev.zones[ to_zone_name ]  
  
  binding.pry
  
  polc = ndev.spols[ [from_zone_name, to_zone_name] ]  
  rules = polc.rules.list!
  rule = polc.rules["545"]
  
  binding.pry
    
  # hash of new properties ...  
  new_rule_props = {
    :description => "This is a test policy rule for JEREMY",
    :match_srcs => ["S1","S2"],
    :match_dsts => ["D1", "D2"],
    :match_apps => ["any"],
    :action => :permit    
  }

  polc.rules.ignore_raise = true  
  polc.rules.create( "JEREMY", new_rule_props ) do |rule|
    binding.pry
    rule.write!
    rule.reorder! :before => rules.last
  end
    
  binding.pry
        
end




