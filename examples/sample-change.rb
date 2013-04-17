require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'

###
### load the data we want to use to represent the 'change request'
###

change_data = YAML.load_file( 'change.yaml' )

###
### open a NETCONF connection to the target device
###
login = {:target => 'vsrx', :username => 'jeremy', :password => 'jeremy1' }
ndev = Netconf::SSH.new( login )
ndev.open

###
### bind the Junos EZ provider objects to the device object
###

Junos::Ez::Provider ndev
Junos::Ez::SRX::Zones::Provider ndev, :zones
Junos::Ez::SRX::Policies::Provider ndev, :policies

###
### obtain objects for the from-zone and to-zone
###

from_zone = ndev.zones[ change_data['from-zone']['name'] ]
to_zone = ndev.zones[ change_data['to-zone']['name'] ]

### add the address names/sets to the proper zones.
### if the address data is an Array, then we're adding
### an address book set.  otherwise we're adding an entry

{'from-zone' => from_zone, 'to-zone' => to_zone}.each do |which, zone|
  change_data[which]['addresses'].each do |adr_name, adr_data|
    case adr_data
    when Array
      set = zone.sets[adr_name]
      set[:addr_names] = adr_data
      set.write!
    else
      entry = zone.addrs[adr_name]
      entry[:ip_prefix] = adr_data
      entry.write!
    end
  end
end

###
### now add the new rule to the policy.  insert the 
### new rule before the current last rule
###

policy = ndev.policies[ [from_zone.name, to_zone.name] ]
last_rule = policy.rules.list.last

change_policy = change_data['policy']

rule = policy.rules[ change_policy['rule'] ]
rule[:action] = change_policy['action'].to_sym
rule[:match_srcs] = change_policy['from']
rule[:match_dsts] = change_policy['to']
rule[:match_apps] = change_policy['apps']
rule.write!
rule.reorder! :before => last_rule

###
### get a "diff" output of the changes and display them to the screen
###

puts "Junos changes:\n"
config_diff = ndev.rpc.get_configuration(:compare=>'rollback', :rollback=>'0')
puts config_diff

# - breakpoint if we want to 'look around', just uncomment out the next line
# binding.pry

###
### now commit the configuration changes and close the connection
###

ndev.rpc.commit_configuration
ndev.close


