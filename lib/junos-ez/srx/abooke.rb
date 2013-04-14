##### ---------------------------------------------------------------
##### Provider resource methods
##### ---------------------------------------------------------------

require 'ipaddress'

class Junos::Ez::SRX::AddressBookEntries::Provider < Junos::Ez::Provider::Parent
  
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
  
  def xml_element_top( xml, name )
    xml.address { xml.name @name 
      return xml
    }    
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

class Junos::Ez::SRX::AddressBookEntries::Provider
  
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
    @catalog = {}
    
    @ndev.rpc.get_configuration{ |x|
      x.security { x.zones {
        x.send(:'security-zone') { x.name @parent.name
          x.send(:'address-book') {
            x.address
          }
        }
      }}
    }.xpath('//address').each{ |adr|       
      name = adr.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( adr, @catalog[name] )      
    }    
    @catalog
  end
  
end

##### ---------------------------------------------------------------
##### Provider EXPANDED methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::AddressBookEntries::Provider
  
  ## -----------------------------------------------------
  ## create a Hash from the existing provider information
  ## -----------------------------------------------------
  
  def to_h_expanded( opts = {} )           
    { :name => @parent.name,      # zone name
      :addrs => catalog
    }     
  end    
    
  ## ----------------------------------------------------------------
  ## create the XML for a complete policy rules set given a Hash
  ## structure the mimics the provider and properties for the 
  ## Policy and associated PolicyRules
  ## ----------------------------------------------------------------
  
  def xml_from_h_expanded( from_hash, opts = {} )    
    zone_name = from_hash[:name]    
    raise ArgumentError, "zone-name as :name not provided in hash" unless zone_name

    ## handle the case where 'self' is either a provider or a specific instance. 
    
    zone_pvd = self.is_provider? ? Junos::Ez::SRX::Zones::Provider.new( @ndev, zone_name ) : @parent    
    xml_top = zone_pvd.xml_at_top    
    xml_top.send(:'address-book')
    xml_add_here = xml_top.parent.at('address-book')
    
    ## now create objects and process the hash data accordingly
    
    from_hash[:addrs].each do |name, hash|
      Nokogiri::XML::Builder.with( xml_add_here ) do |xml|      
        # create the new object so we can generate XML on it
        adr = self.class.new( @ndev, name, :parent => zone_pvd )                    
        # generate the object specific XML inside
        adr.should = hash
        adr_xml = adr.xml_element_top( xml, name )    
        adr.xml_build_change( adr_xml )            
      end
    end
    
    xml_top.doc.root
  end

end

##### ---------------------------------------------------------------
##### Provider operational methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::AddressBookEntries::Provider
  
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
    @zab_lpm_cache ||= catalog!.collect{ |name, hash| 
      adr = hash[:ip_prefix]
      [ name, adr, IPAddress.parse( adr ) ]
    }
  end

  def lpm_cache_clear!; @zab_lpm_cache = nil end

end

