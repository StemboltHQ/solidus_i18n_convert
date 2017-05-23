require 'active_support'
require 'yaml'
require 'pp'

# Locales to be converted
TARGET_LOCALES = ["fr", "nl"]

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

# Recursively sorts a hash by its keys
def recsort(hash)
  hash = hash.sort_by(&:first).to_h
  hash.each do |k, v|
    if v.is_a? Hash
      hash[k] = recsort(v)
    end
  end
end

source = YAML.load_file("locales/en.yml")
flat_source = hash_flatten('', source['en']).to_h

TARGET_LOCALES.each do |target_locale|
  destination = YAML.load_file("locales/#{target_locale}.yml")
  flat_dest = hash_flatten('', destination[target_locale]).to_h

  missing_keys = flat_source.keys - flat_dest.keys

  missing_keys.each do |key|
    missing_value = flat_source[key]
    candidates = flat_source.select { |k, v| v == missing_value }.keys
    candidates -= missing_keys
    candidates.sort_by!(&:length)
    next if candidates.empty?

    flat_dest[key] ||= flat_dest[candidates.first]
  end

  new_locale = recsort(reconstruct(flat_dest))
  FileUtils.mkdir_p "output"
  File.open("output/#{target_locale}_new.yml", 'w') do |f|
    yaml = YAML.dump({target_locale => new_locale}, line_width: 1000)
    yaml.gsub!(/ +$/, '')
    f.write(yaml)
  end
end
