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

policy = ndev.policies[  ["PII-SOX-BZ-ST1", "OUTSIDE-BZ-ST1"] ]

catalog_h = policy.rules.catalog_expanded
rule_530 = policy.rules.catalog_expanded( "530" )

### find policy rules that have an application term with 
### a timeout of < 5 min == 300 seconds

t_5_m = catalog_h[:rules].select do |rule|
  not( rule[:match_apps].select do |app_name, app_terms|
    app_terms.select{|t| t[:timeout] > 0 and t[:timeout] < 300 }[0]
  end.empty? )
end

binding.pry

ndev.close
