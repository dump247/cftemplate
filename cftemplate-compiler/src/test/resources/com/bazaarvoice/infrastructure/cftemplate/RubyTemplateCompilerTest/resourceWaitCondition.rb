template '2010-09-09' do
  resource 'Dummy', 'AWS::CloudFormation::Stack' do
    properties 'TemplateURL' => 'http://localhost/no.template'
  end

  wait_condition_handle 'C6Handle'

  wait_condition 'C0' do
    timeout 1800.seconds
  end

  wait_condition 'C1' do
    timeout 10.seconds
  end

  wait_condition 'C2' do
    timeout 100.milliseconds
    count 5
  end

  wait_condition 'C3' do
    timeout 1800
    handle 'C2Handle'
  end

  wait_condition 'C4' do
    timeout 1800.seconds
    depends_on 'Dummy'
  end
  
  wait_condition 'C5' do
    timeout Timespan.new(:hours => 3, :minutes => 7)
    count 2
    depends_on 'Dummy'
    handle ref('C2Handle')
  end

  wait_condition 'C6' do
    timeout 1800.seconds
  end
end