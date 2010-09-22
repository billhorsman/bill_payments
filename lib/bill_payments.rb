module BillPayments

  def self.symbolize_keys(hash)
    new_hash = {}
    hash.each do |key, value|
      if Hash === value
        new_hash[key.to_sym] = symbolize_keys value
      else
        new_hash[key.to_sym] = value
      end        
    end
    new_hash
  end

  def self.validate_params(params, options = {})
    if options[:required]
      missing = options[:required] - params.keys
      if missing.size > 0
        raise "The params [#{missing.to_sentence}] are missing from [#{params.keys.to_sentence}]"
      end
    end
  end

end
