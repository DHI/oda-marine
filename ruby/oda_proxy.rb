require 'savon'
  
class ODAProxy
  
  attr_reader :filename
  attr_accessor :parameters, :species, :include_species
  
  BOTTLE = 10
  PROFILE = 18
  PHYTO = 15
  ZOO = 14
  KD = 23
  SECCHI = 19    
  
  def initialize(opts={})
    @filename = opts[:filename]
	@name_parameters = opts[:name_parameters] || false
    @include_species = opts[:include_species] || false
    
	@defaults = {parameterId: -1,slutDT: "2020-01-01",lonMin:5,lonMax:20,latMin:54,latMax:58}
	
	puts "Named paramters #@name_parameters"
	
	File.delete filename if File.exists? filename
	
	if opts[:header]
	  write_header
	end
	
    @url = "https://odahavdata.oda.dk/ODAHavData.asmx?WSDL"
    @client = Savon::Client.new(wsdl: @url,endpoint: @url, ssl_verify_mode: :none,log: false)
  end


  def get_bottle_data_by_station(opts)
    soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = BOTTLE
	get_data_by_station soap_opts
  end
  
  def get_profile_data_by_station(opts)
	soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = PROFILE
	get_data_by_station soap_opts
  end
  
  def get_bottle_data_by_area(opts)
    soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = BOTTLE
    get_data_by_area soap_opts
  end
  
  def get_profile_data_by_area(opts)
	soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = PROFILE
    get_data_by_area soap_opts
  end
  
  def get_kd_data_by_station(opts)
    soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = KD
	get_data_by_station soap_opts
  end
    
  def get_secchi_data_by_station(opts)
    soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = SECCHI
	get_data_by_station soap_opts
  end
  
  def get_kd_data_by_area(opts)
    soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = KD
	get_data_by_area soap_opts
  end
      
  def get_phyto_data_by_station(opts)
	soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = PHYTO
	get_data_by_station soap_opts
  end
    
  def get_zoo_data_by_station(opts)
	soap_opts = @defaults.merge opts
	soap_opts[:dataemneId] = ZOO
	get_data_by_station soap_opts
  end
  
  #===============================================================================================
  private
  #===============================================================================================

  def get_data_by_area(soap_opts)
    @topic = soap_opts[:dataemneId]
    puts "Connecting to SOAP Service at #{@url} with parameters:"
    puts soap_opts
    response = @client.call(:get_data_by_area,message: soap_opts)
    
    begin
	  if response.nil?
	    puts "No data in dataset"
	  else
	    data = response.to_hash[:get_data_by_area_response][:get_data_by_area_result][:oda_data]
        write_data_to_file data
	  end
    rescue Savon::Error => error
      puts error
    end
  end

  def get_data_by_station(soap_opts)
    @topic = soap_opts[:dataemneId]
    puts "Connecting to SOAP Service at #{@url} with parameters:"
    puts soap_opts
    response = @client.call(:get_data_by_station,message: soap_opts)
    
    begin
	  if response.nil?
	    puts "No data in dataset"
	  else
        data = response.to_hash[:get_data_by_station_response][:get_data_by_station_result][:oda_data]
        write_data_to_file data
	  end
    rescue => error
      puts error
      puts error.backtrace
    end
  end
  
  def write_data_to_file data
    lines = data.map do |row|
               
               if @include_species
                   [
                     row[:station_navn],
                     row[:lon],
                     row[:lat],
                     row[:dato].strftime("%Y-%m-%d %H:%M:%S"),
                     parameter_name_or_id(row[:parameter_id]),
                     species_name_or_id(row[:art_id]),
                     row[:enhed],
                     row[:dybde],
                     row[:vaerdi],
                     row[:q_aniveau]
                     ].join(",")
                     
                 else
                   [
                     row[:station_navn],
                     row[:lon],
                     row[:lat],
                     row[:dato].strftime("%Y-%m-%d %H:%M:%S"),
                     parameter_name_or_id(row[:parameter_id]),
                     row[:enhed],
                     row[:dybde],
                     row[:vaerdi],
                     row[:q_aniveau]
                     ].join(",")
                 end
      end
        
      File.open(@filename,"a:UTF-8") do |f|
        f.write lines.join("\n")
        f.write("\n")
      end
  end
  
  def write_header
    File.open(@filename,"a") do |f|
        #f.write "\uFEFF" # UTF-8 Byte order marker
		if @include_species
			f.write "Station,Lon,Lat,DateTime,Parameter,Species,Unit,Depth,Value,QALevel\n" 
		else
			f.write "Station,Lon,Lat,DateTime,Parameter,Unit,Depth,Value,QALevel\n" 
		end
      end
  end
  
  
  
  def parameter_name_or_id id
    if  @name_parameters
      name = "Undefined"
      if [ZOO,PHYTO].include? @topic
          id = "10000" + id
      end
      begin
        name = @parameters.find{|p| p["id"] == id}["name"]   
      rescue
        puts "Could not find parameter name for id: #{id}"
      end
      name
    else
      id
    end
  end
    
    def species_name_or_id id
    if  @name_parameters
      name = "Undefined"
      begin
          name = @species.find{|p| p["id"] == id}["name"]   
      rescue
          puts "Could not find species name for id: #{id}"
      end
      name
    else
      id
    end
  end
  

end