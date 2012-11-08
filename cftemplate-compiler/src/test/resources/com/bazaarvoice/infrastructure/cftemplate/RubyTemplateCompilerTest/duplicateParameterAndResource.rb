require 'cftemplate'

template '2010-09-09' do
  parameter 'dummy', 'String'
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
