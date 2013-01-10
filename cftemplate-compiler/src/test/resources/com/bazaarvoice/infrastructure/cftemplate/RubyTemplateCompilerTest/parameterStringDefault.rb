# Max 32 parameters

template '2010-09-09' do
  parameter 'P5', 'String' do
    default true
  end

  parameter 'P6', 'String' do
    default 18
  end

  parameter 'P7', 'String' do
    default ''
  end

  parameter 'P8', 'String' do
    length 3
    default 'str'
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
