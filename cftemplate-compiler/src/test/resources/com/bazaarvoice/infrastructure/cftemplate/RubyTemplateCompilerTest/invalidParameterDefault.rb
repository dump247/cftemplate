require 'cftemplate'

template '2010-09-09' do
  parameter 'P1', 'Number',
            :default => 'a'

  parameter 'P2', 'Number',
            :default => true

  parameter 'P3', 'Number',
            :default => 2147483648

  parameter 'P4', 'CommaDelimitedList',
            :default => ['a,b']

  parameter 'P5', 'String',
            :length => 1..5,
            :default => ''

  parameter 'P6', 'String',
            :length => 1..5,
            :default => 'abcdef'


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
