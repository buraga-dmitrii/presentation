class User < ApplicationRecord
  attr_reader :shard

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :connections, dependent: :destroy

  around_create :create_on_shard
  before_create :generate_secrets
  after_create  :create_lookup_user
  after_destroy :destroy_lookup_user

  private

  def create_on_shard(&block)
    @shard = (DatabaseHandler.shards.keys - [LookupUser.last.try(:shard)]).sample
    DatabaseHandler.with_master(shard) do
      yield
    end
  end

  def generate_secrets
    self.app_id = SecureRandom.hex
    self.secret = SecureRandom.hex
  end

  def create_lookup_user
    DatabaseHandler.with_master(DatabaseHandler.master_shard) do
      LookupUser.create(id: id, email: email, app_id: app_id, secret: secret, shard: shard)
    end
  end

  def destroy_lookup_user
    DatabaseHandler.with_master(DatabaseHandler.master_shard) do
      LookupUser.where(id: id).delete_all
    end
  end
end
