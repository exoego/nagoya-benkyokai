# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  connpass_id :string
#  twitter_id  :string
#  facebook_id :string
#  github_id   :string
#  linkedin_id :string
#  name        :string
#  image_url   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  atnd_id     :integer
#

class User < ApplicationRecord
  has_many :participants
  has_many :events, through: :participants

  class << self
    def find_connpass(connpass_id, twitter_id = nil, facebook_id = nil, github_id = nil)
      user = User.find_by(connpass_id: connpass_id)
      return user if user
      find_social(twitter_id, facebook_id, github_id)
    end

    def find_atnd(atnd_id, twitter_id = nil, facebook_id = nil)
      user = User.find_by(atnd_id: atnd_id)
      return user if user
      find_social(twitter_id, facebook_id)
    end

    def find_doorkeeper(twitter_id = nil, facebook_id = nil, github_id = nil, linkedin_id = nil, name = nil)
      user = find_social(twitter_id, facebook_id, github_id, linkedin_id)
      return user if user
      User.find_by(name: name)
    end

    def find_social(twitter_id = nil, facebook_id = nil, github_id = nil, linkedin_id = nil)
      if twitter_id.present?
        user = User.find_by(twitter_id: twitter_id)
        return user if user
      end

      if facebook_id.present?
        user = User.find_by(facebook_id: facebook_id)
        return user if user
      end

      if github_id.present?
        user = User.find_by(github_id: github_id)
        return user if user
      end

      if linkedin_id.present?
        user = User.find_by(linkedin_id: linkedin_id)
        return user if user
      end
    end
  end
end
