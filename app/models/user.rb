class User < ActiveRecord::Base

  has_many :friends
  has_many :followings

  def import_twitter_friends
    Twitter.configure do |config|
      config.oauth_token = token
      config.oauth_token_secret = secret
    end
    Twitter.friends(twitter_handle).each do |buddy|
      self.friends << Friend.create(twitter_handle: buddy.screen_name)
      sleep(4)
    end
    self.save!
  end
  handle_asynchronously :import_twitter_friends

  def to_param
    twitter_handle
  end

  def is_following?(entity)
    !!self.followings.where(dbpedia_key: entity.url_key).first
  end

  def followings_as_entities
    self.followings.map do |following|
      ::Juicer.person_by_name(following.dbpedia_key)
    end
  end

  def admin?
    self.role == 'admin'
  end

  def xpedia_slug
    xpedia_slug || url_key
  end
end
