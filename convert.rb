require 'yaml'
require 'pp'

# Flatten hash by joining nested keys with periods and assigning the same value
def hash_flatten prefix, value
  if value.is_a? Hash
    value.flat_map do |k, v|
      key = prefix.empty? ? k : [prefix, k].join('.')
      hash_flatten(key, v)
    end
  else
    [[prefix, value]]
  end
end

source = YAML.load_file("locales/en.yml")
destination = YAML.load_file("locales/nl.yml")

flat_source = hash_flatten('', source['en']).to_h
flat_dest = hash_flatten('', destination['nl']).to_h

missing_keys = flat_source.keys - flat_dest.keys

missing_keys.each do |key|
  missing_value = flat_source[key]
  candidates = flat_source.select { |k, v| v == missing_value }.keys
  candidates -= missing_keys
  candidates.sort_by!(&:length)
  next if candidates.empty?

  puts "dest[#{key.inspect}] ||= source[#{candidates.first.inspect}]"
end
