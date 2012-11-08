# Monkey patching for Numeric class.
class Numeric
  # Convert the number to an ordinal string (e.g. 1st, 2nd, 3rd, etc).
  #
  # @return [String] ordinal string for the number
  def to_ordinal
    (10...20) === self ? "#{self}th" : self.to_s + %w{ th st nd rd th th th th th th }[self.to_s[-1..-1].to_i]
  end
end

class Timespan
  MILLISECONDS_PER_SECOND=1000.0
  MILLISECONDS_PER_MINUTE=60.0 * MILLISECONDS_PER_SECOND

  def initialize(values)
    days = values.fetch(:days, 0)
    hours = values.fetch(:hours, 0) + (days * 24)
    minutes = values.fetch(:minutes, 0) + (hours * 60)
    seconds = values.fetch(:seconds, 0) + (minutes * 60)
    @total_mils = values.fetch(:milliseconds, 0) + (seconds * 1000)
  end

  def to_minutes
    @total_mils / MILLISECONDS_PER_MINUTE
  end

  def to_seconds
    @total_mils / MILLISECONDS_PER_SECOND
  end

  def self.minutes(value)
    Timespan.new(:minutes => value)
  end

  def self.seconds(value)
    Timespan.new(:seconds => value)
  end
end

module CloudFormation
  # Generate a AWS::CloudFormation::WaitConditionHandle resource.
  # A wait condition handle has no properties or other configuration options.
  #
  # @example
  #     wait_condition_handle 'myWaitHandle'
  #
  # @param name [String] name of the resource
  # @return [void]
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitconditionhandle.html AWS::CloudFormation::WaitConditionHandle
  def wait_condition_handle(name)
    resource name, 'AWS::CloudFormation::WaitConditionHandle'
  end

  # Generate a AWS::CloudFormation::WaitCondition resource.
  #
  # @example Wait for 1 signal or timeout after 1800 seconds (5 minutes) and generate a WaitConditionHandle with name myWaitConditionHandle
  #     wait_condition 'myWaitCondition'
  # @example Timeout 4500 seconds after the resource Ec2Instance is created. A WaitConditionHandle with name myWaitConditionHandle is generated automatically.
  #     wait_condition 'myWaitCondition', :timeout => Timespan.seconds(4500), :resource => 'Ec2Instance'
  #
  # @param name [String] name of the resource
  # @option options [Fixnum, Timespan] :timeout (1800) Number of seconds to wait for the required number of signals.
  # @option options [String] :depends (nil) Name of the resource to associate with the condition. This becomes the DependsOn of the resulting wait condition resource.
  #                                         After the resource is created, CloudFormation will wait for the condition to be signaled.
  # @option options [Fixnum] :count (1) Number of signals to wait for.
  # @option options [String, Ref] :handle (new handle) Name of a AWS::CloudFormation::WaitConditionHandle resource.
  #                                                    If not specified, a new wait handle resource named "<name>Handle" is created if it does not already exist.
  #                                                    This can be either a resource name string or a Ref function result.
  # @return [void]
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitcondition.html AWS::CloudFormation::WaitCondition
  def wait_condition(name, options={})
    location = caller()[0]

    depends_on = options.delete :depends

    properties = {
        'Timeout' => options.delete(:timeout) || 1800,
        'Count' => options.delete(:count),
        'Handle' => options.delete(:handle)
    }.reject { |k, v| v.nil? }

    if properties['Timeout'].is_a? Timespan
      properties['Timeout'] = properties['Timeout'].to_seconds.ceil
    end
    
    if properties.include? 'Handle'
      if properties['Handle'].is_a? String
        properties['Handle'] = ref(properties['Handle'])
      end
    else
      handle_name = "#{name}Handle"

      if not resources.include?(handle_name)
        wait_condition_handle handle_name
      end

      properties['Handle'] = ref(handle_name)
    end

    if not options.empty?
      $cftemplate_output.error(location, "Unknown options for wait condition: #{options}")
    end

    resource name, 'AWS::CloudFormation::WaitCondition', {
        'Properties' => properties,
        'DependsOn' => depends_on
    }.reject { |k, v| v.nil? }
  end

  # Generate a AWS::CloudFormation::Stack resource.
  #
  # @example No timeout
  #     stack 'myStack', 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template'
  # @example Timeout 5 minutes with parameters
  #     stack 'myStack', 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template',
  #           :timeout => Timespan.minutes(5),
  #           :parameters => { 'InstanceType' => 't1.micro', 'KeyName' => 'mykey' }
  #
  # @param name [String] name of the resource
  # @param url [String] The URL of a template that specifies the stack that you want to create as a resource.
  # @option options [Fixnum, Timespan] :timeout (nil) Length of time, in minutes, to wait for the embedded stack to be created. The default is to wait forever.
  # @option options [Hash<String, String>] :parameters ({}) The set of parameter values passed to the new stack.
  # @option options [String] :depends (nil) Name of a resource that must be created before this resource.
  # @return [void]
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html AWS::CloudFormation::Stack
  def stack(name, url, options={})
    location = caller()[0]

    depends_on = options.delete :depends

    properties = {
        'TemplateURL' => url,
        'TimeoutInMinutes' => options.delete(:timeout),
        'Parameters' => options.delete(:parameters)
    }.reject { |k, v| v.nil? }

    if properties.include?('TimeoutInMinutes') && properties['TimeoutInMinutes'].is_a?(Timespan)
      properties['TimeoutInMinutes'] = properties['TimeoutInMinutes'].to_minutes.ceil
    end

    if properties.include?('Parameters') && properties['Parameters'].empty?
      properties.delete 'Parameters'
    end

    if not options.empty?
      $cftemplate_output.error(location, "Unknown options for wait condition: #{options}")
    end

    resource name, 'AWS::CloudFormation::Stack', {
        'Properties' => properties,
        'DependsOn' => depends_on
    }.reject { |k, v| v.nil? }
  end
