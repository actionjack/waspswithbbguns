require 'rubygems'
require 'fog'
require 'json'

class Wasp < Struct.new(:nest_file,
                        :provider_region,
                        :image_id,
                        :tag,
                        :species,
                        :private_key_path,
                        :provider,
                        :public_key_path,
                        :username,
                        :security_group)

  def connection
    @connection = Fog::Compute.new(
        {
            :provider => self.provider,
            :region => self.provider_region
        }
    )
  end

  def rebuild_nest(wasp_info)
    File.open(self.nest_file, 'w') do |file|
      file.puts wasp_info.to_json
    end
  end

  def clean_nest
    rebuild_nest([])
  end

  def query_swarm
    JSON.parse(File.read(self.nest_file))
  end

  def breed
    server = connection.servers.bootstrap(
        :tags => self.tag,
        :image_id => self.image_id,
        :flavor_id => self.species,
        :private_key_path => self.private_key_path,
        :public_key_path => self.public_key_path,
        :username => self.username,
        :security_groups => self.security_group
    )
    server.wait_for { ready? }
    server.reload
    server.id
  end

  def smoke
    return if !File.exist?(self.nest_file)
    query_swarm.each do |wasp|
      puts wasp + ' smoked.'
      connection.terminate_instances(wasp)
    end
    clean_nest
  end

  def display_swarm
    puts query_swarm.to_json
    puts "You currently have a swarm of #{query_swarm.size} wasps"
  end

  def create_colony(number_of_wasps)
    clean_nest if !File.exist?(self.nest_file)
    threads = []
    nest = query_swarm

    number_of_wasps.times {
      threads << Thread.new() do
        nest << self.breed
      end
    }
    threads.each { |thr| thr.join }

    rebuild_nest(nest)
  end
end
