require 'cftemplate'

template do


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
