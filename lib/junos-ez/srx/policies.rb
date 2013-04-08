class Junos::Ez::SRX::Policies::Provider < Junos::Ez::Provider::Parent
  attr_reader :from_zone_name, :to_zone_name
  
  def initialize( p_obj, name = nil, opts = {} )
    super    
    return unless name            
        
    # bind in the child provider for managing the actual rules    
    Junos::Ez::SRX::PolicyRules::Provider( self, :rules, :parent => self )     
  end
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.security { x.policies { 
        x.policy {
          x.send( :'from-zone-name', @name[0] )
          x.send( :'to-zone-name', @name[1] )
          return x
        }
      }}
    }}
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  ## override the reader to only pull in the policy names, and 
  ## not all the details.
  
  def xml_config_read!
    xml = xml_at_top
    xml.policy( :recurse => 'false' )    
    @ndev.rpc.get_configuration( xml )      
  end
  
  def xml_get_has_xml( xml )
    xml.xpath('security/policies/policy')[0]
  end
    
  def xml_read_parser( as_xml, as_hash )   
    set_has_status( as_xml, as_hash )      
    as_hash[:rules] = as_xml.xpath('policy/name').collect do |pol|
      pol.text
    end    
    as_hash[:rules_count] = as_hash[:rules].count
    return true
  end    
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::Policies::Provider  
  
  def build_list     
    fw = @ndev.rpc.get_firewall_policies( :zone_context => true )
    fw.xpath('policy-zone-context/policy-zone-context-entry').collect do |pzc|
      [ pzc.xpath('policy-zone-context-from-zone').text,
        pzc.xpath('policy-zone-context-to-zone').text ]        
    end
  end
  
  def build_catalog
    @catalog = {}  
    fw = @ndev.rpc.get_firewall_policies( :zone_context => true )
    fw.xpath('policy-zone-context/policy-zone-context-entry').collect do |pzc|
      
      name = [pzc.xpath('policy-zone-context-from-zone').text,
          pzc.xpath('policy-zone-context-to-zone').text  ]
      
      @catalog[name] = {
        :rules_count => pzc.xpath('policy-zone-context-policy-count').text.to_i
      }
    end    
    return @catalog
  end  
end

##### ---------------------------------------------------------------
##### Provider EXPANDED methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::Policies::Provider

  ## ----------------------------------------------------------------
  ## create an 'expanded' hash structure
  ## ----------------------------------------------------------------
  
  def to_h_expanded( opts = {} )   
    
    unless opts[:brief]; return {
       :name => @name,
       :rules => rules.catalog!
    } 
    end    
    
    # make a deep-copy of the catalog since we're going 
    # to mung it, yo Marshal!
    
    out_hash = { 
      :name => @name,
      :rules => Marshal.load( Marshal.dump( rules.catalog! ))
    }
    
    out_hash[:rules].each do |rule_name, rule_hash|
      rule_hash.delete :exist if rule_hash[:exist] == true
      rule_hash.delete :active if rule_hash[:active] == true
      rule_hash.delete :count unless rule_hash[:count]
      rule_hash.delete :log_init unless rule_hash[:log_init]
      rule_hash.delete :log_close unless rule_hash[:log_close]
    end
    
    return out_hash            
  end

  ## ----------------------------------------------------------------
  ## ----------------------------------------------------------------
  
  def xml_from_h_expanded( from_hash, opts = {} )    
    raise ArgumentError, "This is not a provider" unless is_provider?       
    raise ArgumentError, ":name not provided in hash" unless from_hash[:name]
    
    provd = self.class.new( @ndev, from_hash[:name], @opts )   
    
    # setup the XML for writing the complete configuration
    
    xml_top = provd.xml_at_top    
    xml_add_here = xml_top.parent
    
    # iterate through each of the policy rules. @@@ need
    # to validate that the HASH actually contains this, yo!
    
    from_hash[:rules].each do |name, hash|
      Nokogiri::XML::Builder.with( xml_add_here ) do |xml|
        
        # create the new object so we can generate XML on it
        rule = Junos::Ez::SRX::PolicyRules::Provider.new( @ndev, name, :parent => provd )            
                
        # generate the object specific XML inside
        rule.should = hash
        rule_xml = rule.xml_element_top( xml, rule.name )    
        rule.xml_build_change( rule_xml )
      end      
    end
    
    xml_top.parent[:replace] = "replace" if opts[:replace]    
    xml_top.doc.root
  end
  
end




