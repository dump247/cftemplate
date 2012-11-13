require 'ostruct'
require 'cftemplate/timespan'
require 'cftemplate/fn'

class Class
  private

  def cf_type(name)
    define_method :cf_type do
      name
    end
  end

  def array_attr_accessor(*names)
    names.each { |name|
      define_method name do |*args|
        if !args.nil? && args.length > 0
          public_send "#{name}=", args.flatten(1)
        end

        instance_variable_get("@#{name}")
      end

      define_method "#{name}=" do |value|
        instance_variable_set("@#{name}", value)
      end
    }
  end

  def attr_accessor(*names)
    names.each { |name|
      define_method name do |arg=NOT_SET|
        if arg != NOT_SET
          public_send "#{name}=", arg
        end

        instance_variable_get("@#{name}")
      end

      define_method "#{name}=" do |value|
        instance_variable_set("@#{name}", value)
      end
    }
  end

  NOT_SET=Object.new
end

module CloudFormation
  # @abstract Interface for objects that can build CloudFormation resource data.
  class CFObject
    def cf_build
      OpenStruct.new(:resource => {}, :issues => [])
    end
  end

  # @abstract CloudFormation template resource.
  class Resource < CFObject
    attr_accessor :depends_on, :metadata, :deletion_policy

    def initialize()
      @evaluate_context = nil
    end

    def deletion_policy=(value)
      case value
        when :delete
          @deletion_policy = 'Delete'
        when :retain
          @deletion_policy = 'Retain'
        when :snapshot
          @deletion_policy = 'Snapshot'
        else
          @deletion_policy = value
      end
    end

    def cf_type
      raise "Not implemented"
    end

    def cf_build()
      result = super()

      result.resource = {
          'Type' => self.cf_type,
          'Properties' => build_resource_properties(result.issues),
          'DependsOn' => build_resource_value(self.depends_on, result.issues),
          'Metadata' => build_resource_value(self.metadata, result.issues),
          'DeletionPolicy' => build_resource_value(self.deletion_policy, result.issues)
      }.delete_if { |k, v| v.nil? }

      return result
    end

    def evaluate(&block)
      if block.nil?
        return
      end

      begin
        @evaluate_context = eval 'self', block.binding
        instance_eval &block
      ensure
        @evaluate_context = nil
      end
    end

    def method_missing(method, *args, &block)
      if @evaluate_context.nil?
        super
      else
        @evaluate_context.send method, *args, &block
      end
    end

    private

    def build_resource_properties(issues)
      {}
    end

    def build_resource_value(value, issues)
      resource_value = value

      if value.is_a? CFObject
        value_result = value.cf_build()
        issues.push(*value_result.issues)
        resource_value = value_result.resource
      elsif value.is_a? Array
        resource_value = value.collect { |v| build_resource_value(v, issues) }
      elsif value.is_a? Hash
        resource_value = Hash[value.collect { |k, v| [k, build_resource_value(v, issues)] }]
      end

      return resource_value
    end
  end

  # Resource used for signaling an associated {WaitCondition}.
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitconditionhandle.html AWS::CloudFormation::WaitConditionHandle
  class WaitConditionHandle < Resource
    cf_type 'AWS::CloudFormation::WaitConditionHandle'
  end

  # Add a named AWS::CloudFormation::WaitConditionHandle resource.
  #
  # @example
  #     wait_condition_handle 'myWaitHandle'
  #
  # @see CloudFormation::WaitConditionHandle
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitconditionhandle.html AWS::CloudFormation::WaitConditionHandle
  def wait_condition_handle(name, &block)
    resource = WaitConditionHandle.new
    resource.evaluate &block
    add_resource name, resource
  end

  # Resource used for pausing the stack creation until a condition is met.
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitcondition.html AWS::CloudFormation::WaitCondition
  class WaitCondition < Resource
    cf_type 'AWS::CloudFormation::WaitCondition'
    attr_accessor :timeout, :count, :handle

    def timeout=(value)
      @timeout = value.is_a?(Timespan) ? value.to_seconds.ceil : value
    end

    def handle=(value)
      @handle = value.is_a?(String) ? FN.ref(value) : value
    end

    private

    def build_resource_properties(issues)
      {
          'Timeout' => build_resource_value(self.timeout, issues),
          'Count' => build_resource_value(self.count, issues),
          'Handle' => build_resource_value(self.handle, issues)
      }.delete_if { |k, v| v.nil? }
    end
  end

  # Add a named AWS::CloudFormation::WaitCondition resource.
  #
  # @example Wait for resource Ec2Instance to be created, or timeout after 1 hour. Creates a wait condition handle named myWaitConditionHandle
  #     wait_condition 'myWaitCondition' do
  #       timeout 1.hour
  #       depends_on 'Ec2Instance'
  #     end
  # @example Wait for resource Ec2Instance to be created, or timeout after 30 minutes, and use existing WaitConditionHandle myWaitHandle
  #     wait_condition 'myWaitCondition' do
  #       timeout 30.minutes
  #       depends_on 'Ec2Instance'
  #       handle 'myWaitHandle'
  #     end
  #
  # @see CloudFormation::WaitCondition
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitcondition.html AWS::CloudFormation::WaitCondition
  def wait_condition(name, &block)
    resource = WaitCondition.new
    resource.evaluate &block

    if resource.handle.nil?
      handle_name = "#{name}Handle"

      if not resources.include? handle_name
        wait_condition_handle handle_name
      end

      resource.handle = handle_name
    end

    add_resource(name, resource)
  end

  # Embeds a stack as a resource in a template.
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html AWS::CloudFormation::Stack
  class Stack < Resource
    cf_type 'AWS::CloudFormation::Stack'
    attr_accessor :url, :timeout, :parameters

    def timeout=(value)
      @timeout = value.is_a?(Timespan) ? value.to_minutes.ceil : value
    end

    private

    def build_resource_properties(issues)
      {
          'TemplateURL' => build_resource_value(self.url, issues),
          'TimeoutInMinutes' => build_resource_value(self.timeout, issues),
          'Parameters' => build_resource_value(self.parameters, issues)
      }.delete_if { |k, v| v.nil? }
    end
  end

  # Add a named AWS::CloudFormation::Stack resource.
  #
  # @example No timeout
  #     stack 'myStack' do
  #       url 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template'
  #     end
  # @example Timeout 1 hour with parameters
  #     stack 'myStack' do
  #       url 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template',
  #       timeout 1.hours
  #       parameters 'InstanceType' => 't1.micro',
  #                  'KeyName' => 'mykey'
  #     end
  #
  # @see CloudFormation::Stack
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html AWS::CloudFormation::Stack
  def stack(name, &block)
    resource = Stack.new
    resource.evaluate &block
    add_resource name, resource
  end

  # Define a resource without type specific helpers and validations.
  class GenericResource < Resource
    attr_accessor :properties, :type

    def cf_type
      self.type
    end

    private

    def build_resource_properties(issues)
      build_resource_value(self.properties, issues)
    end
  end

  # Generate a named resource.
  #
  # @example Wait condition
  #     resource 'myWaitCondition' do
  #       type 'AWS::CloudFormation::WaitCondition'
  #       properties 'Handle' => ref('myWaitHandle'),
  #                  'Timeout' => 1800
  #       depends_on 'myEc2Instance'
  #     end
  def resource(name, type=nil, &block)
    resource = GenericResource.new
    resource.type = type
    resource.evaluate &block
    add_resource name, resource
  end
end