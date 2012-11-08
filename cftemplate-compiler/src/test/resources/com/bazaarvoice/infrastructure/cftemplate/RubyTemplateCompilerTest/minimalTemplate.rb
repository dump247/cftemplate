require 'cftemplate'

template '2010-09-09' do


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
