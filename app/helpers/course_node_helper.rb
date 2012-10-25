module CourseNodeHelper

  def get_conditions(show=nil,user_id=nil)
    if show
      conditions = 'courses.instructor_id in (?)'
    else
      conditions = '(courses.private = 0 or courses.instructor_id in (?))'
    end

    if show
      if User.find(user_id).role.name != "Teaching Assistant"
        conditions = 'courses.instructor_id = ?'
      else
        conditions = 'courses.id in (?)'
      end
    else
      if User.find(user_id).role.name != "Teaching Assistant"
        conditions = '(courses.private = 0 or courses.instructor_id = ?)'
      else
        conditions = '(courses.private = 0 or courses.id in (?))'
      end
      conditions
    end
  end

  def get_values(user_id=nil)
    if User.find(user_id).role.name != "Teaching Assistant"
      values = user_id
    else
      values = Ta.get_mapped_courses(user_id)
    end
    values
  end


end