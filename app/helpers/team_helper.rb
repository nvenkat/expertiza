module TeamHelper

  #separates the file into the necessary elements to create a new user
  def self.upload_teams(file, assignment_id, options,logger)
    unknown = Array.new
    while (rline = file.gets)
      split_line = rline.split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/)
      if options[:has_column_names] == "true"
        name = split_line[0]
        pos = 1
      else
        name = generate_team_name()
        pos = 0
      end
      teams = Team.find(:all, :conditions => ["name =? and assignment_id =?",name,assignment_id])
      currTeam = teams.first
      if currTeam != nil && options[:handle_dups] == "rename"
        name = generate_team_name()
        currTeam = nil
      end
      if options[:handle_dups] == "replace" && teams.first != nil
        for teamsuser in TeamsUser.find(:all, :conditions => ["team_id =?", currTeam.id])
          teamsuser.destroy
        end
        currTeam.destroy
        currTeam = nil
      end
      if teams.length == 0 || currTeam == nil
        currTeam = Team.new
        currTeam.name = name
        currTeam.assignment_id = assignment_id
        currTeam.save
      end

      logger.info "#{split_line.length}"
      logger.info "#{split_line}"
      while(pos < split_line.length)
        user = User.find_by_name(split_line[pos].strip)
        if user && !(options[:handle_dups] == "ignore" && teams.length > 0)
          teamusers = TeamsUser.find(:all, :conditions => ["team_id =? and user_id =?", currTeam.id,user.id])
          currUser = teamusers.first
          if teamusers.length == 0 || currUser == nil
            currUser = TeamsUser.new
            currUser.team_id = currTeam.id
            currUser.user_id = user.id
            currUser.save

            Participant.create(:assignment_id => assignment_id, :user_id => user.id, :permission_granted => true)
          end
        else
          unknown << split_line[pos]
        end
        pos = pos+1
      end
    end

    return unknown
  end

  def self.generate_team_name()
    counter = 0
    while (true)
      temp = "Team #{counter}"
      if (!Team.find_by_name(temp))
        return temp
      end
      counter=counter+1
    end
  end

  def self.check_course(id)
    course = Course.find(id)
    if course == nil
      raise ImportError, "The course with id \""+id.to_s+"\" was not found. <a href='/assignment/new'>Create</a> this assignment?"
    end
    course
  end

  def self.find_current_team(name,id)
    CourseTeam.find(:first, :conditions => ["name =? and parent_id =?",name,id])
  end

  def self.replace_team(id)
    for teamsuser in TeamsUser.find(:all, :conditions => ["team_id =?", id])
      teamsuser.destroy
    end
    currTeam.destroy
    currTeam = nil
  end

  def self.new_team(name,id)
    currTeam = CourseTeam.new
    currTeam.name = name
    currTeam.parent_id = id
    currTeam.save
    parent = CourseNode.find_by_node_object_id(course.id)
    TeamNode.create(:parent_id => parent.id, :node_object_id => currTeam.id)
    currTeam
  end

  def self.add_user_to_team(row,currTeam)
    user = User.find_by_name(row[index].to_s.strip)
    if user == nil
      raise ImportError, "The user \""+row[index].to_s.strip+"\" was not found. <a href='/users/new'>Create</a> this user?"
    elsif currTeam != nil
      currUser = TeamsUser.find(:first, :conditions => ["team_id =? and user_id =?", currTeam.id,user.id])
      if currUser == nil
        currTeam.add_member(user)
      end
    end
    currTeam
  end

end
