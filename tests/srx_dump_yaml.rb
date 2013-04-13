require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'

def yaml_zone( zone )
  zone.to_yaml :filename => zone.name + "_ZONE_IFS.yaml"
  zone.addrs.to_yaml :filename => zone.name + "_ZONE_ADDRS.yaml"
  zone.sets.to_yaml :filename => zone.name + "_ZONE_SETS.yaml"
end

login = {:target => 'vsrx', :username => 'jeremy', :password => 'jeremy1' }

ndev = Netconf::SSH.new( login )
ndev.open

Junos::Ez::Provider( ndev )
Junos::Ez::SRX::Zones.Provider( ndev, :zones )
Junos::Ez::SRX::Policies.Provider( ndev, :policies )

### -----------------------------------------------------------------
### dump all of the Zones to YAML
### -----------------------------------------------------------------

ndev.zones.each do |zone|
  next if zone.name == "junos-host"     
  $stdout.puts "Dumping Junos ZONE to YAML:[#{zone.name}]"
  yaml_zone( zone )
end

### -----------------------------------------------------------------
### dump all of the Polcies to YAML
### -----------------------------------------------------------------

ndev.policies.each do |policy|
  from_zone, to_zone = policy.name
  $stdout.puts "Dumping Junos POLICY to YAML: #{from_zone} --> #{to_zone}"
  policy.to_yaml :filename => "POLICY__" + from_zone + "__" + to_zone + ".yaml"
end

ndev.close


    




