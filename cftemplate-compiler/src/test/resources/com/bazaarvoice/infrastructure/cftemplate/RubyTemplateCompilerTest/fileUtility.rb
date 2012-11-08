require 'cftemplate'

template '2010-09-09' do
  output 'EmptyFile', file('fileUtility_empty.txt')
  output 'NoVariables', file('fileUtility_novars.txt')
  output 'WithVariables', file('fileUtility_withvars.txt')
  output 'NoInterpolation', file('fileUtility_withvars.txt', false)


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end