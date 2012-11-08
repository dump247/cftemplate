require 'cftemplate'

template '2010-09-09' do
  resource 'Resource1', 'AWS::CloudFormation::WaitConditionHandle',
           'DependsOn' => 'Resource3'
  resource 'Resource2', 'AWS::CloudFormation::WaitConditionHandle',
           'DependsOn' => 'Resource1'
  resource 'Resource3', 'AWS::CloudFormation::WaitConditionHandle',
           'DependsOn' => 'Resource2'
end
