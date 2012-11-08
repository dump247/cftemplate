require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'CommaDelimitedList',
            'Default' => ''

  parameter 'P2', 'CommaDelimitedList',
            'Default' => 'a'

  parameter 'P3', 'CommaDelimitedList',
            'Default' => 'a,b'

  parameter 'P4', 'CommaDelimitedList',
            'Default' => '    a,    b   '

  parameter 'P5', 'CommaDelimitedList',
            'Default' => []

  parameter 'P6', 'CommaDelimitedList',
            'Default' => ['a']

  parameter 'P7', 'CommaDelimitedList',
            'Default' => ['a', 'b']

  parameter 'P8', 'CommaDelimitedList',
            :default => ''

  parameter 'P9', 'CommaDelimitedList',
            :default => 'a'

  parameter 'P10', 'CommaDelimitedList',
            :default => 'a,b'

  parameter 'P11', 'CommaDelimitedList',
            :default => '    a,    b   '

  parameter 'P12', 'CommaDelimitedList',
            :default => []

  parameter 'P13', 'CommaDelimitedList',
            :default => ['a']

  parameter 'P14', 'CommaDelimitedList',
            :default => ['a', 'b']


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
