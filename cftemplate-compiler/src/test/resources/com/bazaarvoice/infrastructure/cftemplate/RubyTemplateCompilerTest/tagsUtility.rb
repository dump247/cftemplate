template '2010-09-09' do
  output 'EmptyTags' => tags()
  output 'SingleTag' => tags('A' => 'B')
  output 'MultiTag' => tags('A' => 'B', 'C' => 'D')
  output 'Propagate' => tags({'A' => 'B', 'C' => 'D'}, :propagate => true)
  output 'DontPropagate' => tags({'A' => 'B', 'C' => 'D'}, :propagate => false)
  output 'PropagateTag' => tags('A' => 'B', 'C' => tag('D'), 'E' => tag('F', :propagate => true), 'G' => tag('H', :propagate => false))
  output 'TagsArray' => [tag('A', 'B'), tag('C', 'D', :propagate => true), tag('E', 'F', :propagate => false)]


  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end