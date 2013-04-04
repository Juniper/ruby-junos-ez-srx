require 'yaml'
require 'net/netconf/jnpr'

require 'JunosNC/facts'
require 'JunosNC/ip_ports'
require 'JunosNC/srx'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  include JunosNC::Facts
  
  # overload the open method to the Junos device and then
  # create provider objects starting with Facts ...
  
  def open
    super
    JunosNC::Facts::Provider( self )    
    JunosNC::IPports::Provider( self, :ip_ports )
    JunosNC::SRX::Zones::Provider( self, :zones )  
    JunosNC::SRX::Policies::Provider( self, :zpols )
  end
  
end

host = MyLogins::HOSTS[ ARGV[0] ]

JunosDevice.new( host ) do |ndev|
  
  binding.pry
  
  from_zone_name = "PII-SOX-BZ-ST1"
  to_zone_name = "OUTSIDE-BZ-ST1"
  
  from_zone = ndev.zones[ from_zone_name ]
  to_zone = ndev.zones[ to_zone_name ]  
  zpol_name = [ from_zone_name, to_zone_name ]
  zpol = ndev.zpols[ zpol_name ]   

  binding.pry
  
  ndev.zpols.create_from_yaml! :filename=> "srx-policy.yaml",  :replace=>true       
  
  rule_list = zpol.rules.list!
  rule = zpol.rules["545"]
  
  binding.pry

=begin  
  # hash of new properties ...  
  new_rule_props = {
    :description => "This is a test policy rule for JEREMY",
    :match_srcs => ["S1","S2"],
    :match_dsts => ["D1", "D2"],
    :match_apps => ["any"],
    :action => :permit    
  }

  zpol.rules.ignore_raise = true  
  zpol.rules.create( "JEREMY", new_rule_props ) do |rule|
    rule.write!
    rule.reorder! :before => rules.last
  end
    
  binding.pry
=end  
        
end




