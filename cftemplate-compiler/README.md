# Introduction

Supports compiling and verifying AWS CloudFormation templates written in
CloudFormation JSON or CloudFormation Ruby DSL.

The Ruby DSL provides a simpler syntax as an alternative to
CloudFormation JSON and is the recommended method for writing new
templates. The compiler uses JRuby so it does not depend on Ruby being
installed.

When compiling JSON, the compiler will correct some basic issues (such
as quoting numbers/booleans) and will run a series of validations on the
template itself. This can be used with existing CloudFormation
templates.

# DSL

The DSL is a simpler syntax written in Ruby that will generate a
CloudFormation JSON document.

## Template

A template is declared with the template function block and the target
CloudFormation syntax verison. CloudFormation resources are then
declared within the `do..end` block. This same syntax is used
extensively for declaring resources in the template.

```ruby
template '2010-09-09' do
  # Declare CloudFormation resources, parameters, outputs, mappings
end
```

### Description

```ruby
template '2010-09-09' do
  description 'Description of the template'
end
```

## Mappings

```ruby
template '2010-09-09' do
  mapping 'Mapping1' => {
            'Map1' => {'A' => 'B'},
            'Map2' => {
              'A' => 'C',
              'D' => 'E'
            }
          }

  mappings 'Mapping2' => {
             'Map1' => {'A' => 'B'},
           },
           'Mapping3' => {
             'Map1' => {'A' => 'B'}
           }
end
```

## Parameters

```ruby
template '2010-09-09' do
  parameter 'Parameter1', :String # No addtional options

  parameter 'Parameter2', :Number do
    description 'A description'
  end
end
```

### String

```ruby
template '2010-09-09' do
  parameter 'Parameter', :String do
    description 'A description'
    echo false
    default 'The Default'

    constraint 'Description of the constraints'
    length 1      # Length must be exactly 1 character
    length 1..10  # Length must be between 1 and 9 characters, inclusive
    length 1...10 # Length must be between 1 and 10 characters, inclusive
    pattern '\d+'

    values 'a', 'b', 'c' # The parameter value must be one of the given values
    values 'd', 'e'      # Overwrites the previous list of values; values are now 'd', 'e'
    values ['f', 'g']    # Can also pass a list; values are now 'f', 'g'
  end
end
```

### Number

The type can be :Number, :Float, or :Integer.

```ruby
template '2010-09-09' do
  parameter 'Parameter', :Number do
    description 'A description'
    echo false
    default 7

    constraint 'Description of the constraints'
    min 3
    max 90
    range 3..90  # Value must be between 3 and 89, inclusive
    range 3...90 # Value must be between 3 and 90, inclusive

    values 1, 2, 3   # The parameter value must be one of the given values
    values 4, 5      # Overwrites the previous list of values; values are now 4, 5
    values [6, 7]    # Can also pass a list; values are now 6, 7
  end
end
```

### CommaDelimitedList

The type can be :CommaDelimitedList or :List.

```ruby
template '2010-09-09' do
  parameter 'Parameter', :List do
    description 'A description'
    echo false
    default 'A', 'B'
    default ['C', 'D'] # Can also pass a list; default is now 'C', 'D'
  end
end
```

## Outputs

```ruby
template '2010-09-09' do
  output 'OutputName' => 'OutputValue'

  outputs 'Output1' => 'Output1Value',
          'Output2' => 'Output2Value',
          'Output3' => 'Output3Value'

  output 'OutputName' do
    description 'Description of the output'
    value 'OutputValue'
  end
end
```

## Intrinsic Functions

### Ref

ref(resourceName)

```ruby
template '2010-09-09' do
  output 'OutputName' => ref('ResourceName')
end
```

### Base64

base64(content)

```ruby
template '2010-09-09' do
  output 'OutputName' => base64(ref('ResourceName'))
end
```

### FindInMap

find_in_map(mapName, key, value)

```ruby
template '2010-09-09' do
  output 'OutputName' => find_in_map('MapName', 'MapKey', 'MapValue')
end
```

### GetAtt

get_att(resourceName, attributeName)

```ruby
template '2010-09-09' do
  output 'OutputName' => get_att('ResourceName', 'AttributeName')
end
```

### GetAZs

get_azs([regionName])

```ruby
template '2010-09-09' do
  output 'OutputName' => get_azs('us-east-1')

  output 'OutputName' => get_azs() # Get availability zones for current region
end
```

### Join

join(delimiter, *values)

```ruby
template '2010-09-09' do
  output 'OutputName' => join('.', ref('ResourceName'), 'us-east-1')

  output 'OutputName' => join('.', [ ref('ResourceName'), 'us-east-1' ]) # Can also pass a list
end
```

### Select

select(index, *list)

```ruby
template '2010-09-09' do
  output 'OutputName' => select(1, "apples", "grapes", "oranges", "mangoes")

  output 'OutputName' => select(1, [ "apples", "grapes", "oranges", "mangoes" ]) # Can also pass as a list
end
```

## Helper Functions

### file

Load the contents of a file. Template values can be injected into the
file using double curly braces.

Useful when passing data to the UserData of an EC2 instance.

file(path, options)
* option :interpolate [Boolean] True to inject template content between
         double curly braces, false to load the file without interpreting curly
         braces. Default is true.

```ruby
template '2010-09-09' do
  resource 'LaunchConfig', 'AWS::AutoScaling::LaunchConfiguration' do
    property 'UserData' => base64(file('init.sh'))
  end

  output 'OutputName' => file('other.txt', :interpolate => false) # Do not do variable substitution
end
```

init.sh
```bash
#!/bin/bash

SOME_VAR="{{ref('SomeVar')}}"

echo $SOME_VAR
```

other.txt
```
This is some text {{with braces}}
Yay!
```

The resulting template JSON will be something like this:

```json
{
  "AWSTemplateFormatVersion" : "2010-09-09",
  "Resources" : {
    "Resource1" : {
      "Type" : "AWS::AutoScaling::LaunchConfiguration",
      "Properties" : {
        "UserData" : { "Base64" : { "Join" : [ "", [ "#!/bin/bash\n\nSOME_VAR=\"", { "Ref" : "SomeVar" }, "\"\n\necho $SOME_VAR\n" ] ] } }
      }
    }
  },
  "Outputs" : {
    "OutputName" : { "Value" : "This is some text {{with braces}}\nYay!" }
  }
}
```

