class RemovePasswordDigestFromUsers < ActiveRecord::Migration[7.1]
  # Devise stores password hashes in `encrypted_password`, so the `password_digest`
  # column used by has_secure_password is no longer needed. Accounts created before
  # the switch have no `encrypted_password` and must reset their password.
  def change
    remove_column :users, :password_digest, :string
  end
end
