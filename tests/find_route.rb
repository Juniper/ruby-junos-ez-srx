require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'

login = { :target => 'vsrx', :username => 'jeremy',  :password => 'jeremy1',  }

ndev = Netconf::SSH.new( login )
ndev.open

Junos::Ez::Provider( ndev )
Junos::Ez::SRX::Zones::Provider( ndev, :zones )
Junos::Ez::SRX::Policies::Provider( ndev, :policies )

f_1 = ndev.zones.find_route "23.171.20.12", :addrs => true
f_2 = ndev.zones.find_route "23.171.37.37", :addrs => true

binding.pry

ndev.close
