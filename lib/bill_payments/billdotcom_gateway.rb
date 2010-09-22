module BillPayments

  class BilldotcomGateway < Gateway

    attr_accessor :debug
    
    URL = "https://api.bill.com/crudApi"

    HANDLERS = {
      :vendor => :build_vendor
    }

    def self.send_xml(xml)
      uri = URI.parse(URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(uri.request_uri)
      Rails.logger.debug xml
      request.set_form_data({:request => xml})
      response = http.request(request)
      Rails.logger.debug response.body
      return response.body
    end
    
    def org_ids
      @org_ids
    end

    def initialize(options = {})
      @application_key = options[:application_key]
      @email = options[:email]
      @password = options[:password]
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.request(:version => "1.0", :applicationkey => @application_key) do
          xml.getorglist do
            xml.username @email
            xml.password @password
          end
        end
      end
      doc  = Nokogiri::XML(BilldotcomGateway.send_xml(builder.to_xml))
      @org_ids = doc.xpath("//orgID").map(&:content)
      login
    end
    
    def login
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.request(:version => "1.0", :applicationkey => @application_key) do
          xml.login do
            xml.username @email
            xml.password @password
            xml.orgID @org_ids.first
          end
        end
      end
      xml = BilldotcomGateway.send_xml(builder.to_xml)
      doc  = Nokogiri::XML(xml)
      statusNode = doc.at_xpath("//status")
      if statusNode
        result = { :status => statusNode.content }
        if result[:status] == "OK"
          @session_id = doc.at_xpath("//sessionId").content
          result[:session_id] = @session_id
        end
        result
      else
        xml
      end
    end
  
    def make_request(request_xml)
      response_xml = BilldotcomGateway.send_xml(request_xml)
      doc = Nokogiri::XML(response_xml)
      statusNode = doc.at_xpath("//status")
      if statusNode.nil?
        raise "No status"
      end
      # Check for expired session
      errorCodeNode = doc.at_xpath("//loginresult/errorcode")
      if errorCodeNode && errorCodeNode.content == "BDCE015"
        # Invalid session. Try logging in again
        login
        # retry the request with the new session_id
        request_xml.sub!(/sessionId=\".*\"/, "sessionId=\"#{@session_id}\"")
        response_xml = BilldotcomGateway.send_xml(request_xml)
        doc = Nokogiri::XML(response_xml)
        statusNode = doc.at_xpath("//status")
        if statusNode.nil?
          raise "No status"
        end
      end
      result = { :status => statusNode.content }
      if result[:status] == "OK"
        responseNode = doc.at_xpath("//response")
        if responseNode.nil?
          raise "No response"
        end
        responseNode.xpath("//data").each do |dataNode|
          dataNode.children.each do |childNode|
            setName = "#{childNode.name}s"
            result[setName] ||= []
            handler = HANDLERS[childNode.name.to_sym]
            if handler
              result[setName] << send(handler, childNode)
            end
          end
        end
        if debug
          result[:request] = request_xml
          result[:response] = response_xml
        end
        idNode = responseNode.at_xpath("//operationresult/id")
        if idNode
          result[:id] = idNode.content
        end
        return result
      else
        result[:request] = request_xml
        result[:response] = response_xml
        return result
      end
    end

    def build_vendor(node)
      {
        :id => extract(node, "id"),
        :name => extract(node, "name"),
        :address1 => extract(node, "address1"),
        :address2 => extract(node, "address2"),
        :city => extract(node, "addressCity"),
        :state => extract(node, "addressState"),
        :postal_code => extract(node, "addressZip"),
        :country => extract(node, "addressCountry"),
        :name_on_check => extract(node, "nameOnCheck")
      }
    end

    def extract(node, name)
      n = node.at_xpath("#{name}")
      if n
        n.content
      else
        nil
      end
    end

    def list_vendors
      builder = build_xml do |xml|
        xml.get_list(:object => 'vendor')
      end
      make_request(builder.to_xml)
    end

    # :vendor_id
    # :invoice_number
    # :invoice_date
    # :amount_in_cents
    # :due_date (optional)
    #
    def create_bill(params = {})
      params = BillPayments::symbolize_keys(params)
      BillPayments::validate_params(params, :required => [:vendor_id, :invoice_number, :invoice_date, :amount_in_cents])
      params[:due_date] ||= params[:invoice_date]
      builder = build_xml do |xml|
        xml.create_bill do
          xml.bill do 
            xml.invoiceNumber params[:invoice_number]
            xml.invoiceDate params[:invoice_date]
            xml.vendorId params[:vendor_id]
            xml.amount params[:amount_in_cents].to_i / 100.0
            xml.dueDate params[:due_date]
          end
        end
      end
      make_request(builder.to_xml)
    end

    # :address1
    # :address2 (optional)
    # :city
    # :postal_code
    # :country
    # :name_on_check (optional, defaults to name)
    # :account_number (optional)
    #
    def create_vendor(params = {})
      params = BillPayments::symbolize_keys(params)
      BillPayments::validate_params(params, :required => [:address1, :city, :state, :postal_code, :country, :name])
      builder = build_xml do |xml|
        xml.create_vendor do
          xml.vendor do 
            xml.name params[:name]
            xml.address1 params[:address1]
            xml.address2 params[:address2]
            xml.addressCity params[:city]
            xml.addressState params[:state]
            xml.addressZip params[:postal_code]
            xml.addressCountry params[:country]
            xml.nameOnCheck params[:name_on_check] || params[:name]
            xml.accNumber params[:account_number] if params[:account_number]
          end
        end
      end
      make_request(builder.to_xml)
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
      params = BillPayments::symbolize_keys(params)
      BillPayments::validate_params(params, :required => [:id, :address1, :city, :state, :postal_code, :country, :name])
      builder = build_xml do |xml|
        xml.update_vendor do
          xml.vendor do 
            xml.id_ params[:id]
            xml.isActive 1
            xml.name params[:name]
            xml.address1 params[:address1]
            xml.address2 params[:address2]
            xml.addressCity params[:city]
            xml.addressState params[:state]
            xml.addressZip params[:postal_code]
            xml.addressCountry params[:country]
            xml.nameOnCheck params[:name_on_check] || params[:name]
            xml.accNumber params[:account_number] if params[:account_number]
          end
        end
      end
      make_request(builder.to_xml)
    end
    
    def fetch_vendor(id)
      builder = build_xml do |xml|
        xml.get_list(:object => 'vendor') do 
          xml.filter do 
            xml.expression do 
              xml.field 'id'
              xml.operator '='
              xml.value id
            end
          end
        end
      end
      make_request(builder.to_xml)
    end
    
    def build_xml(&block)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.request(:version => "1.0", :applicationkey => @application_key) do
          xml.operation(:sessionId => @session_id) do
            block.call(xml)
          end
        end
      end
    end
    
    def test_build
      builder = build_xml do |xml|
        xml.foo
      end
      builder.to_xml
    end

  end

end