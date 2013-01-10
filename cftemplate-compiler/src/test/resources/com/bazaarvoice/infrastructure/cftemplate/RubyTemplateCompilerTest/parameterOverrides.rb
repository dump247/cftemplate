template '2010-09-09' do
  parameter 'NullValue', :String do
    default 'XYZ'
  end

  parameter 'Param1', 'String' do
    default 'ABC'
  end

  parameter 'Param2', 'String'

  parameter 'Param3', 'String' do
    default 'DEF'
  end

  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
