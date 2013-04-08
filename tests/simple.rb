# from gem netconf
require 'net/netconf/jnpr'

# from gem junos-nc-stdlib
require 'junos-ez/stdlib'

# from gem junos-nc-srx
require 'junos-ez/srx'

login = { :target => 'vsrx',
  :username => 'jeremy', 
  :password => 'jeremy1',  
}

ndev = Netconf::SSH.new( login )
ndev.open

binding.pry

ndev.close
