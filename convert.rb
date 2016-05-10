require 'active_support'
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

# Convert the flattened hash back into a nested hash structure
def reconstruct flat_hash
  flat_hash.inject({}) do |result, (key, value)|
    # Build the nested hash for a single key/value pair
    hash = key.split(".").reverse.inject(value) do |r, e|
      { e => r }
    end

    result.deep_merge(hash)
  end
end

dest_locale = "nl"
source = YAML.load_file("locales/en.yml")
destination = YAML.load_file("locales/#{dest_locale}.yml")

flat_source = hash_flatten('', source['en']).to_h
flat_dest = hash_flatten('', destination[dest_locale]).to_h

missing_keys = flat_source.keys - flat_dest.keys

missing_keys.each do |key|
  missing_value = flat_source[key]
  candidates = flat_source.select { |k, v| v == missing_value }.keys
  candidates -= missing_keys
  candidates.sort_by!(&:length)
  next if candidates.empty?

  flat_dest[key] ||= flat_dest[candidates.first]
end

new_locale = reconstruct(flat_dest)
File.open('nl_new.yml', 'w') do |f|
  yaml = YAML.dump({dest_locale => new_locale}, line_width: 1000)
  yaml.gsub!(/ +$/, '')
  f.write(yaml)
end
