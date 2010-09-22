module BillPayments

  class BogusGateway < Gateway
  
    def self.authenticate(application_key, email, password)
    end
  
    def list_vendors
      {:status => "OK", :vendors => []}
    end

    # :vendor_id
    # :invoice_number
    # :invoice_date
    # :amount_in_cents
    # :due_date (optional)
    #
    def create_bill(params = {})
      {:status => "OK", :id => generate_unique_id}
    end

    # :address1
    # :address2 (optional)
    # :city
    # :postal_code
    # :country
    # :name
    # :id (optional)
    #
    def create_vendor(params = {})
      {:status => "OK", :id => generate_unique_id}
    end
  
    def generate_unique_id
      ((Time.zone.now.to_i + rand) * 10000).to_i.to_s
    end

  end

end