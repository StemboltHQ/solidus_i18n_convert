require 'yaml'
require 'pp'

# Flatten hash by joining nested keys with periods and assigning the same value
def unwrap prefix, value
  if value.is_a? Hash
    value.flat_map do |k, v|
      key = prefix.empty? ? k : [prefix, k].join('.')
      unwrap(key, v)
    end
  else
    [[prefix, value]]
  end
end

source = YAML.load_file("locales/en.yml")
destination = YAML.load_file("locales/nl.yml")

flat_source = unwrap('', source['en']).to_h
flat_dest = unwrap('', destination['nl']).to_h

missing_keys = flat_source.keys - flat_dest.keys

missing_keys.each do |key|
  missing_value = flat_source[key]
  candidates = flat_source.select { |k, v| v == missing_value }.keys
  candidates.delete(key)
  pp candidates
end