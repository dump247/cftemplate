require 'cftemplate'

template '2010-09-09' do
  resource 'Resource1' do
    type 'AWS::CloudFormation::WaitConditionHandle'
    depends_on 'Resource3'
  end

  resource 'Resource2', 'AWS::CloudFormation::WaitConditionHandle' do
    depends_on 'Resource1'
  end

  resource 'Resource3' do
    type 'AWS::CloudFormation::WaitConditionHandle'
    depends_on 'Resource2'
  end
end
