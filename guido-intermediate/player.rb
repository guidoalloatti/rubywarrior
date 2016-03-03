class Player
  # Declaring variables and arrays 
  attr_accessor :warrior
  Directions = [:forward, :left, :backward, :right]
  Enemies = [:Wizard, :Archer, :"Sludge", :"Thick Sludge"]
  Captives = [:Captive]

  # Initial warrior attributes setting
  def initialize
    @enemies_direction = Array.new
    @captives_direction = Array.new
    @max_health = 20
    @health = 20
    @min_health = 15
    @retreat_health = 4
    @enemies = 0
    @captives = 0
    @binded = 0
    @enemies_binded = 0
    @bombs_used = 0
    @close_enemies = 0
    @captive_unit = nil
    @enemy_unit = nil
    @turn = 0
  end

  # Setting every turn actions
  def play_turn(warrior)
    @turn += 1
    puts "[============= NEW TURN | #{@turn} =============]"
    self.warrior = warrior
    @bomb_optimal_direction = track_bomb
    count_enemies
    get_enemies_info
    get_captives_info
    choose_attack_direction

    # Showing health and general information including the bomb information for this turn 
    puts "[========== Health: #{@health} => #{warrior.health} / #{@max_health} (last turn => this turn / max health)"
    puts "[========== Remaining:  Enemies #{@enemies} / Captives: #{@captives} / Binded: #{@enemies_binded}"
    if check_for_a_bomb
      puts "[========== There is a bomb to the direction #{get_bomb_direction}"
    end

    # Actions to be performed
    action = evade||bind||detonate||rest||retreat||attack||release||walk
    puts "[========== Action executed: #{action}"

    # End of the turn actions
    @health = warrior.health
  end

  ######################################################
  # Here starts the methods to the actions definitions #
  ######################################################

  # Define method for the evade action
  # evade checks if it is needed to avoid stairs and clear the level first
  def evade
    return false if (@enemies < 1 and @captives < 1) or         # There are units to interact
                    enemies_close or                            # There are enemies close
                    captives_close or                           # There are captives close   
                    !warrior.feel(get_stairs_location).stairs?  # There are no stairs close
    puts "Evading the stairs, there are unit to interact with still"
    Directions.each do |dir|
      if warrior.feel(dir).stairs?
        Directions.each do |new_dir|
          if !warrior.feel(new_dir).stairs? and
             !warrior.feel(new_dir).wall? and
             !warrior.feel(new_dir).enemy? and
             !warrior.feel(new_dir).captive? and 
             warrior.feel(new_dir).empty? and 
             dir == warrior.direction_of(warrior.listen.first)
            return warrior.walk! new_dir
          end
        end 
      end
    end
    return false
  end

  # Define method for the bind action
  # bind allows the warrior to binding enemies when surrounded
  def bind
    if @close_enemies > 2 and @enemies_binded < 3
      Directions.each do |dir|
        if warrior.feel(dir).enemy?
          puts "Binding enemy #{warrior.look(dir)[0].to_s.to_sym} to the #{dir}"
          @enemies_binded += 1        
          return warrior.bind! dir
        end    
      end 
    end
    return false
  end

  # Define method for the detonate action
  # detonate stablishes when a bomb should be released
  def detonate
    if (Enemies.include?warrior.look(:forward)[0].unit.to_s.to_sym and 
       Enemies.include?warrior.look(:forward)[1].unit.to_s.to_sym) or
       (Enemies.include?warrior.look(:left)[0].unit.to_s.to_sym and 
       Enemies.include?warrior.look(:right)[0].unit.to_s.to_sym and 
       !Captives.include?warrior.look(:forward)[2].unit.to_s.to_sym) or 
       (Enemies.include?warrior.look(:forward)[0].unit.to_s.to_sym and 
       Enemies.include?warrior.look(:backward)[0].unit.to_s.to_sym) and
       warrior.health > 4 and @bombs_used < 4 and !captives_close
      @bombs_used += 1
      return warrior.detonate!:forward
    end
  end

  # Define method for the rest action
  # rest determines when is save to rest and heal when the health is low
  def rest
    return false if under_attack or @enemies < 1
    if check_for_a_bomb and !under_attack and warrior.health < @min_health/3
      puts "Resting the minimun since there is a bomb that needs to be deactivated"
      return warrior.rest!
    elsif !check_for_a_bomb and !under_attack and warrior.health < @min_health 
      puts "Resting a lot since there is no risk"
      return warrior.rest!
    end
    return false
  end

  # Define method for the retreat action
  # retreat defines when to escape from the fight since health is too low and warrior is under attack
  def retreat
    return false if count_unit_type(:Sludge) > 5
    if under_attack and warrior.health < @retreat_health and @enemies > 0
      Directions.each do |dir|
        if warrior.feel(dir).empty? and 
          !warrior.feel(dir).wall? and 
          !warrior.feel(dir).stairs? 
          puts "Retreating to the #{dir} to heal"
          @enemies_binded = 0
          return warrior.walk! dir
        end
      end
    end
    return false
  end

  # Define method for the attack action
  # attack defines a set of rules that determines when attacking is the best option
  def attack
    return false if @enemies < 1 or                                    # There are no enemies to attack 
                    @enemies_direction == [] or                        # Dont know where the enemy is
                    (@captives > 0 and bomb_has_direct_path) or        # Can walk to the bomb wihout fighting
                    (@captives > 0 and check_captive_behind_enemy) or  # Needs to elude an enemy to deactivate the bomb
                    (@captives > 0 and bomb_is_on_a_side) or           # The captive with the bomb is on a side
                    !enemies_close #or                                  # There are no enemies to fight with
                    #!get_best_enemy_direction_to_attack
    if (@captives > 0 and check_for_a_bomb and warrior.feel(get_bomb_direction).enemy?) or
       (@captives > 0 and warrior.feel(@captives_direction[0]).captive? and !warrior.feel(@captives_direction[0]).enemy? and @enemies_binded > 2) or
       (@captives == 0 and enemies_close) or
       (@captives > 0 and enemies_close and !check_for_a_bomb)
      puts "Attacking an enemy to the #{@enemies_direction[0]}"
      if warrior.feel(@enemies_direction[0]).captive? and @enemies_direction[1] != nil and @enemies_binded < 3
        return warrior.attack! @enemies_direction[1]
      else
        return warrior.attack! @enemies_direction[0]
      end  
    end
    return false
  end

  # Define method for the walk action
  # walk determines if moving is the best option and the direction to go, the stairs, an enemy, a captive, etc
  def walk
    return false if (@captives > 0 and captives_close and warrior.feel(get_bomb_direction).captive?) or # Captives needs to be rescued, dont walk away
                    count_unit_type(:Sludge) > 5
    message = nil
    walk_to = nil
    if check_for_a_bomb and @bomb_optimal_direction != false
      message = "Walking to captive with the bomb optimal direction to direction #{@bomb_optimal_direction}"
      walk_to = @bomb_optimal_direction
    elsif @captives > 0 and check_for_a_bomb and !warrior.feel(:forward).enemy?
      message = "Walking to get the captive with a bomb to direction #{get_bomb_direction}"
      walk_to = get_bomb_direction
    elsif @captives > 0 and warrior.look(:forward)[1].to_s.to_sym == :"Thick Sludge" and count_unit_type(:"Thick Sludge") > 1
      message = "Walking to avoid sludges to direction #{@captives_direction[0]}"
      walk_to = :right
    elsif @enemies_binded < 3 and @captives > 0 and !enemies_close
      message = "Walking to rescue captives to direction #{@captives_direction[0]}"
      walk_to = @captives_direction[0]
    elsif !under_attack and warrior.listen.empty?
      message = "Walking to the stairs to direction #{warrior.direction_of_stairs}"
      walk_to = warrior.direction_of_stairs
    elsif !under_attack and !enemies_close
      message = "Walking to closest unit to direction #{warrior.direction_of(warrior.listen.first)}"
      walk_to = warrior.direction_of(warrior.listen.first)
    end
    if walk_to != nil
      if message != nil
        puts message
      end
      return warrior.walk! walk_to
    end
    return false
  end

  # Define method for the rescue action
  # release provides the ability to rescue captives, they can be regular captives or captives with bombs, which should be released first
  def release
    return false if @captives < 1 or 
           warrior.feel(@captives_direction[0]).enemy? or
           !captives_close or bomb_has_direct_path
    if bomb_is_on_a_side
      puts "Rescuing the captives with the bomb in #{get_best_side_to_the_bomb}"
      return warrior.rescue! get_best_side_to_the_bomb
    elsif captives_close
      puts "Rescuing the captives without the bomb in #{@captives_direction[0]}"
      return warrior.rescue! @captives_direction[0]
    end
    return false
  end

  ##################################################
  # Here starts the helpers methods to the actions #
  ##################################################

  # Check if the captive is behind an enemy
  def check_captive_behind_enemy 
    return true if @captives > 0 and check_for_a_bomb and           
                   warrior.feel(:left).empty? and !warrior.feel(:left).wall? and
                   warrior.look(:forward)[1].to_s.to_sym == :Captive and
                   warrior.look(:forward)[0].to_s.to_sym == :Sludge
    return false
  end

  # This method provides information about a thicking Captive
  def check_for_a_bomb
    warrior.listen.each do |unit|
      if Captives.include? unit.to_s.to_sym and unit.ticking?
        return true
      end
    end
    return false
  end

  # This method provides the direction for captive that holds the bomb
  def get_bomb_direction
    warrior.listen.each do |unit|
      if Captives.include? unit.to_s.to_sym and unit.ticking?
          return warrior.direction_of(unit)
      end 
    end
    return false
  end

  # Return if the comparison of the directions are oposite
  def is_oposite_direction(dir1, dir2)
    return true if(dir1 == :forward and dir2 == :backward) or
                  (dir1 == :forward and dir2 == :forward) or
                  (dir1 == :left and dir2 == :right) or
                  (dir1 == :right and dir2 == :left)
    return false
  end

  # This method gets all the information in regards of the captives
  def get_captives_info
    @captives = 0
    @captives_direction = Array.new
    warrior.listen.each do |unit|
      if Captives.include? unit.to_s.to_sym
        @captives += 1
        @captives_direction.push warrior.direction_of(unit)
      end    
    end
    return false
  end

  # This method stores all the enemies around the warrior
  def choose_attack_direction
    @enemies_direction = Array.new
    Directions.each do |dir|
      if warrior.feel(dir).enemy? != nil
        @enemies_direction.push dir
      end
    end
    return false  
  end

  # This method gest all the enemies info
  def get_enemies_info
    @enemies = 0
    warrior.listen.each do |unit|
      if Enemies.include? unit.to_s.to_sym
        @enemies += 1
      end    
    end
    return false
  end

  # Method to evaluate if the warrior is under attack
  def under_attack 
    return true if warrior.health < @health
    return false
  end

  # Method to the the direction to the stairs
  def get_stairs_location
    return warrior.direction_of_stairs
  end

  # This methods return the amount of a particular unit in the map
  def count_unit_type unit_type
    count = 0
    warrior.listen.each do |unit|
      count += 1 if unit.to_s.to_sym == unit_type
    end
    return count
  end

  # Method that checks if there is a captive near to the warrior
  def captives_close
    Directions.each do |dir|
      return true if warrior.look(dir)[0].unit.to_s.to_sym == :Captive
    end
    return false
  end

  # Method that checks if there is a enemy near to the warrior
  def enemies_close
    Directions.each do |dir|
      return true if Enemies.include? warrior.look(dir)[0].to_s.to_sym
    end
    return false
  end

  # Method that checks if there is a enemy near to the warrior
  def count_enemies
    @close_enemies = 0
    Directions.each do |dir|
      @close_enemies += 1 if Enemies.include? warrior.look(dir)[0].to_s.to_sym
    end
  end

  # This method checks the best path to track a bomb
  def track_bomb
    return false if @captives < 1 or 
                    !check_for_a_bomb or 
                    !get_bomb_direction
    puts "There is a bomb, figuring out the best way to get it"
    if check_captive_behind_enemy
      puts "Need to avoid enemies"
      return get_direction_to_avoiding_enemies
    elsif bomb_has_direct_path
      puts "Can walk to the bomb"
      return get_bomb_direction
    elsif bomb_is_on_a_side
      puts "The bomb is on a side"
      return get_best_side_to_the_bomb
    end
    return false
  end

  # Determines if the captive with the bomb is on a side
  def bomb_is_on_a_side
    return false if !check_for_a_bomb or @enemies_binded > 2
    Directions.each do |dir|
      return false if !Captives.include? warrior.look(dir)[0].to_s.to_sym and warrior.feel(dir).ticking?
    end
    return true
  end 

  # Evaluates the best way to get to the captive with the bomb when is on a side
  def get_best_side_to_the_bomb
    return false if !check_for_a_bomb
    @captive_unit = nil
    @enemy_unit = nil
    warrior.listen.each do |unit|
      if Captives.include? unit.to_s.to_sym and unit.ticking? #Captive with bomb found
        if warrior.feel(warrior.direction_of(unit)).empty? or warrior.feel(warrior.direction_of(unit)).captive?
          puts "Captive is accesible to the #{warrior.direction_of(unit)}"
          return warrior.direction_of(unit)
        elsif warrior.feel(warrior.direction_of(unit)).enemy? or warrior.feel(warrior.direction_of(unit)).stairs?
          @enemy_unit = unit
          Directions.each do |dir|
            return dir if warrior.feel(dir).empty? and !warrior.feel(dir).wall? and
                          !warrior.feel(dir).stairs? and dir != warrior.direction_of(@enemy_unit)
                          !is_oposite_direction(dir, warrior.direction_of(unit))                    
          end
        end
      end  
    end
    return false
  end

  # Determines if the captive with the bomb can be reached directly
  def bomb_has_direct_path
    return false if !check_for_a_bomb
    direction = warrior.feel(get_bomb_direction)
    return true if direction.empty? and 
                   !direction.stairs? and 
                   !direction.wall?
    return false
  end

  # Check the best way to go to avoid enemies
  def get_direction_to_avoiding_enemies
    Directions.each do |dir|
      if !warrior.feel(dir).wall? and
         warrior.feel(dir).empty? and
         !is_oposite_direction(dir, get_bomb_direction)
        return dir
      end
    end
    return false
  end
end