include TeamHelper
class Team < ActiveRecord::Base
  has_many :teams_users
  has_many :users, :through => :teams_users
  has_many :join_team_requests

  def delete
    for teamsuser in TeamsUser.find(:all, :conditions => ["team_id =?", self.id])       
       teamsuser.delete
    end    
    node = TeamNode.find_by_node_object_id(self.id)
    if node
      node.destroy
    end
    self.destroy
  end

  def get_node_type
    "TeamNode"
  end
  
  def get_author_name
    return self.name
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
  
  def get_possible_team_members(name)
     query = "select users.* from users, participants"
     query = query + " where users.id = participants.user_id"
     query = query + " and participants.type = '"+self.get_participant_type+"'"
     query = query + " and participants.parent_id = #{self.parent_id}"
     query = query + " and users.name like '#{name}%'"
     query = query + " order by users.name"
     User.find_by_sql(query) 
 end
 
 def has_user(user)
   if TeamsUser.find_by_team_id_and_user_id(self.id, user.id) 
     return true
   else
     return false
   end
 end

 def add_member(user)
   if has_user(user)
     raise "\""+user.name+"\" is already a member of the team, \""+self.name+"\""
   end
   t_user = TeamsUser.create(:user_id => user.id, :team_id => self.id) 
   parent = TeamNode.find_by_node_object_id(self.id)
   TeamUserNode.create(:parent_id => parent.id, :node_object_id => t_user.id)
   add_participant(self.parent_id, user)  
 end  
 
 def copy_members(new_team)
   members = TeamsUser.find_all_by_team_id(self.id)
   members.each{
     | member |
     t_user = TeamsUser.create(:team_id => new_team.id, :user_id => member.user_id)
     parent = Object.const_get(self.get_parent_model).find(self.parent_id)
     TeamUserNode.create(:parent_id => parent.id, :node_object_id => t_user.id)
   }   
 end
 
 def self.create_node_object(name, parent_id)
   create(:name => name, :parent_id => parent_id)
   parent = Object.const_get(self.get_parent_model).find(parent_id)
   Object.const_get(self.get_node_type).create(:parent_id => parent.id, :node_object_id => self.id)
 end

 def self.check_for_existing(parent, name, team_type)
   list = Object.const_get(team_type + 'Team').find(:all, :conditions => ['parent_id = ? and name = ?', parent.id, name])
   if list.length > 0
     raise TeamExistsError, 'Team name, "' + name + '", is already in use.'
   end
 end

  def self.delete_all_by_parent(parent)
    teams = Team.find(:all, :conditions => ["parent_id=?", parent.id])

    for team in teams
      team.delete
    end
  end

# @param parent [Object]
# @param team_type [Object]
# @param team_size [Object]
  def self.randomize_all_by_parent(parent, team_type, team_size)
    participants = Participant.find(:all, :conditions => ["parent_id = ? AND type = ?", parent.id, parent.class.to_s + "Participant"])
    participants = participants.sort{rand(3) - 1}
    users = participants.map{|p| User.find_by_id(p.user_id)}
    #users = users.uniq

    Team.delete_all_by_parent(parent)

    no_of_teams = users.length.fdiv(team_size).ceil
    nextTeamMemberIndex = 0

    for i in 1..no_of_teams
      team = Object.const_get(team_type + 'Team').create(:name => "Team #{i}", :parent_id => parent.id)
      TeamNode.create(:parent_id => parent.id, :node_object_id => team.id)

      team_size.times do
        break if nextTeamMemberIndex >= users.length

        user = users[nextTeamMemberIndex]
        team.add_member(user)

        nextTeamMemberIndex += 1
      end
    end
  end
  def self.check_course(id)
    course1 = Course.find(id)
    if course1 == nil
      raise ImportError, "The course with id \""+id.to_s+"\" was not found. <a href='/assignment/new'>Create</a> this assignment?"
    end
    course1
  end

  def self.find_current_team(name,id)
    currTeam = CourseTeam.find(:first, :conditions => ["name =? and parent_id =?",name,id])
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
    parent = CourseNode.find_by_node_object_id(id)
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
