# Max 32 outputs

template '2010-09-09' do
  output 'Output1' => ref('OutputRef')
  output 'Output2' => 'OutputValue'

  output 'OutputA' do
    description 'Description for output a'
    value 'OutputValue'
  end

  output 'ArrayOutput' do
    value ['a', 'b']
  end

  outputs 'A' => 'B',
          'C' => 'D'

  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end