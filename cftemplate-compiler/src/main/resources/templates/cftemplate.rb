require 'cftemplate/timespan'
require 'cftemplate/numeric'
require 'cftemplate/aws'
require 'cftemplate/fn'
require 'cftemplate/ref'
require 'cftemplate/cloud_formation'
require 'cftemplate/iam'
require 'cftemplate/route53'
require 'cftemplate/ec2'

module CloudFormation
  class Template
    include FN
    include Ref
    include CloudFormation
    include Iam
    include Route53
    include EC2

    VERSION='2010-09-09'

    attr_reader :resources
    attr_accessor :description, :overrides

    def initialize()
      @resources = {}
      @overrides = {}
    end

    def parameter(name, type, &block)
      location = caller()[0]

      param = nil

      if type.is_a? Class
        type = type.name.downcase.to_sym
      elsif type.is_a? String
        type = type.downcase.to_sym
      elsif type.is_a? Symbol
        type = type.downcase.to_sym
      end

      if type == :string
        param = StringParameter.new name
      elsif type == :number || type == :integer || type == :float
        param = NumberParameter.new name
      elsif type == :commadelimitedlist || type == :list || type == :array
        param = CommaDelimitedListParameter.new name
      else
        $cftemplate_output.error(location, "Unsupported type #{type} for parameter #{name}")
      end

      if !param.nil?
        param.evaluate &block

        if overrides.include?(name) && !overrides[name].nil?
          param.default = overrides[name]
        end

        $cftemplate_output.addParameter(location, name, clean_obj(param.cf_build.resource))
      end
    end

    def mappings(values={})
      location = caller()[0]
      values.each { |k, v|
        $cftemplate_output.addMapping(location, clean_obj(k), clean_obj(v))
      }
    end

    alias :mapping :mappings

    def output(name, &block)
      location = caller()[0]

      if name.is_a? Hash
        if !block.nil?
          $cftemplate_output.error(location, "Block and hash provided for output")
        end

        outputs(name)
      else
        out = StackOutput.new
        out.evaluate &block
        $cftemplate_output.addOutput(location, name, clean_obj(out.cf_build.resource))
      end
    end

    def outputs(values)
      location = caller()[0]

      values.each { |k, v|
        $cftemplate_output.addOutput(location, k, clean_obj('Value' => v))
      }
    end

    def file(path, options={})
      content = IO.read(path)
      $cftemplate_output.addFile(path)

      interpolate = options.fetch(:interpolate, true)

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
      $cftemplate_output.addResource(nil, clean_obj(name), build_result.resource)
      FN.ref(name)
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
end

def template(version, &block)
  tmpl = nil

  case version
    when CloudFormation::Template::VERSION
      tmpl = CloudFormation::Template.new()
      tmpl.overrides.merge!($cftemplate_parameters)
      tmpl.instance_eval &block
      $cftemplate_output.setVersion(caller()[0], version, tmpl.description)
    else
      return
  end

  return tmpl
end

