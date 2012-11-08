require 'cftemplate'

# Max 32 parameters

template '2010-09-09' do
  parameter 'P1', 'String',
            'NoEcho' => true

  parameter 'P2', 'String',
            'NoEcho' => "TRUE"

  parameter 'P3', 'String',
            'NoEcho' => false

  parameter 'P4', 'String',
            'NoEcho' => "FALSE"

  parameter 'P5', 'String',
            :echo => true

  parameter 'P6', 'String',
            :echo => false


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
