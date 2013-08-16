#!/usr/bin/env ruby
#
# Todo
# - Parameterize command
# - Check for aws creds
#
require 'rubygems'
require 'fog'
require 'json'
require 'optparse'


# Fog.mock!

$number_of_wasps = 2
$wasps_nest_file = '.waspsnest.json'
$aws_region = 'eu-west-1'
$image_id = 'ami-75dbc301'
$wasp_tag = { Name: 'grinder.worker' }
$wasp_species =  't1.micro'
$wasp_private_key_path = '~/.ssh/id_rsa'
$wasp_public_key_path = '~/.ssh/id_rsa.pub'
$wasp_username = 'ec2-user'
$wasp_security_group = ['grinder-pool']

options = {}

$connection = Fog::Compute.new(
    {
        :provider              => 'AWS',
        :region                => $aws_region
    }
)

def rebuild_wasp_nest
  File.open($wasps_nest_file,'w') do |file|
    file.puts [].to_json
  end
end

def breed_wasp

  server = $connection.servers.bootstrap(
      :tags             => $wasp_tag,
      :image_id         => $image_id,
      :flavor_id        => $wasp_species,
      :private_key_path => $wasp_private_key_path,
      :public_key_path  => $wasp_public_key_path,
      :username         => $wasp_username,
      :security_groups  => $wasp_security_group
  )
  server.wait_for { ready? }
  server.reload
  return server.id
end


def smoke_wasps
  return if !File.exist?($wasps_nest_file)
  data = JSON.parse(File.read($wasps_nest_file))
  data.each do |wasp|
    puts wasp + " smoked."
    $connection.terminate_instances(wasp)
  end
  rebuild_wasp_nest
end

def create_colony(number_of_wasps)
  threads = []
  rebuild_wasp_nest if !File.exist?($wasps_nest_file)
  nest = JSON.parse(File.read($wasps_nest_file))

  number_of_wasps.times{
    threads << Thread.new() do
      nest << breed_wasp
    end
  }
  threads.each { |thr| thr.join }
  puts nest.to_json

  File.open($wasps_nest_file,'w') do |file|
    file.puts nest.to_json
  end
end

#create_colony($number_of_wasps)
#sleep(10)
#puts "Smoking wasps"
#smoke_wasps

opts = OptionParser.new
opts.on("--up") { create_colony($number_of_wasps) }
opts.on("--down") { smoke_wasps }
opts.parse!
