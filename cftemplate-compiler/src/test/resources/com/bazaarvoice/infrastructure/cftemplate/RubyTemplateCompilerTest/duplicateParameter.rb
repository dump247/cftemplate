require 'cftemplate'

template '2010-09-09' do
  parameter 'TheParameter', 'String'
  parameter 'TheParameter', 'String'

  parameter 'OtherParameter', 'Number'
  parameter 'otherParameter', 'Number'


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
