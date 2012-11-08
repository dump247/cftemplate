require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'String',
            'Default' => true

  parameter 'P2', 'String',
            'Default' => 18

  parameter 'P3', 'String',
            'Default' => ''

  parameter 'P4', 'String',
            'Default' => 'str'

  parameter 'P5', 'String',
            :default => true

  parameter 'P6', 'String',
            :default => 18

  parameter 'P7', 'String',
            :default => ''

  parameter 'P8', 'String',
            :length => 3,
            :default => 'str'


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
