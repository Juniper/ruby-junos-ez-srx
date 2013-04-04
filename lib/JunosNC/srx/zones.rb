class JunosNC::SRX::Zones::Provider < JunosNC::Provider::Parent
  
  def initialize( p_obj, name = nil, opts = {} )
    super
    
    ## binding child providers ...
    ##    'interfaces' for zone-interfaces
    ##    'addrs' for address-book address entries
    ##    'sets' for address-book address sets
    
    JunosNC::SRX::Interfaces::Provider( self, :interfaces, :parent => self ) 
    JunosNC::SRX::AddressBookEntries::Provider( self, :addrs, :parent => self )
    JunosNC::SRX::AddressBookSets::Provider( self, :sets, :parent => self )
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
  
  def xml_try_rename( par_xml, new_name )
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

class JunosNC::SRX::Zones::Provider
  
  def list!     
    zones = @ndev.rpc.get_zones_information
    zones.xpath('zones-security/zones-security-zonename').collect do |zone|
      zone.text.strip
    end
  end
  
  def catalog!
    catalog = {}    
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
    
    xml_cfg.xpath('//security-zone').each do |zone|
      zn_name = zone.xpath('name').text.strip
      props = {}
      xml_read_parser( zone, props )
      catalog[zn_name] = props
    end
    
    return catalog
    
  end
  
end

