require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'

login = {:target => 'vsrx', :username => 'jeremy', :password => 'jeremy1' }

ndev = Netconf::SSH.new( login )
ndev.open

$stdout.puts "Connected to #{login[:target]}"

Junos::Ez::Provider( ndev )
Junos::Ez::SRX::Zones.Provider( ndev, :zones )
Junos::Ez::SRX::Policies.Provider( ndev, :policies )

binding.pry

### -----------------------------------------------------------------
### Load all of the Zones YAML files
### -----------------------------------------------------------------

Dir["*_ZONE_IFS.yaml"].each do |file|
  $stdout.puts "Loading Zone Interface YAML contents into Junos: #{file} ..."
  ndev.zones.create_from_yaml! :filename=>file
end

Dir["*_ZONE_ADDRS.yaml"].each do |file|
  $stdout.puts "Loading Zone address YAML contents into Junos: #{file} ..."
  ndev.zones.addrs.create_from_yaml! :filename=>file
end

Dir["*_ZONE_SETS.yaml"].each do |file|
  $stdout.puts "Loading Zone address-set YAML contents into Junos: #{file} ..."
  ndev.zones.sets.create_from_yaml! :filename=>file
end

### -----------------------------------------------------------------
### Load all of the Policy YAML files
### -----------------------------------------------------------------

Dir['POLICY_*.yaml'].each do |file|
  $stdout.puts "Loading security policy YAML contents into Junos: #{file} ... "
  ndev.policies.create_from_yaml! :filename => file
end

$stdout.puts "Committing configuration ... "
ndev.rpc.commit_configuration

ndev.close


    




