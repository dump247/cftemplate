require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'String',
            'MinLength' => -10

  parameter 'P2', 'String',
            'MinLength' => 1.0

  parameter 'P3', 'Number',
            'MaxLength' => 10

  parameter 'P4', 'Number',
            'MinLength' => "10"

  parameter 'P5', 'Number',
            :length => 100

  parameter 'P6', 'Number',
            :length => 10..100

  parameter 'P7', 'CommaDelimitedList',
            'MaxLength' => 10

  parameter 'P8', 'CommaDelimitedList',
            'MinLength' => "10"

  parameter 'P9', 'CommaDelimitedList',
            :length => 100

  parameter 'P10', 'CommaDelimitedList',
            :length => 10..100


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
