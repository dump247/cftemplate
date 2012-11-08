require 'cftemplate'

template '2010-09-09' do
  resource 'Resource1', 'AWS::CloudFormation::WaitConditionHandle',
           'DependsOn' => 'Resource3'
end
