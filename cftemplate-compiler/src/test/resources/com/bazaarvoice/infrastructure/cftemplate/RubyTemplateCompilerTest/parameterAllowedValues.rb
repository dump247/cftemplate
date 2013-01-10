# Max 32 parameters

template '2010-09-09' do
  parameter 'P4', 'String' do
    values []
  end

  parameter 'P5', 'String' do
    default 'a'
    values ['a']
  end

  parameter 'P6', 'String' do
    values ['a', 'b']
  end

  parameter 'P7', :Number do
    values [1, 2]
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
