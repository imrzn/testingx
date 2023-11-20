require 'json'
require 'net/http'
require 'fileutils'
require 'openssl'
require 'base64'

def decrypt_password(encrypted_password, key, iv)
decipher = OpenSSL::Cipher.new('AES-256-CBC')
decipher.decrypt
decipher.key = key
decipher.iv = iv

decrypted = decipher.update(encrypted_password) + decipher.final
end

def read_from_file(filename)
File.read(filename)
end

encrypted_password = read_from_file('_plugins/xyz/1.txt')
key = read_from_file('_plugins/xyz/2.txt')
iv = read_from_file('_plugins/xyz/3.txt')

decrypted_password = decrypt_password(encrypted_password, key, iv)

api_key = Base64.decode64(decrypted_password)

# Step 1: Fetch data from a URL in JSON format using Net::HTTP
url = URI("https://sheets.googleapis.com/v4/spreadsheets/102jPm41ih-0yhYSZC3gkI6UJgRcZA4W5k4wX8vHyeaw/values/data!A2:ZZZ?key=#{api_key}")
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true if url.scheme == 'https'

request = Net::HTTP::Get.new(url)
response = http.request(request)

if response.code == '200'
  json_data = JSON.parse(response.body)
else
  puts "Failed to fetch data. HTTP Status code: #{response.code}"
  exit
end

# Step 2: Save the fetched data as data.json in the _data directory
data_dir = '_data'
Dir.mkdir(data_dir) unless Dir.exist?(data_dir)

data_to_save = json_data['values']

File.write("#{data_dir}/data.json", JSON.pretty_generate(data_to_save))

# Step 3: Reformat the JSON structure
data_values = json_data['values']

# Step 4: Modify data[1] to lowercase and replace spaces with hyphens
data_values.each do |data|
  # Convert the second element to lowercase and replace spaces with hyphens
  data[1] = data[1].downcase.gsub(' ', '-')
end


# Step 5: Create new folders inside the "work" directory
work_dir = 'work'
FileUtils.rm_rf(work_dir) if File.directory?(work_dir)
Dir.mkdir(work_dir)

data_values.each do |data|
  folder_name = "#{work_dir}/#{data[1]}"
  Dir.mkdir(folder_name)

  # Step 6: Read the template HTML file
  template_file = File.read('demo/index.html')

  # Step 7: Replace placeholders within the HTML file with corresponding JSON data values
  modified_content = template_file.gsub(/{{\s*data\[\d+\]\s*}}/) { |match|
    index = match.scan(/\d+/).first.to_i
    data[index]
  }

  # Step 8: Write modified HTML files in their respective directories
  File.write("#{folder_name}/index.html", modified_content)
end