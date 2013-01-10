require 'cftemplate/timespan'
require 'cftemplate/fn'
require 'cftemplate/cloud_formation'

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