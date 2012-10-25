class CourseTeam < Team

  def self.import(row,session,id,options)
    if row.length < 2
      raise ArgumentError, "Not enough items"
    end

    course = check_course(id)

    if options[:has_column_names] == "true"
      name = row[0].to_s.strip
      index = 1
    else
      name = generate_team_name()
      index = 0
    end

    currTeam = find_current_team(name,course.id)

    if options[:handle_dups] == "ignore" && currTeam != nil
      return
    end

    if currTeam != nil && options[:handle_dups] == "rename"
      name = generate_team_name()
      currTeam = nil
    end
    if options[:handle_dups] == "replace" && teams.first != nil
      currTeam = replace_team(currTeam.id)
    end

    if currTeam == nil
      currTeam = new_team(name,course.id)
    end

    while(index < row.length)
      user = User.find_by_name(row[index].to_s.strip)
      if user == nil
        raise ImportError, "The user \""+row[index].to_s.strip+"\" was not found. <a href='/users/new'>Create</a> this user?"
      elsif currTeam != nil
        currUser = TeamsUser.find(:first, :conditions => ["team_id =? and user_id =?", currTeam.id,user.id])
        if currUser == nil
          currTeam.add_member(user)
        end
      end
      index = index+1
    end
  end

  def get_participant_type
    "CourseParticipant"
  end

  def get_parent_model
    "Course"
  end

  def get_node_type
    "TeamNode"
  end

  def copy(assignment_id)
    new_team = AssignmentTeam.create_node_object(self.name, assignment_id)
    copy_members(new_team)
  end

  def add_participant(course_id, user)
    if CourseParticipant.find_by_parent_id_and_user_id(course_id, user.id) == nil
      CourseParticipant.create(:parent_id => course_id, :user_id => user.id, :permission_granted => user.master_permission_granted)
    end
  end
  def self.export(csv, parent_id, options)
    course = Course.find(parent_id)
    assignmentList = Assignment.find_all_by_course_id(parent_id)
    assignmentList.each do |currentAssignment|
      currentAssignment.teams.each { |team|
        tcsv = Array.new
        teamUsers = Array.new
        tcsv.push(team.name)
        if (options["team_name"] == "true")
          teamMembers = TeamsUser.find(:all, :conditions => ['team_id = ?', team.id])
          teamMembers.each do |user|
            teamUsers.push(user.name)
            teamUsers.push(" ")
          end
          tcsv.push(teamUsers)
        end
        tcsv.push(currentAssignment.name)
        tcsv.push(course.name)
        csv << tcsv
      }
    end
  end

  def self.get_export_fields(options)
    fields = Array.new
    fields.push("Team Name")
    if (options["team_name"] == "true")
      fields.push("Team members")
    end
    fields.push("Assignment Name")
    fields.push("Course Name")
  end
end