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
Junos::Ez::SRX::Apps::Provider( ndev, :apps )
Junos::Ez::SRX::AppSets::Provider( ndev, :appsets )

zone = ndev.zones["DEF-PROTECT-BZ-ST1"]
addr_set = zone.sets["SWITCHBOARD-MDM-UAT"]

app_list = ndev.apps.list
appset_list = ndev.appsets.list

binding.pry

ndev.close
