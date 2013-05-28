require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'
require 'pry'

unless ARGV[0]
  puts "You must specify a target"
end

login = { :target => ARGV[0], :username => 'jeremy',  :password => 'jeremy1',  }
ndev = Netconf::SSH.new( login )
ndev.open

Junos::Ez::Provider( ndev )
Junos::Ez::L1ports::Provider( ndev, :l1_ports )
Junos::Ez::IPports::Provider( ndev, :ip_ports )
Junos::Ez::SRX::Zones::Provider( ndev, :zones )
Junos::Ez::SRX::Policies::Provider( ndev, :policies )

binding.pry

ndev.close
