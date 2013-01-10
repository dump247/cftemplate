# Max 32 parameters

template '2010-09-09' do
  parameter 'P15', :Number do
    default 1
  end

  parameter 'P16', :Number do
    default -1
  end

  parameter 'P17', :Number do
    default 0
  end

  parameter 'P18', :Number do
    default 2147483647
  end

  parameter 'P19', :Number do
    default "1"
  end

  parameter 'P20', :Number do
    default "-1"
  end

  parameter 'P21', :Number do
    default "0"
  end

  parameter 'P22', :Number do
    default "2147483647"
  end

  parameter 'P23', :Number do
    default 1.0
  end

  parameter 'P24', :Number do
    default -1.0
  end

  parameter 'P25', :Number do
    default 0.0
  end

  parameter 'P26', :Number do
    default "1.0"
  end

  parameter 'P27', :Number do
    default "-1.0"
  end

  parameter 'P28', :Number do
    default "0.0"
  end


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
