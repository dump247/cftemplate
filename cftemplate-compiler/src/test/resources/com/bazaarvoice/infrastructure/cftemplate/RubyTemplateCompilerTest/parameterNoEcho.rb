# Max 32 parameters

template '2010-09-09' do
  parameter 'P5', 'String' do
    echo true
  end

  parameter 'P6', 'String' do
    echo false
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
