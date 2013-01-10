# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'Number' do
    min 10
  end

  parameter 'P3', 'Number' do
    max -10
  end

  parameter 'P5', 'Number' do
    min 0
    max 2147483647
  end

  parameter 'P6', 'Number' do
    min -10
    max 10
  end

  parameter 'P7', 'Number' do
    range 10..100
  end

  parameter 'P8', :Integer do
    range -10...100
  end

  parameter 'P9', :Float do
    min 1.0
  end

  parameter 'P11', 'Number' do
    max -10.0
  end

  parameter 'P13', 'Number' do
    default 900
    min 0.0
    max 900
  end

  parameter 'P14', 'Number' do
    default -10
    min -10
    max 10
  end


# At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
