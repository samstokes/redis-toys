#!/usr/bin/env ruby

require 'rubygems'
require 'andand'
require 'redis'
require 'treetop'

parser = Treetop.load('monitor_log.treetop').new
opts = {}
opts[:port] = ARGV[0].to_i if ARGV[0]
redis = Redis.new(opts)

executed = 0

errors = []
def errors.<<(item)
  if length < 100
    super
  elsif @overflow
    @overflow += 1
  else
    puts "More than 100 errors!"
    @overflow = length
  end
end
def errors.output!
  puts "#@overflow errors, only showing first 100" if @overflow
  each do |index, line, command, error|
    puts "At line #{index}: #{line}"
    puts "\tCommand: #{command.bits.inspect}"
    puts "\tError: #{error}"
  end
end

stop = false
trap(:INT) { stop = true }

begin
  STDIN.each_with_index do |line, i|
    raise 'Told to stop!' if stop
    parser.parse(line.strip).andand do |parsed_line|
      command = parsed_line.command
      begin
        command.execute(redis) unless command.name.upcase == 'MONITOR'
      rescue => e
        errors << [i, line, command, e]
      end
      executed += 1
    end or puts parser.failure_reason

    if i % 1000 == 999
      puts "Executed #{executed} out of #{i + 1} lines"
    end
  end
rescue => e
  p e
end

puts 'Errors: ' if errors.any?
errors.output!

puts
puts "Executed: #{executed}\tErrors: #{errors.length}"

exit 1 if errors.any?
