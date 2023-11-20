require 'fileutils'
require 'open-uri'
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

main_url = "https://sheets.googleapis.com/v4/spreadsheets/102jPm41ih-0yhYSZC3gkI6UJgRcZA4W5k4wX8vHyeaw/values/data?key=#{api_key}"

module JsonProcessor
  class Generator
    def fetch_and_save_json(url)
      begin
        # Fetch JSON data from the provided URL
        json_data = JSON.parse(URI.open(url).read)
        
        # Extract only the 'values' array and save it into _data directory as data.json
        values_data = json_data['values']
        data_to_save = { 'values' => values_data }

        File.open('_data/data.json', 'w') { |file| file.write(JSON.pretty_generate(data_to_save)) }

        generate_from_local('_data/data.json')
      rescue StandardError => e
        puts "Error fetching or processing data: #{e.message}"
      end
    end

    def generate_from_local(file_path)
        begin
          json_data = JSON.parse(File.read(file_path))
          
          # Remove the entire work directory and its contents
          FileUtils.rm_rf('work')
      
          values = json_data['values']
      
          values.each do |item_data|
            title = item_data[0]
            url = item_data[1].downcase.gsub(/\s+/, "-")  # Convert to lowercase and replace spaces with hyphens
            content = item_data[2]
            var1 = item_data[3]
            var2 = item_data[4]
            var3 = item_data[5]
            var4 = item_data[6]
      
            folder_path = File.join('work', url)
            FileUtils.mkdir_p(folder_path)
      
            generated_html = generate_html(title, url, content, var1, var2, var3, var4)
      
            File.open(File.join(folder_path, 'index.html'), 'w') do |file|
              file.write(generated_html)
            end
          end
        rescue StandardError => e
          puts "Error fetching or processing data: #{e.message}"
        end
      end      

    def generate_html(title, url, content, var1, var2, var3, var4)
      demo_html = File.read('demo/index.html')
      demo_html.gsub!('{{ title }}', title)
      demo_html.gsub!('{{ url }}', url)
      demo_html.gsub!('{{ content }}', content)
      demo_html.gsub!('{{ var1 }}', var1)
      demo_html.gsub!('{{ var2 }}', var2)
      demo_html.gsub!('{{ var3 }}', var3)
      demo_html.gsub!('{{ var4 }}', var4)
      return demo_html
    end
  end
end

# Instantiate the generator and call the fetch_and_save_json method with the URL
generator = JsonProcessor::Generator.new
generator.fetch_and_save_json(main_url)
