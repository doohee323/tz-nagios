#!/usr/bin/env ruby
require 'rubygems'
require 'redis'
require 'nagios'

module CheckLastRedisRuntime

class Config < Nagios::Config

  def initialize
    super
    #defaults
    @settings[:host] = '127.0.0.1'
    @settings[:port] = 6379
    @settings[:database] = 2
    
    @options.on("-h",
                "--host [HOST]", String,
                "The redis host where the redis rules wrapper deposits it's data, default: 127.0.0.1") do |x|
      @settings[:host] = x
    end
    @options.on("-p",
                "--port [PORT]", Integer,
                "The redis port where the redis rules wrapper deposits it's data, default: 6379") do |x|
      @settings[:port] = x
    end
    @options.on("-d",
                "--database [DATABASE]", Integer,
                "The redis database number in which the status key is located, default: 2") do |x|
      @settings[:database] = x
    end
    @options.on("-k",
                "--key KEY", String,
                "The key which contains a string representing the time at which the tool last ran in unix epoch time") do |x|
      @settings[:key] = x
    end
  end

end

class Runner < Nagios::Plugin

  def initialize
    super
    @config = Config.new
  end

  def critical(result)
    result && result > @config[:critical]
  end

  def critical_msg(result)
    if result
      "Tool has not run for #{result} seconds"
    else
      "Could not find last run time"
    end
  end

  def warning(result)
    result > @config[:warning]
  end

  def warning_msg(result)
    "Tool has not run for #{result} seconds"
  end

  def ok_msg(result)
    "Tool ran #{result} seconds ago"
  end

  def measure
    redis = Redis.new(:host => @config[:host], :port => @config[:port], :db => @config[:database])
    data = redis.get(@config[:key])
    if data && data.to_i > 0 # should never be the 70's again, and to_i returns 0 if the string is not convertable to integer. Anyway, this needs attention if this happens
      return Time.now.strftime('%s').to_i - data.to_i
    else
      return false
    end
  end
end

end

CheckLastRedisRuntime::Runner.new.run!

