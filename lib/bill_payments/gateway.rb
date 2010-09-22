module BillPayments

  class Gateway
 
    def initialize(options = {})
    end
  
    def list_vendors
    end
  
    # :name
    # :address1
    # :address2 (optional)
    # :city
    # :postal_code
    # :country
    # :name_on_check (optional, defaults to name)
    # :account_number (optional)
    #
    def create_vendor(params = {})
    end
    
    # :id (bill.com reference)
    # :name
    # :address1
    # :address2 (optional)
    # :city
    # :postal_code
    # :country
    # :name_on_check (optional, defaults to name)
    # :account_number (optional)
    #
    def update_vendor(params = {})
    end
    
    def update_or_create_vendor(params = {})
      result = fetch_vendor params[:id] 
      if result[:vendors] && result[:vendors].first
        update_vendor(params)
      else
        create_vendor(params)
      end
    end
  
    # :vendor_id
    # :invoice_number
    # :invoice_date
    # :amount_in_cents
    # :due_date (optional)
    #
    def create_bill(params = {})
    end
    
  end

end