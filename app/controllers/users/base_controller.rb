class Users::BaseController < ApplicationController
  before_action :authenticate_user!
  layout "application"
  helper_method :user_shard

  private

  def user_shard
    Switch.with_master(Switch.master_shard) do
      LookupUser.find_by(id: current_user.id).shard
    end
  end
end
