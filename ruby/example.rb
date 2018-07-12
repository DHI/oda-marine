require 'csv'
require_relative 'oda_proxy'

parameters = %w{
 33
 1154
 50
 51
 1230
}
                                     

years = (2012..2017).to_a
months = (1..11).to_a

years.each do |year|
    months.each do |month|

        proxy = ODAProxy.new(filename: File.expand_path("output_#{year}_#{month}.csv"),
                             header:true,
                             name_parameters:true)

        proxy.parameters = CSV.read("oda_parameters.csv",headers:true)    
        proxy.species = CSV.read("species.csv",headers:true) 

        startdt = Date.new(year,month,1).strftime("%Y-%m-%d")
        enddt = Date.new(year,month+1,1).strftime("%Y-%m-%d")
        
        parameters.each do |param|
            opts = {
                stationName: -1,
                startDT: startdt,
                slutDT: enddt,
                parameterId: param
            }        
            proxy.get_profile_data_by_area opts
            
            sleep(10.0)
        end
    end
end
