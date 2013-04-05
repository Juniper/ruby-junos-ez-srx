# from gem netconf
require 'net/netconf/jnpr'

# from gem junos-nc-stdlib
require 'JunosNC/stdlib'

# from gem junos-nc-srx
require 'JunosNC/srx'

login = { :target => 'vsrx',
  :username => 'jeremy', 
  :password => 'jeremy1',  
}

ndev = Netconf::SSH.new( login )
ndev.open

binding.pry

ndev.close
