require 'cftemplate'

template '2010-09-09' do
  stack 'myStack' do
    url 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template'
  end

  stack 'myStack2' do
    url 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template'
    timeout_in_minutes 5.minutes
    parameters 'InstanceType' => 't1.micro', 'KeyName' => 'mykey'
    depends_on 'myStack'
  end

  stack 'myStack3' do
    url 'https://s3.amazonaws.com/cloudformation-templates-us-east-1/S3_Bucket.template'
    timeout 5941.minutes
  end
end