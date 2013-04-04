class JunosNC::SRX::PolicyRules::Provider < JunosNC::Provider::Parent
    
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
    
    as_hash[:action] = if r_then.xpath('permit')[0]
      :permit
    elsif r_then.xpath('reject')[0]
      :reject
    elsif r_then.xpath('deny')[0]
      :deny
    end    
    
    as_hash[:count] = not( r_then.xpath('count').empty? )    
    as_hash[:log_init] = not( r_then.xpath('log/session-init').empty? )
    as_hash[:log_close] = not( r_then.xpath('log/session-close').empty? )
    
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

class JunosNC::SRX::PolicyRules::Provider  
  
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

