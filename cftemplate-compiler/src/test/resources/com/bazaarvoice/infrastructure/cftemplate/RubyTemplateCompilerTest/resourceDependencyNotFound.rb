template '2010-09-09' do
  resource 'Resource1', 'AWS::CloudFormation::WaitConditionHandle' do
    depends_on 'Resource3'
  end
end
