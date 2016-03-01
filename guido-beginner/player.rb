## Level 1
# class Player
#  def play_turn(warrior)
#    warrior.walk!
#  end
# end

## Level 2
# class Player
#   def play_turn(warrior)
#     if warrior.feel.enemy?
#       warrior.attack!
#     else
#       warrior.walk!
#     end
#   end
# end

## Level 3
# class Player
# 	def play_turn(warrior)
# 		if warrior.feel.enemy?
#       warrior.attack!
#     elsif warrior.health < 10
#     	 warrior.rest!
#     else
#       warrior.walk!
#     end
#   end
# end

## Level 4
# class Player
#   @health = 20
# 	def play_turn(warrior)
#     puts '=================================='
#     puts "Turn Starts"
#   	puts "Previous health: #{@health}"
#    	puts "Current health: #{warrior.health}"

# 		taking_damage = false
# 		if(warrior.health < 19 and warrior.health < @health)
# 			taking_damage = true
# 		end

# 		if warrior.feel.enemy?
#       warrior.attack!
#     elsif warrior.health < 19 and !taking_damage
#     	warrior.rest!
#     else
#       warrior.walk!
#     end
#     @health = warrior.health
#   end
# end

## Level 5
# class Player
#   @health = 20
# 	def play_turn(warrior)
#     puts '=================================='
#     puts "Turn Starts"
#   	puts "Previous health: #{@health}"
#    	puts "Current health: #{warrior.health}"

# 		taking_damage = false
# 		if(warrior.health < 19 and warrior.health < @health)
# 			taking_damage = true
# 		end

# 		if warrior.feel.enemy?
#       warrior.attack!
#     elsif !taking_damage and warrior.health < 19 
#     	warrior.rest!
#    	elsif !taking_damage and warrior.feel.captive?
#     	warrior.rescue!
#     else
#       warrior.walk!
#     end
#     @health = warrior.health
#   end
# end

## Level 6
# class Player
# 	#attr_accessor :warrior
# 	Directions = [:forward, :left, :backward, :right]
	
# 	def initialize
#   	@health = 20
#   	@back_wall_reached = false
#   end

# 	def play_turn(warrior)
#     puts '=================================='
#     puts "Turn Starts"
#   	puts "Previous health: #{@health}"
#    	puts "Current health: #{warrior.health}"
#    	puts "Feel Enemy: #{warrior.feel.enemy?}"

# 		taking_damage = false
# 		if(warrior.health < 19 and warrior.health < @health)
# 			taking_damage = true
# 		end

# 		if warrior.feel.enemy?
#       warrior.attack!
#     elsif !taking_damage and warrior.health < 19 
#     	warrior.rest!
#    	elsif !taking_damage and check_captives warrior
#    		rescue_captive warrior
#    	elsif taking_damage and warrior.health < 9
#    		warrior.walk!:backward
#    	elsif !taking_damage and !warrior.feel(:backward).wall? and !@back_wall_reached
#    		warrior.walk!:backward
#     elsif !taking_damage and warrior.feel(:backward).wall? and !@back_wall_reached
#     	@back_wall_reached = true
#     else
#       warrior.walk!
#     end
#     @health = warrior.health
#   end
  
# ## Level 7
# class Player
# 	#attr_accessor :warrior
# 	Directions = [:forward, :left, :backward, :right]
	
# 	def initialize
#   	@health = 20
#   end

# 	def play_turn(warrior)
#     puts '=================================='
#     puts "Turn Starts"
#   	puts "Previous health: #{@health}"
#    	puts "Current health: #{warrior.health}"
#    	puts "Feel Enemy: #{warrior.feel.enemy?}"

# 		taking_damage = false
# 		if(warrior.health < 19 and warrior.health < @health)
# 			taking_damage = true
# 		end

# 		if warrior.feel.enemy?
#       warrior.attack!
#     elsif !taking_damage and warrior.health < 19 
#     	warrior.rest!
#    	elsif !taking_damage and check_captives warrior
#    		rescue_captive warrior
#    	elsif taking_damage and warrior.health < 9
#    		warrior.walk!:backward
#    	elsif !taking_damage and warrior.feel.wall?
#    		warrior.pivot!
#     else
#       warrior.walk!
#     end
#     @health = warrior.health
#   end

## Level 8
# class Player
# 	attr_accessor :warrior
# 	Directions = [:forward, :left, :backward, :right]
	
# 	def initialize
#   	@health = 20
#   end

# 	def play_turn(warrior)
#     #puts '=================================='
#     #puts "Turn Starts"
#   	#puts "Previous health: #{@health}"
#    	#puts "Current health: #{warrior.health}"
#    	#puts "Feel Enemy: #{warrior.feel.enemy?}"
#    	#puts "Feel: "
#    	#puts warrior.feel
#    	#puts warrior.listen

# 		if(warrior.health < 19 and warrior.health < @health)
# 			taking_damage = true 
# 		else
# 			taking_damage = false
# 		end

# 		if warrior.look[1].unit.to_s == "Wizard" and 
# 			 warrior.look[0].unit.to_s != "Captive"
# 			warrior.shoot!
# 		elsif !taking_damage and warrior.health < 19
#     	warrior.rest!
#    	elsif !taking_damage and check_captives warrior
#    		rescue_captive warrior
#    	elsif taking_damage and warrior.health < 6
#    		warrior.walk!:backward
#    	elsif !taking_damage and warrior.feel.wall?
#    		warrior.pivot!
# 		elsif warrior.feel.enemy?
#       warrior.attack!
#     else
#       warrior.walk!
#     end
#     @health = warrior.health
#   end


