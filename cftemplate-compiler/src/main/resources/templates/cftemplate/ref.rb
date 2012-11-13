require 'cftemplate/aws'
require 'cftemplate/fn'

# References to standard AWS CloudFormation parameters.
# @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html Pseudo Parameters Reference
module Ref
  # Generate a ref for AWS::NotificationARNs.
  #
  # @return [Hash] { "Ref" => "AWS::NotificationARNs" }
  def aws_notification_arns
    FN.ref(Aws::NOTIFICATION_ARNS)
  end

  module_function :aws_notification_arns

  # Generate a ref for AWS::Region.
  #
  # @return [Hash] { "Ref" => "AWS::Region" }
  def aws_region
    FN.ref(Aws::REGION)
  end

  module_function :aws_region

  # Generate a ref for AWS::StackId.
  #
  # @return [Hash] { "Ref" => "AWS::StackId" }
  def aws_stack_id
    FN.ref(Aws::STACK_ID)
  end

  module_function :aws_stack_id

  # Generate a ref for AWS::StackName.
  #
  # @return [Hash] { "Ref" => "AWS::StackName" }
  def aws_stack_name
    FN.ref(Aws::STACK_NAME)
  end

  module_function :aws_stack_name
end