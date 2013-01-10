template '2010-09-09' do
  # Plural 'roles'
  iam_instance_profile 'Profile1' do
    path '/'
    roles 'Role1'
  end

  # Singular 'role'
  iam_instance_profile 'Profile2' do
    path '/'
    role 'Role1'
  end
end
