template '2010-09-09' do
  description 'This is the description'

  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
