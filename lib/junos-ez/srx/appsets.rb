class Junos::Ez::SRX::AppSets::Provider < Junos::Ez::Provider::Parent
    
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.applications {
        x.send(:'application-set') { 
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
    xml.xpath('applications/application-set')[0]
  end
    
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )            
    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text }
    as_hash[:app_names] = as_xml.xpath('application/name').collect{|i| i.text }
    as_hash[:app_sets] = as_xml.xpath('application-set/name').collect{|i| i.text }
    return true
  end    
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------  
  
  def xml_change_app_names( xml )
    add, del = diff_property_array( :app_names )       
    return false if add.empty? and del.empty?
    
    add.each{ |item| xml.application { xml.name item } }    
    del.each{ |item| xml.application( Netconf::JunosConfig::DELETE ) {  xml.name item  }}   
  end
  
  def xml_change_app_sets( xml )
    add, del = diff_property_array( :app_sets )       
    return false if add.empty? and del.empty?
    
    add.each{ |item| xml.send(:'applicaiton-set') { xml.name item } }
    del.each{ |item| xml.send(:'application-set', Netconf::JunosConfig::DELETE ) { xml.name item }}       
  end
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::SRX::AppSets::Provider
  
  def build_list 
    @ndev.rpc.get_configuration{|x| x.applications {
      x.send(:'application-set', :recurse => 'false' )
    }}.xpath('applications/application-set/name').collect{ |n| n.text }
  end
  
  def build_catalog
    @catalog = {}
    @ndev.rpc.get_configuration{|x| x.applications {
      x.send(:'application-set')
    }}.xpath('applications/application-set').each do |app|
      name = app.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( app, @catalog[name] )
    end    
    @catalog
  end
  
end


