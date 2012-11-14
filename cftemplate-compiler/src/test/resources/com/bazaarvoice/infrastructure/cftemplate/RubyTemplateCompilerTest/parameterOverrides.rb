require 'cftemplate'

template '2010-09-09' do
  parameter 'NullValue', 'String', :default => 'XYZ'
  parameter 'Param1', 'String', :default => 'ABC'
  parameter 'Param2', 'String'
  parameter 'Param3', 'String', :default => 'DEF'

  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
