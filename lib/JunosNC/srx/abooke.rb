##### ---------------------------------------------------------------
##### Provider resource methods
##### ---------------------------------------------------------------

require 'ipaddress'

class JunosNC::SRX::AddressBookEntries::Provider < JunosNC::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
    
  def xml_at_top    
    Nokogiri::XML::Builder.new{ |x| x.configuration{ 
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.address { x.name @name 
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
    xml.xpath('//address')[0]
  end  
  
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )  
    as_hash[:ip_prefix] = as_xml.xpath('ip-prefix').text
    true    
  end   
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_ip_prefix( xml )
    xml_set_or_delete( xml, 'ip-prefix', @should[:ip_prefix] )
  end
    
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class JunosNC::SRX::AddressBookEntries::Provider
  
  def build_list
    @ndev.rpc.get_configuration{ |x|
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.address({:recurse => 'false' })
          }
        }
      }}
    }.xpath('//address/name').collect{ |adr_name| 
      adr_name.text
    }
  end
  
  def build_catalog
    Hash[ @ndev.rpc.get_configuration{ |x|
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.address
          }
        }
      }}
    }.xpath('//address').collect{ |adr| 
      [ adr.xpath('name').text, adr.xpath('ip-prefix').text ]
    }]
  end
  
end

##### ---------------------------------------------------------------
##### Provider operational methods
##### ---------------------------------------------------------------

class JunosNC::SRX::AddressBookEntries::Provider
  
  def find( addr )
    lpm_cache_create!
        
    # turn the given string into a searchable IPAddress object
    find_addr = IPAddress( addr )
  
    # search the cache for a matching item
    found = @zab_lpm_cache.select{ |name, ab_addr, ipadr|
      ipadr.include? find_addr
    }
    
    return nil if found.empty?    
    
    # return a sorted result with highest prefix first
    found.sort_by{ |n,a,ip| ip.prefix }.reverse!    
  end  
  
  def lpm_find( addr )
    return nil unless found = find( addr )
    found[0]
  end
  
  private
  
  def lpm_cache_create!
    # cache is an array-of-arrays
    # [0] = address-book name
    # [1] = address-book address (string)
    # [2] = IPAddress of [1] for searching
    @zab_lpm_cache ||= catalog!.collect{ |k,adr| 
      [ k, adr, IPAddress.parse( adr ) ]
    }
  end

  def lpm_cache_clear!; @zab_lpm_cache = nil end

end

