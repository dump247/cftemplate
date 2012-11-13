require 'cftemplate'

template '2010-09-09' do
  resource 'Resource1', 'AWS::IAM::InstanceProfile' do
    properties 'Path' => '/',
               'Roles' => [ref('InstanceRole')]
  end

  resource 'ResourceWith', 'AWS::IAM::InstanceProfile' do
    properties 'Path' => '/',
               'Roles' => [ref('InstanceRole')]
    metadata 'A' => 'B'
    deletion_policy :retain
    depends_on 'Resource1'
  end
end
