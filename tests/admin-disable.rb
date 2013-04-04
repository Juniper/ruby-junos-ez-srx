require 'net/netconf/jnpr'

login = { :username => 'jeremy', :password => 'jeremy1', :target => 'vsrx' }

ndev = Netconf::SSH.new( login )
ndev.open

puts "getting the config"

got_config = ndev.rpc.get_configuration{ |xml|
  xml.interfaces {
    xml.interface {
      xml.name 'ge-0/0/1'
    }
  }
}

binding.pry

ndev.rpc.load_configuration{ |xml|
  xml.interfaces {
    xml.interface {
      xml.name 'ge-0/0/1'
      xml.disable
    }
  }
}

puts "making change ..."
ndev.rpc.commit
puts "done."

ndev.close
