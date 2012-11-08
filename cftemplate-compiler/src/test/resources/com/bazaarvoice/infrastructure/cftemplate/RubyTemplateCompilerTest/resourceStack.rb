require 'cftemplate'

template '2010-09-09' do
  stack 'myStack', 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template'

  stack 'myStack2', 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template',
        :timeout => 5,
        :parameters => {'InstanceType' => 't1.micro', 'KeyName' => 'mykey'},
        :depends => 'myStack'

  stack 'myStack3', 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template',
        :timeout => 5941.minutes
end