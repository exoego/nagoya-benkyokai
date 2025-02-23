require 'twitter'

class TooManyListsError < StandardError;end
class Tweet140OverError < StandardError;end
class TwitterClient
  attr_reader :client
  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def lists(option = {})
    client.lists(option)
  rescue => e
    NotifyService.new.call(e, "TwitterCient.lists(option: #{option})")
    raise
  end

  def list_exists?(list_id)
    puts "list_exists?(#{list_id})"
    client.list(list_id)
    return true
  rescue Twitter::Error::NotFound
    return false
  rescue => e
    NotifyService.new.call(e, "TwitterCient.list_exists?(list_id: #{list_id})")
    raise
  end

  def mode
    @mode ||= begin
      debug_mode = ENV['TWITTER_DEBUG_MODE']
      if debug_mode == 'false'
        'public'
      else
        'private'
      end
    end
  end

  def create_list(title, description)
    title = create_list_name(title)
    description = create_list_desc(description)
    puts "create_list(title:#{title}, description:#{description})"
    client.create_list(title, description: description, mode: mode)
  rescue Twitter::Error::Forbidden => e
    puts "#{e}\ntitle:#{title} description:#{description}"
    raise TooManyListsError if e.message == 'The list failed validation: This user has too many lists.'
    NotifyService.new.call(e, "TwitterCient.create_list(title: #{title}, description: #{description})")
  rescue => e
    NotifyService.new.call(e, "TwitterCient.create_list(title: #{title}, description: #{description})")
    raise
  end

  def update_list(uri, title, description)
    list_name = create_list_name(title)
    description = create_list_desc(description)
    puts "update_list(uri:#{uri}, list_name:#{list_name}, description:#{description})"
    client.list_update(uri, name: list_name, description: description, mode: mode)
  rescue Twitter::Error::Forbidden => e
    puts "#{e}\nuri:#{uri} list_name:#{list_name} description:#{description}"
  rescue => e
    NotifyService.new.call(e, "TwitterCient.update_list(uri: #{uri}, title: #{title}, description: #{description})")
    raise
  end

  def destroy_list(event_id)
    puts "destroy_list(#{event_id})"
    client.destroy_list(event_id)
  rescue => e
    NotifyService.new.call(e, "TwitterCient.destroy_list(event_id: #{event_id})")
    raise
  end

  def add_list_member(list_id, user_id)
    puts "add_list_member(#{list_id}, #{user_id})"
    client.add_list_member(list_id, user_id)
  rescue Twitter::Error::Forbidden
    puts "Error: #{user_id}をリストに追加する権限がありません。"
  rescue => e
    NotifyService.new.call(e, "TwitterCient.add_list_member(list_id: #{list_id}, user_id: #{user_id})")
    raise
  end

  def add_list_members(list_id, users)
    return if users.empty?
    puts "add_list_members(#{list_id}, #{users})"
    client.add_list_members(list_id, users)
  rescue Twitter::Error::Forbidden
    puts "Error: #{users}をリストに追加する権限がありません。"
  rescue => e
    NotifyService.new.call(e, "TwitterCient.add_list_member(list_id: #{list_id}, user_id: #{users})")
    raise
  end

  def list(list_id)
    puts "list(#{list_id})"
    client.list(list_id)
  rescue => e
    NotifyService.new.call(e, "TwitterCient.list(list_id: #{list_id})")
    raise
  end

  def list_members(list_id)
    puts "list_members(#{list_id})"
    client.list_members(list_id)
  rescue => e
    NotifyService.new.call(e, "TwitterCient.list_members(list_id: #{list_id})")
    raise
  end

  def tweet(message)
    client.update(message)
  rescue => e
    raise Tweet140OverError if e.message == 'Status is over 140 characters.'
    NotifyService.new.call(e, "TwitterCient.tweet(message: #{message})")
    raise
  end

  private

  def check_list_name(title)
    return false if title.size > 25
    return false if title.bytesize > 55
    return false if title =~ (/\A[0-9]/)
    true
  end

  def trim(str)
    str.gsub(/\bin$/, '').gsub(/[・【「\[（(＠@～:：\. ]+$/, '').strip
  end

  def create_list_name(title)
    title.strip!
    title.gsub!(/twitter/i, 'ツイッター')
    title.gsub!(/[[:space:]]+/, ' ')
    title.gsub!(/[\/]+/, '/')
    title.gsub!(/[:]+/, '')
    if title =~ /^[0-9]/
      title = '-' + title
    end
    words = title.split(/\b/)
    name = ''
    words.each do |word|
      if check_list_name(name + word)
        name += word
      else
        break
      end
    end
    if name.length <= 3
      title[name.length..(title.length - name.length)].each_char do |char|
        if check_list_name(name + char)
          name += char
        else
          return trim(name)
        end
      end
    end
    trim(name)
  end

  def check_list_desc(desc)
    return false if desc.size > 100
    return false if desc.bytesize > 255
    true
  end

  def create_list_desc(desc)
    desc.gsub(/[[:space:]]+/, ' ')
    words = desc.split(/\b/)
    name = ''
    words.each do |word|
      if check_list_desc(name + word)
        name += word
      else
        break
      end
    end
    if name.empty?
      desc.each_char do |char|
        if check_list_desc(name + char)
          name += char
        else
          return name
        end
      end
    end
    name
  end
end
