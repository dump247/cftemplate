require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'String',
            'AllowedValues' => []

  parameter 'P2', 'String',
            'AllowedValues' => ['a']

  parameter 'P3', 'String',
            :default => 'b',
            'AllowedValues' => ['a', 'b']

  parameter 'P4', 'String',
            :values => []

  parameter 'P5', 'String',
            :default => 'a',
            :values => ['a']

  parameter 'P6', 'String',
            :values => ['a', 'b']


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