## ALL
class Player
	attr_accessor :warrior

	Directions = [:forward, :left, :backward, :right]
	Units = [:Wizard, :Archer, :Sludge, :"Thick Sludge", :Captive]
	Enemies = [:Wizard, :Archer, :Sludge, :"Thick Sludge"]
	Ranged = [:Wizard, :Archer]
	Blockers = [:Captive, :Sludge, :"Thick Sludge"]

	def initialize
  	@max_health = 20
  	@min_health = 17
  	@min_health_to_backwards = 6
  	@health = 20
  	@captives = 0
  	@enemies = 0
  	@taking_damage = false
  	@aiming_to = :forward
  	@moved_index = 0
  	@map = Hash.new
  end

	def play_turn(warrior)
		self.warrior = warrior
  	scan_enemies
  	scan_captives
  	scan_map
  	check_enemies_on_map
  	check_taking_damage

  	puts "Health: #{@health}=>#{warrior.health}/#{@max_health}"
  	puts "Remaining:  Enemies #{@enemies} / Captives: #{@captives}"

		if warrior.feel.enemy?
      warrior.attack!
   	elsif @taking_damage and warrior.health < @min_health_to_backwards
   		if @aiming_to == :forward
    		@moved_index -= 1
    	elsif @aiming_to == :backward
    		@moved_index += 1
    	end
   		warrior.walk!:backward
    elsif shoot_arrow != false
			warrior.shoot!(shoot_arrow)  	
		elsif !@taking_damage and warrior.health < @min_health and check_enemies_on_map			
    	warrior.rest!
   	elsif !@taking_damage and check_captives
   		rescue_captive
   	elsif warrior.feel.wall? or missing_captives
   		if @aiming_to == :forward
   			@aiming_to = :backward
   		elsif @aiming_to == :backward
   			@aiming_to = :forward
   		end
   		warrior.pivot!:backward
    else
    	if @aiming_to == :forward
    		@moved_index += 1
    	elsif @aiming_to == :backward
    		@moved_index -= 1
    	end  
      warrior.walk!
    end
    @health = warrior.health
  end

  def check_taking_damage
  			if warrior.health < 19 and warrior.health < @health
			@taking_damage = true 
		else
			@taking_damage = false
		end
	end

  def scan_map
  	units = Array.new
  	Directions.each do |dir|
  		[0,1,2].each do |index|
  			units[index] = warrior.look(dir)[index].unit.to_s.to_sym
  		end
  		#puts "Into Scanmmap #{units} #{@aiming_to} #{dir}"
  		if (@aiming_to == :forward and dir == :forward) or
  			 (@aiming_to == :backward and dir == :backward)
	  			set_map_space(4, :right, units)
	  	elsif (@aiming_to == :forward and dir == :backward) or 
	  			  (@aiming_to == :backward	and dir == :forward)
					set_map_space(2, :left, units)	  			
	  	end
  	end
  end

  def	set_map_space(start, dir, units)
  	[0,1,2].each do |index|
  		#puts "Into set_map_space #{start} #{index} #{@moved_index} #{start-index+@moved_index} => #{units[index]}"
  		if dir == :left
  			@map[[0,(start-index+@moved_index)]] = units[index]
  		elsif dir == :right
  			@map[[0,(start+index+@moved_index)]] = units[index]
  		end
  	end
  end 

  def check_enemies_on_map
  	@map.sort.map do |key, value|
  		#puts "#{key}, #{value}"
  		return true if Enemies.include? value
  	end
  	return false
  end

  def scan_captives
  	captives = 0
  	Directions.each do |dir|
  		[0,1,2].each do |space|
	  		captives += 1 if warrior.look(dir)[space].unit.to_s.to_sym == :Captive
	  	end
  	end
  	if captives > @captives
  		@captives = captives
  	end 
  end

  def scan_enemies
  	@enemies = 0
  	Directions.each do |dir|
  		[0,1,2].each do |space|
  			@enemies += 1 if Enemies.include? warrior.look(dir)[space].unit.to_s.to_sym
  		end
  	end
  end

  def missing_captives
 		Directions.each do |dir|
 	 		return true if dir != :forward and
 	 									 @captives > 0 and
 	 									 (warrior.look(dir)[1].unit.to_s.to_sym == :Captive or
  		 		 					 warrior.look(dir)[2].unit.to_s.to_sym == :Captive)
  	end
  	return false
  end

  def check_unit_type_by_space(enemyType, space, dir)
  	return true if enemyType.include?warrior.look(dir)[space].unit.to_s.to_sym	
  	return false
  end

  def space_by_unit_type(unitType, space, dir)
  	return true if warrior.look(dir)[space].unit.to_s.to_sym == unitType
  	return false
  end

  def in_danger
  	Directions.each do |dir|
  		return dir if 
  		  check_unit_type_by_space(Enemies, 0, dir) or
  			(check_unit_type_by_space(Ranged, 1, dir) and !check_unit_type_by_space(Blockers, 0, dir)) or
  			(check_unit_type_by_space(Ranged, 2, dir) and !check_unit_type_by_space(Blockers, 1, dir) and !check_unit_type_by_space(Blockers, 0, dir))
		end
		return false
  end

  def shoot_arrow
  	Directions.each do |dir|
  		return dir if 
  		  (space_by_unit_type(:Wizard, 1, dir) and !check_unit_type_by_space(Blockers, 0, dir)) or
  			(space_by_unit_type(:Wizard, 2, dir) and !check_unit_type_by_space(Blockers, 0, dir) and !check_unit_type_by_space(Blockers, 1, dir)) 
   	 	end
  	return false
  end

  def check_captives
    Directions.each do |dir|
      if warrior.feel(dir).captive?
        return true
      end
    end
    return false
  end

  def rescue_captive
  	Directions.each do |dir|
      if warrior.feel(dir).captive?
        warrior.rescue!(dir)
        @captives -= 1  
      end
    end
  end
end