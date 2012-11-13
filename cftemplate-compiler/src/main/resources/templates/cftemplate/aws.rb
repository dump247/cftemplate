# Pseudo-parameters that are predefined by AWS CloudFormation.
# @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html Pseudo Parameters Reference
module Aws
  # Returns the list of notification Amazon Resource Names (ARNs) for the current stack.
  NOTIFICATION_ARNS='AWS::NotificationARNs'

  # Returns a string representing the AWS Region in which the encompassing resource is being created.
  REGION='AWS::Region'

  # Returns the name of the stack as specified with the cfn-create-stack command.
  STACK_NAME='AWS::StackName'

  # Returns the ID of the stack as specified with the cfn-create-stack command.
  STACK_ID='AWS::StackId'
end
