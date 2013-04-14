class Junos::Ez::SRX::PolicyRules::Provider < Junos::Ez::Provider::Parent
    
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = @parent.xml_at_top
    xml_element_top( xml, @name ) 
  end
  
  def xml_element_top( xml, name )
    xml.policy { 
      xml.name name
      return xml
    }
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------
  
  def xml_get_has_xml( xml )
    xml.xpath('security/policies/policy/policy')[0]
  end
    
  def xml_read_parser( as_xml, as_hash )  
    
    set_has_status( as_xml, as_hash )      
    
    r_match = as_xml.xpath('match')
    r_then = as_xml.xpath('then')
        
    descr = as_xml.xpath('description').text
    as_hash[:description] = descr unless descr.empty?
    
    ## --------------------------------
    ## "match" criteria
    ## --------------------------------
    
    as_hash[:match_srcs] = r_match.xpath('source-address').collect do |src|
      src.text
    end
    as_hash[:match_dsts] = r_match.xpath('destination-address').collect do |dst|
      dst.text
    end
    as_hash[:match_apps] = r_match.xpath('application').collect do |dst|
      dst.text
    end    

    ## --------------------------------
    ## "then" criteria
    ## --------------------------------
    
    action = r_then.xpath('permit | reject | deny')[0]
    as_hash[:action] = action.name.to_sym
    
    xml_when_item( r_then.xpath('count' )){ as_hash[:count] = true }
    xml_when_item( r_then.xpath('log/session-init')){ as_hash[:log_init] = true }
    xml_when_item( r_then.xpath('log/session-close')){ as_hash[:log_close] = true }
    
    return true
  end   
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------  
  
  def xml_change_match_srcs( xml )
    add, del = diff_property_array( :match_srcs )       
    return false if add.empty? and del.empty?
        
    ele = :'source-address'
    xml.match {
      add.each{ |a| xml.send(ele, a) }
      del.each{ |a| xml.send(ele, a, Netconf::JunosConfig::DELETE ) }
    }
  end
  
  def xml_change_match_dsts( xml )
    add, del = diff_property_array( :match_dsts )        
    return false if add.empty? and del.empty?
    
    ele = :'destination-address'
    xml.match {
      add.each{ |a| xml.send(ele, a) }
      del.each{ |a| xml.send(ele, a, Netconf::JunosConfig::DELETE ) }
    }
  end
  
  def xml_change_match_apps( xml )
    add, del = diff_property_array( :match_apps )        
    return false if add.empty? and del.empty?
    
    xml.match {
      add.each{ |a| xml.application a }
      del.each{ |a| xml.application a, Netconf::JunosConfig::DELETE  }
    }
  end
  
  def xml_change_action( xml )
    xml.then { xml.send( @should[:action] ) }
  end
  
  def xml_change_count( xml )
    xml.then {
      xml_set_or_delete_element( xml, 'count', @should[:count] )
    }
  end
  
  def xml_change_log_init( xml )
    xml.then { xml.log {
      xml_set_or_delete_element( xml, 'session-init', @should[:log_init] )
    }}
  end
  
  def xml_change_log_close( xml )
    xml.then { xml.log {
      xml_set_or_delete_element( xml, 'session-close', @should[:log_close] )
    }}    
  end
    
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::PolicyRules::Provider  
  
  def build_list
    xml_get = @parent.xml_at_top
    xml_get.policy( :recurse => 'false' )
    xml_got = @ndev.rpc.get_configuration( xml_get )    
    xml_got.xpath('//name').collect{|n| n.text }
  end
  
  def build_catalog
    @catalog = {}
    xml_got = @ndev.rpc.get_configuration( @parent.xml_at_top )
    pols = xml_got.xpath('security/policies/policy')
    pols.xpath('policy').each do |pol|
      name = pol.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( pol, @catalog[name] )
    end
    return @catalog
  end  
  
end

##### ---------------------------------------------------------------
##### Provider Misc. operational methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::PolicyRules::Provider
  
  ## 'catalog_expanded' does the equivalent of the show w/detail option
  ## this expands the security object names into their exact values.
  ## note that this processing could take some time given the size of
  ## the address-books and application database involved. yo!
  
  def catalog_expanded( policy_name = nil, opts = {} )
    
    context = @parent.name
    
    catalog_h = { :name => context }
    catalog_h[:rules] = []
    
    args = { :detail => true, :from_zone => context[0], :to_zone => context[1] }
    args[:policy_name] = policy_name if policy_name     
    got = @ndev.rpc.get_firewall_policies( args )
    
    got.xpath('security-context/policies/policy-information').each do |pi|
      catalog_h[:rules] << _pi_to_h_( pi )
    end     
    
    return catalog_h    
  end
  
  ### ---------------------------------------------------------------
  ### !!! PRIVATE METHODS
  ### ---------------------------------------------------------------

  private
  
  def _pi_to_h_( xml )
    
    name = xml.xpath('policy-name').text
    action = xml.xpath('policy-action/action-type').text.to_sym
    
    srcs = xml.xpath('source-addresses/source-address').collect do |i|
      [ i.xpath('address-name').text, i.xpath('prefixes/address-prefix').text ]
    end
    
    dsts = xml.xpath('destination-addresses/destination-address').collect do |i|
      [ i.xpath('address-name').text, i.xpath('prefixes/address-prefix').text ]
    end
    
    apps = {}
    xml.xpath('applications/application').each do |i|
      app_name = i.xpath('application-name').text
      app_terms_xml = i.xpath('application-term')
      app_terms_a = []
      app_terms_xml.each do |app_term|            
        app_term_h = {}
        app_term_h[:proto] = app_term.xpath('protocol').text       
        app_term_h[:timeout] = app_term.xpath('inactivity-timeout').text.to_i
        if app_term_h[:proto] == 'icmp'
          app_term_h[:icmp_type] = app_term.xpath('icmp-info/icmp-type').text
          app_term_h[:icmp_code] = app_term.xpath('icmp-info/icmp-code').text
        else        
          app_sports = [ app_term.xpath('source-port-range/low').text.to_i,
          app_term.xpath('source-port-range/high').text.to_i ]                          
          app_dports = [ app_term.xpath('destination-port-range/low').text.to_i,
          app_term.xpath('destination-port-range/high').text.to_i ]                                
          app_term_h[:src_ports] = app_sports                    
          app_term_h[:dst_ports] = app_dports
        end
        app_terms_a << app_term_h
      end
      apps[app_name] = app_terms_a
    end
  
    to_h = {}
    to_h[:name] = name
    to_h[:action] = action
    to_h[:match_srcs] = Hash[srcs]
    to_h[:match_dsts] = Hash[dsts]
    to_h[:match_apps] = apps
    
    return to_h
  end
  
end




