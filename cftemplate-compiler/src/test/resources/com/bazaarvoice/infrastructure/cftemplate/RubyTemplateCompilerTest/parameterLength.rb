# Max 32 parameters

template '2010-09-09' do
  parameter 'P7', 'String' do
    length 100
  end

  parameter 'P8', 'String' do
    length 10..100
  end

  parameter 'P9', 'String' do
    length 10...100
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
