#!/usr/bin/env ruby

require 'rubygems'
require 'nagios-probe'

class TimezoneProbe < Nagios::Probe

  def check_crit
    t = Time.new # will create a time object defaulting to /now/
    !(t.zone == "UTC") # we're truly critical if we're not utc
  end

  def check_warn
    false # never warn
  end

  def crit_message
    t = Time.new
    "Timezone does not match UTC. Timezone is #{t.zone}"
  end

  def warn_message
    "This should never happen"
  end

  def ok_message
    "Timezone is UTC"
  end

end

begin
  options = {}
  probe = TimezoneProbe.new(options)
  probe.run
rescue Exception => e
  puts "Unknown: Encountered Ruby Exception: " + e
  exit Nagios::UNKNOWN
end

puts probe.message
exit probe.retval
