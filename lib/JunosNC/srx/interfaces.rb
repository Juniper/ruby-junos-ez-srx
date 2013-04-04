

class JunosNC::SRX::Interfaces::Provider < JunosNC::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
    
  def xml_at_top
    
    @zone_name = @opts[:zone].name
    
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.security { x.zones {
        x.send(:'security-zone') { 
          x.name @zone_name
          x.interfaces {
            x.name @name
            return x
          }
        }
      }}
    }}
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//interfaces')[0]
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
    
    true    
  end   
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_host_inbound_services( xml )
    should = @should[:host_inbound_services] || []
    has = @has[:host_inbound_services] || []  
    
    add = should - has
    del = has - should
        
    xml.send( :'host-inbound-traffic' ) {
      del.each do |i| 
        xml.send(:'system-services', Netconf::JunosConfig::DELETE) {
          xml.name i 
        }
      end
      add.each{|i| xml.send(:'system-services', i) }
    }
  end
  
  def xml_change_host_inbound_protocols( xml )
    should = @should[:host_inbound_protocols] || []
    has = @has[:host_inbound_protocols] || []  
    
    add = should - has
    del = has - should
        
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

class JunosNC::SRX::Interfaces::Provider
  
  def list!    
    args = { :get_zones_named_information => @opts[:zone].name }    
    zinfo = @ndev.rpc.get_zones_information( args )
    zinfo.xpath('//zones-security-interface-name').collect do |zif|
      zif.text
    end
  end
  
  def catalog!
    catalog = {}    
    
    xml_get = @opts[:zone].xml_at_top
    xml_get.interfaces
    xml_cfg = @ndev.rpc.get_configuration( xml_get )
    xml_cfg.xpath('//interfaces').each do |zif|
      zif_name = zif.xpath('name').text
      catalog[zif_name] = {}
      xml_read_parser( zif, catalog[zif_name] )
    end

    return catalog
  end
  
end
