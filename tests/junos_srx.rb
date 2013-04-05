require 'yaml'
require 'net/netconf/jnpr'

require 'JunosNC/facts'
require 'JunosNC/l1_ports'
require 'JunosNC/ip_ports'
require 'JunosNC/srx'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  # overload the open method to the Junos device and then
  # create provider objects starting with Facts ...
  
  def open
    super                                                     # open connection to device
    JunosNC::Facts::Provider( self )                          # Facts must always be first!
    JunosNC::L1ports::Provider( self, :l1_ports )             # manage IFD properties
    JunosNC::IPports::Provider( self, :ip_ports )             # manage IPv4 interfaces
    JunosNC::SRX::Zones::Provider( self, :zones )             # manage security zones
    JunosNC::SRX::Policies::Provider( self, :zpols )          # manage secuirty policies
  end
  
end

host = MyLogins::HOSTS[ ARGV[0] ]
unless host 
  puts "Unknown host: '#{ARGV[0]}'"
  exit 1
end

filename = "srx-policy.yaml"

JunosDevice.new( host ) do |ndev|
   
  
  from_zone_name = "PII-SOX-BZ-ST1"
  to_zone_name = "OUTSIDE-BZ-ST1"
  
  from_zone = ndev.zones[ from_zone_name ]
  to_zone = ndev.zones[ to_zone_name ]  
  zpol_name = [ from_zone_name, to_zone_name ]
  zpol = ndev.zpols[ zpol_name ]  
  
  binding.pry
  
  ndev.zpols.create_from_yaml!( :filename=> filename,  :replace=>true  )
  
  rule_list = zpol.rules.list!
  rule = zpol.rules["545"]
  
  # hash of new properties ...  
  new_rule_props = {
    :description => "This is a test policy rule for JEREMY",
    :match_srcs => ["S1","S2"],
    :match_dsts => ["D1", "D2"],
    :match_apps => ["any"],
    :action => :permit    
  }

  zpol.rules.create( "JEREMY", new_rule_props ) do |rule|
    rule.write!
    rule.reorder! :before => rule_list.last
  end
    
  binding.pry  rule_list = zpol.rules.list!
  rule = zpol.rules["545"]
  
  # hash of new properties ...  
  new_rule_props = {
    :description => "This is a test policy rule for JEREMY",
    :match_srcs => ["S1","S2"],
    :match_dsts => ["D1", "D2"],
    :match_apps => ["any"],
    :action => :permit    
  }

  zpol.rules.create( "JEREMY", new_rule_props ) do |rule|
    rule.write!
    rule.reorder! :before => rule_list.last
  end
  
end

    




