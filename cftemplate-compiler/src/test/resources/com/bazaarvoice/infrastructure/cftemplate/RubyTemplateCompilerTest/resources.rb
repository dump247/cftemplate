require 'cftemplate'

template '2010-09-09' do
  resource 'Resource1', 'AWS::IAM::InstanceProfile',
           'Properties' => {
               'Path' => '/',
               'Roles' => [ref('InstanceRole')]
           }

  resource 'ResourceWith', 'AWS::IAM::InstanceProfile',
           'Properties' => {
               'Path' => '/',
               'Roles' => [ref('InstanceRole')]
           },
           'Metadata' => {
               'A' => 'B'
           },
           'DeletionPolicy' => 'Retain',
           'DependsOn' => 'Resource1'
end
