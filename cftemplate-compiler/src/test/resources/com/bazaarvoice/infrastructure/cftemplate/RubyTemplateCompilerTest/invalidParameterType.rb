require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', ''
  parameter 'P2', 'string'
  parameter 'P3', 'num'


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