end

# CloudFormation EC2 functions.
module EC2
  # @attr_reader [String] type type of the instance (m1, m2, etc)
  # @attr_reader [String] size size of the instance (small, medium, etc)
  class InstanceType
    attr_reader :type, :size

    # Initialize a new instance.
    #
    # @param [String] type instance type (m1, m2, etc)
    # @param [String] size instance size (small, medium, etc)
    def initialize(type, size)
      @type = type
      @size = size
    end

    # Full instance type name.
    # @return [String] "type.size"
    def name;
      "#{@type}.#{@size}"
    end

    def to_s;
      name
    end
  end

  # All defined instance types.
  # @see EC2.instance_types
  # @see EC2.instance_type_names
  @@INSTANCE_TYPES = [
      InstanceType.new('t1', 'micro'),
      InstanceType.new('m1', 'small'),
      InstanceType.new('m1', 'medium'),
      InstanceType.new('m1', 'large'),
      InstanceType.new('m1', 'xlarge'),
      InstanceType.new('m2', 'xlarge'),
      InstanceType.new('m2', '2xlarge'),
      InstanceType.new('m2', '4xlarge'),
      InstanceType.new('c1', 'medium'),
      InstanceType.new('c1', 'xlarge'),
      InstanceType.new('cc1', '4xlarge'),
      InstanceType.new('cc2', '8xlarge'),
      InstanceType.new('cg1', '4xlarge'),
      InstanceType.new('hi1', '4xlarge')
  ]

  # Get information about types of EC2 instances.
  #
  # @example Get all instance types
  #   EC2.instance_types.each { |x| puts(x) }
  #
  # @example Get all m1 and m2 instance types
  #   EC2.instance_types(:m1, :m2).each { |x| puts(x) }
  #
  # @param [Array<String, Symbol>] types EC2 instance type codes to return (:t1, :m1, etc) or empty to return all instance types
  # @return [Array<InstanceType>] EC2 instance types
  def self.instance_types(*types)
    if types.length == 0
      return @@INSTANCE_TYPES
    end

    type_names = types.collect { |x| x.to_s }
    @@INSTANCE_TYPES.select { |x| type_names.include?(x.type) }
  end

  # Get the names of EC2 instance types.
  #
  # @example Get all instance type names
  #   EC2.instance_type_names.each { |x| puts(x) }
  #
  # @example Get all m1 and m2 instance type names
  #   EC2.instance_type_names(:m1, :m2).each { |x| puts(x) }
  #
  # @param [Array<String, Symbol>] types EC2 instance type codes to return (:t1, :m1, etc) or empty to return all instance types
  # @return [Array<String>] EC2 instance type names ('m1.small', 'm2.xlarge', etc)
  def self.instance_type_names(*types)
    self.instance_types(*types).collect { |x| x.name }
  end
end

