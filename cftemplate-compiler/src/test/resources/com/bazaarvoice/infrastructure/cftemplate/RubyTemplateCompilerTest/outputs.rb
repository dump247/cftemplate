require 'cftemplate'

# Max 32 outputs

template '2010-09-09' do
  output 'Output1', ref('OutputRef')
  output 'Output2', 'OutputValue'
  output 'OutputA', 'OutputValue', 'Description for output a'
  output 'ArrayOutput', ['a', 'b']


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end