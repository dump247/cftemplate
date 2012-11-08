require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'Number',
            'Default' => 1

  parameter 'P2', 'Number',
            'Default' => -1

  parameter 'P3', 'Number',
            'Default' => 0

  parameter 'P4', 'Number',
            'Default' => 2147483647

  parameter 'P5', 'Number',
            'Default' => "1"

  parameter 'P6', 'Number',
            'Default' => "-1"

  parameter 'P7', 'Number',
            'Default' => "0"

  parameter 'P8', 'Number',
            'Default' => "2147483647"

  parameter 'P9', 'Number',
            'Default' => 1.0

  parameter 'P10', 'Number',
            'Default' => -1.0

  parameter 'P11', 'Number',
            'Default' => 0.0

  parameter 'P12', 'Number',
            'Default' => "1.0"

  parameter 'P13', 'Number',
            'Default' => "-1.0"

  parameter 'P14', 'Number',
            'Default' => "0.0"

  parameter 'P15', 'Number',
            :default => 1

  parameter 'P16', 'Number',
            :default => -1

  parameter 'P17', 'Number',
            :default => 0

  parameter 'P18', 'Number',
            :default => 2147483647

  parameter 'P19', 'Number',
            :default => "1"

  parameter 'P20', 'Number',
            :default => "-1"

  parameter 'P21', 'Number',
            :default => "0"

  parameter 'P22', 'Number',
            :default => "2147483647"

  parameter 'P23', 'Number',
            :default => 1.0

  parameter 'P24', 'Number',
            :default => -1.0

  parameter 'P25', 'Number',
            :default => 0.0

  parameter 'P26', 'Number',
            :default => "1.0"

  parameter 'P27', 'Number',
            :default => "-1.0"

  parameter 'P28', 'Number',
            :default => "0.0"


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
