require 'cftemplate/timespan'
require 'cftemplate/fn'
require 'cftemplate/cloud_formation'

module Route53
  # Route53 DNS record set.
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html AWS::Route53::RecordSet
  class RecordSet < CloudFormation::StackResource
    cf_type 'AWS::Route53::RecordSet'
    attr_accessor :name, :type, :hosted_zone_name, :hosted_zone_id, :set_identifier, :comment, :region, :ttl, :weight, :alias_target
    array_attr_accessor :resource_records
    attr_accessor_alias :id => :set_identifier,
                        :description => :comment,
                        :records => :resource_records,
                        :zone_name => :hosted_zone_name,
                        :zone_id => :hosted_zone_id

    def initialize()
      @records = []
    end

    def alias_target=(options)
      hosted_zone_id = options.delete_all(:hosted_zone_id, :zone_id, :zone)
      dns_name = options.delete_all(:dns_name, :dns)

      @alias_target = {
          'HostedZoneId' => hosted_zone_id,
          'DNSName' => dns_name
      }
    end

    def resource_record(value)
      resource_records.push(value)
    end

    alias :record :resource_record

    def type=(value)
      @type = value.is_a?(String) || value.is_a?(Symbol) ? value.to_s.upcase : value
    end

    def ttl=(value)
      @ttl = value.is_a?(Timespan) ? value.to_seconds.ceil : value
    end

    private

    def build_resource_properties(issues)
      # TODO hosted_zone_name or hosted_zone_id is required, but not both
      # TODO records is required if ttl is specified
      # TODO name and type are required
      # TODO set_identifier is required if weight is specified

      {
          'SetIdentifier' => build_resource_value(self.set_identifier, issues),
          'Name' => build_resource_value(self.name, issues),
          'Type' => build_resource_value(self.type, issues),
          'Comment' => build_resource_value(self.comment, issues),
          'HostedZoneName' => build_resource_value(self.hosted_zone_name, issues),
          'HostedZoneId' => build_resource_value(self.hosted_zone_id, issues),
          'Region' => build_resource_value(self.region, issues),
          'TTL' => build_resource_value(self.ttl, issues),
          'Weight' => build_resource_value(self.weight, issues),
          'ResourceRecords' => build_resource_value(self.records, issues),
          'AliasTarget' => build_resource_value(@alias_target, issues)
      }.delete_if { |k, v| v.nil? }
    end
  end

  # Add a AWS::Route53::RecordSet resource to the template.
  #
  # @example Adding RecordSet using HostedZoneId
  #     route53_record_set 'myDNSRecord' do
  #       type :cname
  #       name 'mysite.example.com.'
  #       description 'CNAME for my frontends.'
  #       hosted_zone_id '/hostedzone/Z3DG6IL3SJCGPX'
  #       ttl 15.minutes
  #
  #       record get_att('myLB', 'DNSName')
  #       record "192.168.0.2"
  #     end
  #
  # @see Route53::RecordSet
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html AWS::Route53::RecordSet
  def route53_record_set(name, &block)
    resource = RecordSet.new
    resource.evaluate &block
    add_resource name, resource
  end
end
