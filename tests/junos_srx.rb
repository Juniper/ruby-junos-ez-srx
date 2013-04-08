require 'yaml'
require 'net/netconf/jnpr'

require 'junos-ez/stdlib'
require 'junos-ez/srx'

require_relative 'mylogins'

class JunosDevice < Netconf::SSH
  
  # overload the open method to the Junos device and then
  # create provider objects starting with Facts ...
  
  def open
    super                                                       # open connection to device
    Junos::Ez::Facts::Provider( self )                          # Facts must always be first!
    Junos::Ez::Hosts::Provider( self, :hosts )                  # manage staic host mapping
    Junos::Ez::StaticRoutes::Provider( self, :routes )          # manage static routes
    Junos::Ez::L1ports::Provider( self, :l1_ports )             # manage IFD properties
    Junos::Ez::IPports::Provider( self, :ip_ports )             # manage IPv4 interfaces
    Junos::Ez::SRX::Zones::Provider( self, :zones )             # manage security zones
    Junos::Ez::SRX::Policies::Provider( self, :zpols )          # manage secuirty policies
  end
  
  def rollback( rbid = 0 )
    @rpc.load_configuration( :rollback => rbid.to_s )
  end
  def commit_check
    @rpc.commit_configuration( :check => true )
  end
  
end

target = ARGV[0] || "vsrx"
host = MyLogins::HOSTS[ target ] 
filename = "srx-policy.yaml"

JunosDevice.new( host ) do |ndev|
  
  rt = ndev.routes[:default]
  binding.pry
  
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

    




