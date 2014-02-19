require 'digest'
class UsersController < ResourceController::Base

  layout false

  def update
    if current_user.valid_password?(params[:user][:current_password])
      if params[:user][:password].empty?
        render :update do |page|
          page << "Ext.MessageBox.alert('Update password', 'Password is empty');";
        end
        return
      end

      prev_password = params[:user][:current_password]
      params[:user].delete(:current_password)

      render :update do |page|
        if current_user.update_attributes(params[:user])
          current_user.reload
          Rails.logger.warn 'Syncing admin passwords'
          SyncAdminPasswords.sync({:prev_password => Digest::MD5.hexdigest(prev_password), :password => Digest::MD5.hexdigest(params[:user][:password]) })

          page << "editUserPassword.hide()"
        else
          page << "Ext.MessageBox.alert('Update password', 'Passwords do not match');"
        end
      end
    else
      render :update do |page|
        page << "Ext.MessageBox.alert('Update password', 'Wrong current password');"
      end
    end
  end
end