# CloudFormation template functions.
module Fn
  # Generate a Fn::Select function call.
  #
  # @param index index of the object to retrieve
  # @param list list of objects to select from
  # @return [Hash] { 'Fn::Select' => [index, list] }
  def select(index, list)
    {'Fn::Select' => [index, list]}
  end

  module_function :select

  # Generate a Fn::GetAZs function call.
  #
  # @param region name of the region to get the availability zones for or
  #               'AWS::Region' to get availability zones in the region the stack was created
  # @return [Hash] { 'Fn::GetAZs' => [index, list] }
  def get_azs(region='AWS::Region')
    if region.is_a?(Hash) && region.fetch('Ref', '') == 'AWS::Region'
      # Check if called like: get_azs(aws_region)
      region = 'AWS::Region'
    end

    {'Fn::GetAZs' => region}
  end

  module_function :get_azs

  # Generate a Ref function call.
  #
  # @param name name of the object/value to reference
  # @return [Hash] { "Ref" => name }
  def ref(name)
    {'Ref' => name}
  end

  module_function :ref

  # Generate a Fn::FindInMap function call.
  #
  # @param map name of the mapping
  # @param key name of the key in the mapping
  # @param value name of the value
  # @return [Hash] { "Fn::FindInMap" => [map, key, value] }
  def find_in_map(map, key, value)
    {'Fn::FindInMap' => [map, key, value]}
  end

  module_function :find_in_map

  # Generate a Fn::GetAtt function call.
  #
  # @param resource name of the resource to get the attribute from
  # @param attribute name of the attribute to get
  # @return [Hash] { "Fn::GetAtt" => [resource, attribute] }
  def get_att(resource, attribute)
    {'Fn::GetAtt' => [resource, attribute]}
  end

  module_function :get_att

  # Generate a Fn::Base64 function call.
  #
  # @param content content to base64
  # @return [Hash] { "Fn::Base64" => content }
  def base64(content)
    {'Fn::Base64' => content}
  end

  module_function :base64

  # Generate a Fn::Join function call.
  #
  # @param [String] separator separator to place between content values
  # @param [Array] content content values to join
  # @return [Hash] { "Fn::Join" => [separator, content] }
  def join(separator, *content)
    values = content

    if values.nil? || values.length == 0
      values = []
    elsif values.length == 1 && values[0].is_a?(Array)
      values = values[0]
    end

    {'Fn::Join' => [separator, values]};
  end

  module_function :join

  # Generate a Ref for the current AWS region.
  #
  # This is equivalent to ref("AWS::Region").
  #
  # @return [Hash] { "Ref" => "AWS::Region" }
  def aws_region
    ref("AWS::Region")
  end

  module_function :aws_region

  # Generate a Ref for the current AWS stack name.
  #
  # This is equivalent ot ref("AWS::StackName").
  #
  # @return [Hash] { "Ref" => "AWS::StackName" }
  def aws_stack_name
    ref("AWS::StackName")
  end

  module_function :aws_stack_name
end

