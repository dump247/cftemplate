# Max 32 parameters

template '2010-09-09' do
  parameter 'P8', :List do
    default ''
  end

  parameter 'P9', :List do
    default 'a'
  end

  parameter 'P12', :List do
    default []
  end

  parameter 'P13', :List do
    default ['a']
  end

  parameter 'P14', :List do
    default ['a', 'b']
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
