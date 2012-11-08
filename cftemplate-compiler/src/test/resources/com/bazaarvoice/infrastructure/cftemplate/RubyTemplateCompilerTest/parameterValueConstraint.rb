require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'Number',
            'MinValue' => 10

  parameter 'P2', 'Number',
            'MinValue' => "10"

  parameter 'P3', 'Number',
            'MaxValue' => -10

  parameter 'P4', 'Number',
            'MaxValue' => "-10"

  parameter 'P5', 'Number',
            'MinValue' => 0, 'MaxValue' => 2147483647

  parameter 'P6', 'Number',
            'MinValue' => -10, 'MaxValue' => 10

  parameter 'P7', 'Number',
            :range => 10..100

  parameter 'P8', 'Number',
            :range => -10...100

  parameter 'P9', 'Number',
            'MinValue' => 1.0

  parameter 'P10', 'Number',
            'MinValue' => "1.0"

  parameter 'P11', 'Number',
            'MaxValue' => -10.0

  parameter 'P12', 'Number',
            'MaxValue' => "-10.0"

  parameter 'P13', 'Number',
            :default => 900,
            'MinValue' => 0.0, 'MaxValue' => 900

  parameter 'P14', 'Number',
            :default => -10,
            'MinValue' => -10, 'MaxValue' => 10


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
