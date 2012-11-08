require 'cftemplate'

template '2010-09-09' do
  resource 'Dummy', 'AWS::CloudFormation::Stack',
           'Properties' => {
               'TemplateURL' => 'http://localhost/no.template'
           }

  wait_condition_handle 'C6Handle'

  wait_condition 'C0'
  wait_condition 'C1', :timeout => 10
  wait_condition 'C2', :count => 5
  wait_condition 'C3', :handle => 'C2Handle'
  wait_condition 'C4', :depends => 'Dummy'
  wait_condition 'C5', :timeout => Timespan.new(:hours => 3, :minutes => 7), :count => 2, :depends => 'Dummy', :handle => ref('C2Handle')
  wait_condition 'C6'
end