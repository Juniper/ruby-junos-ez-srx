class Junos::Ez::SRX::Apps::Provider < Junos::Ez::Provider::Parent
    
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.applications {
        x.application { 
          x.name @name 
          return x
        }
      }
    }}
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//application')[0]
  end
    
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )            

    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text }    
    as_hash[:proto] = as_xml.xpath('protocol').text        
    xml_when_item(as_xml.xpath('inactivity-timeout')){|i| as_hash[:timeout] = i.text.to_i }

    if as_hash[:proto] == 'icmp'
      xml_when_item(as_xml.xpath('icmp-type')){|i| as_hash[:icmp_type] = i.text }
      xml_when_item(as_xml.xpath('icmp-code')){|i| as_hash[:icmp_code] = i.text }
      return true
    end
    
    ### rest of this is for non ICMP
    
    xml_when_item(as_xml.xpath('destination-port')) do |i|
      text = i.text
      if (Float(text) != nil rescue false)
        as_hash[:dst_ports] = text.to_i
      elsif text =~ /(\d+)-(\d+)/
        as_hash[:dst_ports] = [ $1.to_i, $2.to_i ]
      else
        as_hash[:dst_ports] = text
      end
    end
    
    return true
  end    
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------  
  
  def xml_change_proto( xml )
    xml_set_or_delete( xml, 'protocol', @should[:proto] )
  end
  
  def xml_change_dst_ports( xml )
    e_value = 
      ( @should[:dst_ports].kind_of? Array ) ? "#{@should[:dst_ports][0]}-#{@should[:dst_ports][1]}"
      : @should[:dst_ports]      
      
    xml_set_or_delete( xml, 'destination-port', e_value )
  end
  
  def xml_change_timeout( xml )
    xml_set_or_delete( xml, 'inactivity-timeout', @should[:timeout] )
  end
  
  def xml_change_icmp_type( xml )
    xml_set_or_delete( xml, 'icmp-type', @should[:icmp_type] )    
  end
  
  def xml_change_icmp_code( xml )
    xml_set_or_delete( xml, 'icmp-code', @should[:icmp_code] )        
  end
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::Apps::Provider
  
  def build_list 
    @ndev.rpc.get_configuration{|x| x.applications {
      x.application(:recurse => 'false')
    }}.xpath('applications/application/name').collect{ |n| n.text }
  end
  
  def build_catalog
    @catalog = {}
    @ndev.rpc.get_configuration{|x| x.applications {
      x.application
    }}.xpath('applications/application').each do |app|
      name = app.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( app, @catalog[name] )
    end    
    @catalog
  end
  
end


