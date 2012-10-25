require File.dirname(__FILE__) + '/../test_helper'


class ParticipantTest < ActiveSupport::TestCase
  fixtures :participants
  fixtures :courses
  fixtures :assignments
  fixtures :users
  fixtures :roles

  def setup

  end

  def test_add_participant
    participant = Participant.new

    #TODO Should an empty Participant be allowed?
    # assert !participant.valid??
    #TODO Define requerid fields in test and add those validations to the model so test passes.

    assert participant.valid?
  end

  def test_add_course_participant
    #participant = CourseParticipant.new

    #TODO read TODO tag in lines 11-13

    participant = participants(:par5)
    assert participant.valid?
    assert participant.get_course_string
    assert participant.get_parent_name
    c_course = courses(:course1)
    assert c_course.id
    assert c_course.get_participants
    assert c_course.get_teams
    assert participant.copy(c_course)
  end

  def test_course_participant_import
    row = Array.new
    row[0] = "student2"
    row[1] = "student2_fullname"
    row[2] = "student2@foo.edu"
    row[3] = "stu2"

    @request = ActionController::TestRequest.new
    @request.session[:user] = User.find( users(:student2).id )
    role_id = User.find(users(:student2).id).role_id
    Role.rebuild_cache
    Role.find(role_id).cache[:credentials]
    @request.session[:credentials] = Role.find(role_id).cache[:credentials]
    AuthController.set_current_role(role_id,@request.session)

    id = Assignment.find(assignments(:assignment_team_count).id).id

    c_course = courses(:course2)

    pc = CourseParticipant.count
    assert CourseParticipant.import(row,@request.session,c_course.id)
    # verify that a single user was added to participants table
    assert_equal pc+1,CourseParticipant.count
    user = User.find_by_name("student2")
    # verify that correct user was added
    assert CourseParticipant.find_by_user_id(user.id)
  end

  def test_course_participant_export

    c_par = CourseParticipant.new
    csv = Array.new
    row = Array.new
    row[0] = "student3"
    row[1] = "student3_fullname"
    row[2] = "student"
    row[3] = "student3@foo.edu"
    row[4] = "stu3"

    assert CourseParticipant.export(csv,c_par.parent_id,row)
    assert CourseParticipant.get_export_fields("handle")
    assert CourseParticipant.get_export_fields("role")
  end

  def test_add_assignment_participant

    a_participant = Participant.new
    assert a_participant.valid?

    #assert !participant.valid?

    #TODO read TODO tag in line 13

    #participant.handle = 'test_handle'
    a_participant = participants(:par4)
    assert a_participant.valid?
    p_course = courses(:course1)
    assert p_course.id
    assert p_course.instructor_id
    assert p_course.directory_path
    assert a_participant.copy(p_course)
  end

  def test_delete_not_force
    participant = participants(:par1)
    participant.delete
    assert participant.valid?
  end
end