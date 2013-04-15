##### ---------------------------------------------------------------
##### Provider resource methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::AddressBookSets::Provider < Junos::Ez::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
    
  def xml_at_top    
    Nokogiri::XML::Builder.new{ |x| x.configuration{ 
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            return xml_element_top( x, @name )           
          }
        }
      }}
    }}
  end
  
  def xml_element_top( xml, name )
    xml.send(:'address-set') { 
      xml.name name 
      return xml
    }    
  end
    
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//address-set')[0]
  end  
  
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )  
    
    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text }
    as_hash[:addr_names] = as_xml.xpath('address/name').collect{ |i| i.text }
    as_hash[:addr_sets] = as_xml.xpath('address-set/name').collect{ |i| i.text }
    
    true
  end   
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_addr_names( xml )
    add, del = diff_property_array( :addr_names )       
    return false if add.empty? and del.empty?
    
    add.each{ |item| xml.address { xml.name item } }
    del.each{ |item| xml.address( Netconf::JunosConfig::DELETE ) { xml.name item }}
  end
  
  def xml_change_addr_sets( xml )
    add, del = diff_property_array( :addr_sets )       
    return false if add.empty? and del.empty?
    
    add.each{ |item| xml.send(:'address-set') { xml.name item } }
    del.each{ |item| xml.send(:'address-set', Netconf::JunosConfig::DELETE ) {  xml.name item  }}
  end
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::AddressBookSets::Provider
  
  def build_list   
    @ndev.rpc.get_configuration{ |x|
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.send(:'address-set', {:recurse => 'false' })
          }
        }
      }}
    }.xpath('//address-set/name').collect{ |this| 
      this.text
    }
  end
  
  def build_catalog    
    
    @catalog = {}
    
    @ndev.rpc.get_configuration{ |x|
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.send(:'address-set')
          }
        }
      }}
    }.xpath('//address-set').each{ |set| 
      name = set.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( set, @catalog[name] )      
    }
    
    return @catalog  
  end
  
end

##### ---------------------------------------------------------------
##### Provider EXPANDED methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::AddressBookSets::Provider
  
  ## -----------------------------------------------------
  ## create a Hash from the existing provider information
  ## -----------------------------------------------------
  
  def to_h_expanded( opts = {} )   
    { :name => @parent.name,      # zone name
      :sets => catalog
    } 
  end    
    
  ## ----------------------------------------------------------------
  ## create the XML for a complete policy rules set given a Hash
  ## structure the mimics the provider and properties for the 
  ## Policy and associated PolicyRules
  ## ----------------------------------------------------------------
  
  def xml_from_h_expanded( from_hash, opts = {} )    
    zone_name = from_hash[:name]    
    raise ArgumentError, ":name not provided in hash" unless from_hash[:name]
    
    ## Need to set the Nokogiri xml_add_here (Element) to the address-book element
    ## for provider zone (@parent)
    
    zone_pvd = self.is_provider? ? Junos::Ez::SRX::Zones::Provider.new( @ndev, zone_name ) : @parent    
    xml_top = zone_pvd.xml_at_top    
    xml_top.send(:'address-book')
    xml_add_here = xml_top.parent.at('address-book')
    
    ## now create objects and process the hash data accordingly
    
    from_hash[:sets].each do |name, hash|
      Nokogiri::XML::Builder.with( xml_add_here ) do |xml|      
        # create the new object so we can generate XML on it
        obj = self.class.new( @ndev, name, :parent => zone_pvd )                    
        # generate the object specific XML inside
        obj.should = hash
        obj_xml = obj.xml_element_top( xml, name )    
        obj.xml_build_change( obj_xml )            
      end
    end
    
    xml_top.doc.root        
  end

end

