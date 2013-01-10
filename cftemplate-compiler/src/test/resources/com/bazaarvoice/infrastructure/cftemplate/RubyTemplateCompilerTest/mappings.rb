# Max 32 parameters

template '2010-09-09' do
  mapping 'MappingA' => {
              'Map1' => {
                  'Key1' => 'Value1'
              },
              'Map2' => {
                  'Key1' => 'Value2',
                  'Key2' => ['A', 'B', 'c']
              }
          }

  mapping 'Mapping1' => {
              'MapA' => {
                  'KeyA' => 'ValueA'
              }
          },
          'Mapping2' => {
              'MapA' => {
                  'KeyB' => 7
              }
          }

  mappings 'Mapping3' => {
               'MapA' => {
                   'KeyA' => 'ValueA'
               }
           },
           'Mapping4' => {
               'MapA' => {
                   'KeyB' => 7
               }
           }

  # At least one resource is required
  resource 'Dummy', 'AWS::CloudFormation::WaitConditionHandle'
end
