# redis-toys #

## monitor_replay.rb ##

The format in which `redis-cli monitor` outputs commands is not suitable for
replaying straight back into `redis-cli`, as it includes metadata such as
timestamps.  This parses the format and then replays the commands (using the
`redis-rb` gem).
