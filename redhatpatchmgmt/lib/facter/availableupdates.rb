#fact for hash of available updates for packages
Facter.add('availableUpdates') do
  setcode do
   require 'yaml'
   if (File.file?('/var/local/data.yaml'))
    availableUpdates = YAML.load_file "/var/local/data.yaml"
   end
  end
end
