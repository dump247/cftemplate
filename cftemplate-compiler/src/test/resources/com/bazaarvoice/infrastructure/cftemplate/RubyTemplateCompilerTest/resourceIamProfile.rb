require 'cftemplate'

template '2010-09-09' do
  iam_instance_profile 'Profile1', '/', 'Role1'
end
