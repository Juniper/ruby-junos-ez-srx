# from gem netconf
require 'net/netconf/jnpr'
# from gem junos-ez-stdlib
require 'junos-ez/stdlib'
# from gem junos-ez-srx
require 'junos-ez/srx'

login = { :target => 'vsrx', :username => 'jeremy',  :password => 'jeremy1',  }

ndev = Netconf::SSH.new( login )
ndev.open

Junos::Ez::Provider( ndev )
Junos::Ez::SRX::Zones::Provider( ndev, :zones )

binding.pry

ndev.close
