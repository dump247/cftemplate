template '2010-09-09' do
  parameter 'TestList', :List

  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle' do
    properties 'A' => select(0, ref('TestList')),
               'B' => select(1, ['a', 'b'])
  end
end
