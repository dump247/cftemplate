require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'String',
            'MinLength' => 10

  parameter 'P2', 'String',
            'MinLength' => "10"

  parameter 'P3', 'String',
            'MaxLength' => 10

  parameter 'P4', 'String',
            'MaxLength' => "10"

  parameter 'P5', 'String',
            'MinLength' => 0, 'MaxLength' => 2147483647

  parameter 'P6', 'String',
            'MinLength' => 10, 'MaxLength' => 10

  parameter 'P7', 'String',
            :length => 100

  parameter 'P8', 'String',
            :length => 10..100

  parameter 'P9', 'String',
            :length => 10...100


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
