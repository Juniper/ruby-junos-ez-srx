class Junos::Ez::SRX::Zones::Provider < Junos::Ez::Provider::Parent
  
  def initialize( p_obj, name = nil, opts = {} )
    super
    
    ## binding child providers ...
    ##    'interfaces' for zone-interfaces
    ##    'addrs' for address-book address entries
    ##    'sets' for address-book address sets
    
    Junos::Ez::SRX::Interfaces::Provider( self, :interfaces, :parent => self ) 
    Junos::Ez::SRX::AddressBookEntries::Provider( self, :addrs, :parent => self )
    Junos::Ez::SRX::AddressBookSets::Provider( self, :sets, :parent => self )
  end
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.security { x.zones {
        x.send(:'security-zone') { 
          x.name @name
          return x
        }
      }}
    }}
  end

  ## for this provider, we only want to retrieve the
  ## configuration for the 'host-inbound-traffic' section
  
  def xml_config_read!
    xml = xml_at_top
    xml.send(:'host-inbound-traffic')
    xml.interfaces
    @ndev.rpc.get_configuration( xml )      
  end  
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//security-zone')[0]
  end
    
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )        
    
    host_ib = as_xml.xpath('host-inbound-traffic')    
    as_hash[:host_inbound_services] = host_ib.xpath('system-services').collect do |svc|
      svc.xpath('name').text.strip
    end    
    as_hash[:host_inbound_protocols] = host_ib.xpath('protocols').collect do |proto|
      proto.xpath('name').text.strip
    end
    
    as_hash[:interfaces] = as_xml.xpath('interfaces/name').collect do |zif|
      zif.text.strip
    end    
     
    return true
  end    
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------
  
  def xml_change_host_inbound_services( xml )
    add, del = diff_property_array( :host_inbound_services ) 
            
    xml.send( :'host-inbound-traffic' ) {
      del.each do |i| 
        xml.send(:'system-services', Netconf::JunosConfig::DELETE) {
          xml.name i 
        }
      end
      add.each{|i| xml.send(:'system-services', i ) }
    }
    
  end
  
  def xml_change_host_inbound_protocols( xml )
    add, del = diff_property_array( :host_inbound_protocols ) 
        
    xml.send( :'host-inbound-traffic' ) {
      del.each do |i| 
        xml.protocols( Netconf::JunosConfig::DELETE ) {
          xml.name i 
        }
      end
      add.each{ |i| xml.protocols i }
    }   
  end    
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::Zones::Provider
  
  def build_list     
    zones = @ndev.rpc.get_zones_information
    zones.xpath('zones-security/zones-security-zonename').collect do |zone|
      zone.text.strip
    end
  end
  
  def build_catalog
    
    zlist = list!
    xml_cfg = @ndev.rpc.get_configuration{|x| 
      x.security { x.zones {
        zlist.each do |zone_name|          
          x.send(:'security-zone') {
            x.name zone_name
            x.send(:'host-inbound-traffic')
            x.interfaces
          }
        end
      }}
    }

    @catalog = {}        
    xml_cfg.xpath('//security-zone').each do |zone|
      zn_name = zone.xpath('name').text.strip
      @catalog[zn_name] = {}
      xml_read_parser( zone, @catalog[zn_name] )
    end
    
    return @catalog    
  end
  
end

##### ---------------------------------------------------------------
##### Provider YAML/Hash methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::Zones::Provider
  
  ## ----------------------------------------------------------------
  ## create an 'expanded' hash structure
  ## ----------------------------------------------------------------
  
  def to_h_expanded( opts = {} )       
    { :name => @name,
      :interfaces => interfaces.catalog
    } 
  end   
  
  def xml_from_h_expanded( from_hash, opts = {} )    
    raise ArgumentError, "This is not a provider" unless is_provider?       
    raise ArgumentError, ":name not provided in hash" unless from_hash[:name]
    
    provd = self.class.new( @ndev, from_hash[:name], @opts )   
    
    # setup the XML for writing the complete configuration
    
    xml_top = provd.xml_at_top    
    xml_add_here = xml_top.parent
    
    # iterate through each of the policy rules. @@@ need
    # to validate that the HASH actually contains this, yo!
    
    from_hash[:interfaces].each do |name, hash|
      Nokogiri::XML::Builder.with( xml_add_here ) do |xml|
        
        # create the new object so we can generate XML on it
        obj = Junos::Ez::SRX::Interfaces::Provider.new( @ndev, name, :parent => provd )            
                
        # generate the object specific XML inside
        obj.should = hash || {}
        obj_xml = obj.xml_element_top( xml, name )    
        obj.xml_build_change( obj_xml )
      end      
    end
    
    xml_top.parent[:replace] = "replace" if opts[:replace]    
    xml_top.doc.root
  end
  
end
