require 'pry'
require 'net/https'
require 'json'


class CountryFinder

  attr_accessor :file_path, :collection

  def initialize(*args)
    @file_path = args[0][:file_path]
    @collection = args[0][:collection]
  end

  def get_country_info(country)
    country = country.gsub(" ", "%20")
    puts "Getting info for #{country}"
    link = "https://restcountries.eu/rest/v1/name/#{country}"
    link = URI(link)

    http = Net::HTTP.new(link.host, link.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(link.request_uri)
    res = http.request(request)
  end

  def convert_country_info_to_seed_command(resp_string, country)
    if resp_string
      country_info = JSON.parse(resp_string.body)[0] rescue nil
      if country_info
        puts "writting command for #{country}"
        iso_2_country_code = country_info["alpha2Code"]
        iso_3_country_code = country_info["alpha3Code"]

        string = %Q{unless Country.find_by_name("#{country}"); Country.create!(:name => "#{country}", :iso_2_country_code => "#{iso_2_country_code}", :iso_3_country_code => "#{iso_3_country_code}"); end}
      else
        puts "#{country} doesn't have content"
      end
    end
  end

  def load_data_from_file
    file_to_read = File.open(self.file_path, "r")
    data = file_to_read.read
    CountryFinder.new(collection: data)

  end

  def get_country_satisfied_condition
    collection = self.collection.scan(/<option.+">([A-z]+\s?[A-z]+)\s\((\d+)/)

    collection = collection.collect{|x| x[0] if x[1].to_i >= 20}.compact
    CountryFinder.new(collection: collection)
  end

  def write_output_to_file
    File.open("country_done.txt", "w") do |write_file|
      self.collection.each do |country|
        response = get_country_info(country)
        write_file.puts (convert_country_info_to_seed_command(response, country))
      end
    end
  end

  def run
    finder = load_data_from_file
    finder = finder.get_country_satisfied_condition
    finder.write_output_to_file
  end
end

finder = CountryFinder.new(file_path: "country_list_html.txt")
finder.run

