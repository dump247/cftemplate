

# AWS Identity and Access Management
# @see http://aws.amazon.com/iam/ AWS Identity and Access Management (IAM)
module Iam
  # CloudFormation resource that represents an IAM instance profile.
  #
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-instanceprofile.html AWS::IAM::InstanceProfile
  class InstanceProfile < CloudFormation::Resource
    cf_type 'AWS::IAM::InstanceProfile'
    attr_accessor :path
    array_attr_accessor :roles

    def roles=(value)
      @roles = value.collect { |v| v.is_a?(String) ? FN.ref(v) : v }
    end

    def role(value)
      roles.push(value)
    end

    private

    def build_resource_properties(issues)
      if self.roles.nil? || self.roles.length != 1
        # TODO issue
      end

      if self.path.nil?
        # TODO issue
      end

      {
          'Path' => build_resource_value(self.path, issues),
          'Roles' => build_resource_value(self.roles, issues)
      }.delete_if { |k, v| v.nil? }
    end
  end

  # Add a named AWS::IAM::InstanceProfile resource.
  #
  # @example
  #     iam_instance_profile 'myInstanceProfile' do
  #       path '/'
  #       roles 'RootRole'
  #     end
  #
  # @see Iam::InstanceProfile
  # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-instanceprofile.html AWS::IAM::InstanceProfile
  def iam_instance_profile(name, options={}, &block)
    resource = InstanceProfile.new
    resource.evaluate &block
    add_resource name, resource
  end
end
