# OVERVIEW

**NOTE: Work in progress - not yet in RubyGems.org**

A collection of Ruby classes to make Junos SRX automation Easy.  This library supports the following
resources:

  * Zones and associated interfaces
  * Zone address-book entries
  * Zone address-book sets
  * Policy Rules
  * Application entries
  * Application sets
  
For more information about each topic, please refer to the **README_xyz.md** files. 

# EXAMPLE USAGE
  
````ruby
require 'pry'
require 'yaml'
require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
require 'junos-ez/srx'

# login information for NETCONF session 

login = { :target => 'vsrx', :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
$stdout.print "Connecting to device #{login[:target]} ... "
ndev.open
$stdout.puts "OK!"

## Now bind providers to the device object.
## the 'Junos::Ez::Provider' must be first before all others
## this provider will setup the device 'facts'.  The other providers
## allow you to define the instance variables; so this example
## is using 'l1_ports' and 'ip_ports', but you could name them
## what you like, yo!

Junos::Ez::Provider( ndev )
Junos::Ez::L1ports::Provider( ndev, :l1_ports )
Junos::Ez::IPports::Provider( ndev, :ip_ports )
Junos::Ez::SRX::Zones::Provider( ndev, :zones )
Junos::Ez::SRX::Policies::Provider( ndev, :policies )

## drop into interactive mode to play around ... let's look
## at what the device has for facts ...

#->  ndev.facts.list
#->  ndev.facts.catalog
#->  ndev.fact :version

## now look at specific providers like the zones and policies

#-> ndev.zones.list
#-> ndev.zones.catalog

binding.pry

ndev.close
````
  
# DEPENDENCIES

  * gem netconf
  * gem junos-ez-stdlib

# INSTALLATION 

  * gem install junos-ez-srx  (* JUST NOT YET *)

# CONTRIBUTORS

  * Jeremy Schulman, @nwkautomaniac

# LICENSES

   BSD-2, See LICENSE file
