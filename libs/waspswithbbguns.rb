require './wasps.rb'

smiley = Wasp.new('.waspsnest.json','eu-west-1','ami-75dbc301',{ Name: 'grinder.worker' }, 't1.micro','~/.ssh/id_rsa','AWS','~/.ssh/id_rsa.pub','ec2-user',['grinder-pool'])


smiley.create_colony(2)
smiley.display_swarm
smiley.smoke
smiley.display_swarm
