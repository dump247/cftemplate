template '2010-09-09' do
  parameter 'P1', 'Number' do
    default 'a'
  end

  parameter 'P2', 'Number' do
    default true
  end

  parameter 'P3', 'Number' do
    default 2147483648
  end

  parameter 'P4', 'CommaDelimitedList' do
    default ['a,b']
  end

  parameter 'P5', 'String' do
    length 1..5
    default ''
  end

  parameter 'P6', 'String' do
    length 1..5
    default 'abcdef'
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
