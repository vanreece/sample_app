class Micropost < ActiveRecord::Base
  attr_accessible :content

  belongs_to :user

  validates :content, presence: true, length: { maximum: 140 }
  validates :user_id, presence: true

  default_scope order: 'microposts.created_at DESC'

  def self.from_users_followed_by(user)
    following_ids = user.following_ids
    #where("user_id IN (#{following_ids}) OR user_id = ?", user)
    where(user_id: user.following.push(user))
  end
end
