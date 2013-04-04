
require "JunosNC/provider"

module JunosNC::SRX; end
  
module JunosNC::SRX::Zones

  PROPERTIES = [
    :host_inbound_services,       ## array of service names | nil
    :host_inbound_protocols,      ## array of protocol names | nil
    :interfaces                   ## R/O array of interface names
  ]  

  def self.Provider( ndev, varsym )       
    newbie = JunosNC::SRX::Zones::Provider.new( ndev )     
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
    
end

module JunosNC::SRX::Interfaces 
  
  PROPERTIES = [
    :host_inbound_services,
    :host_inbound_protocols,
  ]  
  
  def self.Provider( on_obj, varsym, opts = {} )     
    newbie = JunosNC::SRX::Interfaces::Provider.new( on_obj, nil, opts )     
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( on_obj, varsym, newbie )    
  end
  
end

module JunosNC::SRX::AddressBookEntries
  
  PROPERTIES = [:ip_prefix]
  
  def self.Provider( on_obj, varsym, opts = {} )     
    newbie = JunosNC::SRX::AddressBookEntries::Provider.new( on_obj, nil, opts )     
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( on_obj, varsym, newbie )    
  end
  
end

module JunosNC::SRX::AddressBookSets
  
  PROPERTIES = [:list]         # array of addresses
  
  def self.Provider( on_obj, varsym, opts = {} )     
    newbie = JunosNC::SRX::AddressBookSets::Provider.new( on_obj, nil, opts )     
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( on_obj, varsym, newbie )    
  end
  
end

module JunosNC::SRX::Policies
  
  PROPERTIES = [
    :rules_count,         # Number of rules in this policy context
    :rules                # Provider to JunosNC::SRX::PolicyRules
  ]
  
  def self.Provider( on_obj, varsym, opts = {} )     
    newbie = JunosNC::SRX::Policies::Provider.new( on_obj, nil, opts )     
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( on_obj, varsym, newbie )    
  end  
  
end

module JunosNC::SRX::PolicyRules
  
  PROPERTIES = [
    :description,           # string description
    :match_srcs,            # array of sources
    :match_dsts,            # array of destinations
    :match_apps,            # array of apps
    :action,                # [ :permit, :reject, :deny ]
    :count,                 # true | false
    :log_init,              # true | false
    :log_close              # true | false
  ]  
  
  def self.Provider( on_obj, varsym, opts = {} )     
    newbie = JunosNC::SRX::PolicyRules::Provider.new( on_obj, nil, opts )     
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( on_obj, varsym, newbie )    
  end  
  
end

require 'JunosNC/srx/policies'
require 'JunosNC/srx/policyrules'
require 'JunosNC/srx/abooke'
require 'JunosNC/srx/abooks'
require 'JunosNC/srx/interfaces'
require 'JunosNC/srx/zones'



