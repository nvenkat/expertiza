require File.dirname(__FILE__) + '/../test_helper'

class CourseNodeTest < ActiveSupport::TestCase
  fixtures :courses
  fixtures :nodes

  def setup
    @node = nodes(:node12)
    @course = courses (:course1)
  end

def test_get_teams
  assert_kind_of Node, @node
  assert_equal TeamNode, @node.type
  assert_equal nodes(:node12).node_object_id, @node.node_object_id
  assert_equal nodes(:node12).parent_id, @node.parent_id
end

def test_created_at
  assert_instance_of ActiveSupport::TimeWithZone, @course.created_at
end

def test_modified_at
  assert_instance_of ActiveSupport::TimeWithZone, @course.updated_at
end

def test_get_directory
  assert_equal @course.directory_path, "csc111"
end

def test_get_name
  assert_equal @course.name, "CSC111"
end
end