class TemplateV1
  include Fn
  include CloudFormation

  VERSION='2010-09-09'

  attr_reader :description, :resources

  def initialize(description='', &block)
    @description = description
    @resources = {}

    instance_eval(&block)
  end

  def parameter(name, type, description='', args={})
    location = caller()[0]

    if not description.is_a? String
      args = description
      description = ''
    end

    paramData = Hash[args.map { |k, v| [k.to_s, v] }]

    if paramData.include?('Type') || paramData.include?('type')
      $cftemplate_output.error(location, "The type for parameter #{name} must be passed as a method argument and not as a keyword argument.")
      paramData.delete 'Type'
      paramData.delete 'type'
    end

    paramData['Type'] = type

    if paramData.include?('Description') || paramData.include?('description')
      $cftemplate_output.error(location, "The description for parameter #{name} must be passed as a method argument and not as a keyword argument.")
      paramData.delete 'Description'
      paramData.delete 'description'
    end

    unless description.nil? || description.length == 0
      paramData['Description'] = description
    end

    if paramData.include? 'length'
      if paramData.include?('MinLength') || paramData.include?('MaxLength')
        $cftemplate_output.warn(location, "Both length and MinLength/MaxLength have been specified for parameter #{name}. The length attribute overrides MinLength/MaxLength.")
      end

      if paramData['length'].is_a? Numeric
        paramData['MinLength'] = paramData['length']
        paramData['MaxLength'] = paramData['length']
      else
        paramData['MinLength'] = paramData['length'].min
        paramData['MaxLength'] = paramData['length'].max
      end

      paramData.delete 'length'
    end

    if paramData.include? 'range'
      if paramData.include?('MinValue') || paramData.include?('MaxValue')
        $cftemplate_output.warn(location, "Both range and MinValue/MaxValue have been specified for parameter #{name}. The range attribute overrides MinValue/MaxValue.")
      end

      paramData['MinValue'] = paramData['range'].min
      paramData['MaxValue'] = paramData['range'].max
      paramData.delete 'range'
    end

    if paramData.include? 'values'
      if paramData.include?('AllowedValues')
        $cftemplate_output.warn(location, "Both values and AllowedValues have been specified for parameter #{name}. The values attribute overrides AllowedValues.")
      end

      paramData['AllowedValues'] = paramData['values']
      paramData.delete 'values'
    end

    if paramData.include? 'pattern'
      if paramData.include?('AllowedPattern')
        $cftemplate_output.warn(location, "Both pattern and AllowedPattern have been specified for parameter #{name}. The pattern attribute overrides AllowedPattern.")
      end

      paramData['AllowedPattern'] = paramData['pattern']
      paramData.delete 'pattern'
    end

    if paramData.include? 'constraint'
      if paramData.include?('ConstraintDescription')
        $cftemplate_output.warn(location, "Both constraint and ConstraintDescription have been specified for parameter #{name}. The constraint attribute overrides ConstraintDescription.")
      end

      paramData['ConstraintDescription'] = paramData['constraint']
      paramData.delete 'constraint'
    end

    if paramData.include? 'default'
      if paramData.include?('Default')
        $cftemplate_output.warn(location, "Both default and Default have been specified for parameter #{name}. The default attribute overrides Default.")
      end

      paramData['Default'] = paramData['default']
      paramData.delete 'default'
    end

    if paramData.include? 'echo'
      if paramData.include?('NoEcho')
        $cftemplate_output.warn(location, "Both echo and NoEcho have been specified for parameter #{name}. The echo attribute overrides NoEcho.")
      end

      paramData['NoEcho'] = !paramData['echo']
      paramData.delete 'echo'
    end

    $cftemplate_output.addParameter(location, name, clean_obj(paramData))
  end

  def mapping(name, values={})
    location = caller()[0]
    $cftemplate_output.addMapping(location, name, clean_obj(values))
  end

  def resource(name, type, options={})
    location = caller()[0]

    if type.is_a? Hash
      resource = clean_obj(options.merge(type))
    else
      resource = clean_obj(options.merge('Type' => type))
    end

    if not resources.include?(name)
      resources[name] = resource
    end

    $cftemplate_output.addResource(location, name, resource)
  end

  def output(name, value, description='')
    location = caller()[0]
    $cftemplate_output.addOutput(location, name, clean_obj('Value' => value, 'Description' => description))
  end

  def file(path, interpolate=true)
    content = IO.read(path)

    if interpolate
      start_index = content.index('{{')
      end_index = 0

      if not start_index.nil?
        new_content = []

        while not start_index.nil?
          if start_index != end_index
            new_content << content.slice(end_index..(start_index - 1))
          end

          end_index = content.index('}}', start_index)

          if end_index.nil?
            # TODO get line number
            # First arg "#{path}:#{line}"
            $cftemplate_output.error(path, "Unable to find matching close braces.")
            end_index = start_index
            break
          end

          variable_content = content.slice((start_index + 2)..(end_index - 1))

          begin
            new_content << eval(variable_content)
          rescue Exception => ex
            # TODO get line number
            # First arg "#{path}:#{line}"
            $cftemplate_output.error(path, "Error evaluating '#{variable_content}'. Error: #{$!}")
            break
          end

          end_index += 2
          start_index = content.index('{{', end_index)
        end

        new_content << content.slice(end_index..-1)
        content = join('', *new_content)
      end
    end

    return content
  end

  def tags(tags={})
    options = tag_options(tags)

    tags.collect { |k, v|
      if v.is_a? Hash
        options.merge(v).merge('Key' => k)
      else
        options.merge('Key' => k, 'Value' => v)
      end
    }
  end

  def tag(key_or_value, value={}, options={})
    if value.is_a?(Hash)
      tag_options(options).merge(tag_options(value)).merge('Value' => key_or_value)
    else
      tag_options(options).merge('Key' => key_or_value, 'Value' => value)
    end
  end

  private

  def tag_options(options)
    result = {}

    if options.fetch(:propagate, false)
      result['PropagateAtLaunch'] = true
    end
    options.delete :propagate

    return result
  end

  def clean_obj(map)
    cleaned = nil

    if map.is_a? Hash
      cleaned = {}

      map.each do |k, v|
        cleaned[k.to_s] = clean_obj(v)
      end
    elsif map.is_a? String
      cleaned = map
    elsif map.is_a?(TrueClass) || map.is_a?(FalseClass)
      cleaned = map ? 'true' : 'false'
    elsif map.is_a?(Symbol) || map.is_a?(Numeric)
      cleaned = map.to_s
    elsif map.is_a? Enumerable
      cleaned = map.collect { |x| clean_obj(x) }
    else
      raise "Unsupported value type: #{map}"
    end

    return cleaned
  end

end

def template(version, description='', &block)
  tmpl = nil
  $cftemplate_output.setVersion(caller()[0], version, description)

  case version
    when TemplateV1::VERSION
      tmpl = TemplateV1.new(description, &block)
    else
      return
  end

  # Apply parameter overrides
  #if result[0].include?('Parameters')
  #  $cftemplate_parameters.each { |pname, pvalue|
  #    if result[0]['Parameters'].include?(pname)
  #      result[0]['Parameters'][pname]['Default'] = pvalue
  #    end
  #  }
  #end

  return tmpl
end

