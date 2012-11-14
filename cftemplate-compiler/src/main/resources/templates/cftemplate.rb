require 'cftemplate/timespan'
require 'cftemplate/numeric'
require 'cftemplate/aws'
require 'cftemplate/fn'
require 'cftemplate/ref'
require 'cftemplate/cloud_formation'
require 'cftemplate/iam'
require 'cftemplate/route53'

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

class TemplateV1
  include FN
  include Ref
  include CloudFormation
  include Iam
  include Route53

  VERSION='2010-09-09'

  attr_reader :description, :resources
  attr_accessor :overrides

  def initialize(description='')
    @description = description
    @resources = {}
    @overrides = {}
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

    if overrides.include?(name) && !overrides[name].nil?
      paramData['Default'] = overrides[name]
    end

    $cftemplate_output.addParameter(location, name, clean_obj(paramData))
  end

  def mapping(name, values={})
    location = caller()[0]
    $cftemplate_output.addMapping(location, name, clean_obj(values))
  end

  #def resource(name, type, options={})
  #  location = caller()[0]
  #
  #  if type.is_a? Hash
  #    resource = clean_obj(options.merge(type))
  #  else
  #    resource = clean_obj(options.merge('Type' => type))
  #  end
  #
  #  if name.nil?
  #    return resource
  #  else
  #    if not resources.include?(name)
  #      resources[name] = resource
  #    end
  #
  #    $cftemplate_output.addResource(location, name, resource)
  #
  #    return Fn.ref(name)
  #  end
  #end

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

  def tags(tags={}, options={})
    options = tag_options(options)

    tags.collect { |k, v|
      if v.is_a?(Hash) && v.include?('Value')
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

  def add_resource(name, resource)
    if !resources.include? name
      resources[name] = resource
    end

    build_result = resource.cf_build()
    $cftemplate_output.addResource(nil, name, build_result.resource)
    FN.ref(name)
  end

  def create_resource(location, name, options, &block)
    # TODO
  end

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
      tmpl = TemplateV1.new(description)
      tmpl.overrides.merge!($cftemplate_parameters)
      tmpl.instance_eval &block
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

