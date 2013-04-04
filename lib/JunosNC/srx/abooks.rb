##### ---------------------------------------------------------------
##### Provider resource methods
##### ---------------------------------------------------------------

class JunosNC::SRX::AddressBookSets::Provider < JunosNC::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
    
  def xml_at_top    
    Nokogiri::XML::Builder.new{ |x| x.configuration{ 
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.send(:'address-set') { 
              x.name @name 
              return x
            }
          }
        }
      }}
    }}
  end
  
  ### ---------------------------------------------------------------
  ### Rename
  ### ---------------------------------------------------------------
  
  def xml_element_rename( new_name )
    # @@@ for now, just allow the re-name without any checking ...
    return new_name
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//address-set')[0]
  end  
  
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )  
    
    as_hash[:list] = as_xml.xpath('address/name').collect do |this|
      this.text
    end
    
    true
  end   
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_list( xml )
    add = @should[:list] - @has[:list]
    del = @has[:list] - @should[:list]    
    add.each{ |item| xml.address { xml.name item } }
    del.each{ |item| xml.address( Netconf::JunosConfig::DELETE ) {
      xml.name item
    }}
  end
    
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class JunosNC::SRX::AddressBookSets::Provider
  
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
    
    catalog = {}
    
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
      catalog[name] = {}
      xml_read_parser( set, catalog[name] )      
    }
    
    return catalog  
  end
  
end
