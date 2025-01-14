require "../spec_helper"

def assert_single_read(rs, value_type, value)
  rs.move_next.should be_true
  rs.read(value_type).should eq(value)
  rs.move_next.should be_false
end

class NotSupportedType
end

describe PG::Driver do
  it "should register postgres name" do
    DB.driver_class("postgres").should eq(PG::Driver)
  end

  it "exectes and selects value" do
    PG_DB.query "select 123::int4" do |rs|
      assert_single_read rs, Int32, 123
    end
  end

  it "gets column count" do
    PG_DB.query "select 1::int4, 1::int4" do |rs|
      rs.column_count.should eq(2)
    end
  end

  it "gets column names" do
    PG_DB.query "select 1::int4 as foo, 1::int4 as bar" do |rs|
      rs.column_name(0).should eq("foo")
      rs.column_name(1).should eq("bar")
    end
  end

  it "executes insert" do
    PG_DB.exec "drop table if exists contacts"
    PG_DB.exec "create table contacts (name varchar(256), age int4)"

    result = PG_DB.exec "insert into contacts values ($1, $2)", "Foo", 10

    result.last_insert_id.should eq(0) # postgres doesn't support this
    result.rows_affected.should eq(1)
  end

  it "executes insert via query" do
    PG_DB.query("drop table if exists contacts") do |rs|
      rs.move_next.should be_false
    end
  end

  it "executes update" do
    PG_DB.exec "drop table if exists contacts"
    PG_DB.exec "create table contacts (name varchar(256), age int4)"

    PG_DB.exec "insert into contacts values ($1, $2)", "Foo", 10
    PG_DB.exec "insert into contacts values ($1, $2)", "Baz", 10
    PG_DB.exec "insert into contacts values ($1, $2)", "Baz", 20

    result = PG_DB.exec "update contacts set age = 30 where age = 10"

    result.last_insert_id.should eq(0) # postgres doesn't support this
    result.rows_affected.should eq(2)
  end

  it "traverses result set" do
    PG_DB.exec "drop table if exists contacts"
    PG_DB.exec "create table contacts (name varchar(256), age int4)"

    PG_DB.exec "insert into contacts values ($1, $2)", "Foo", 10
    PG_DB.exec "insert into contacts values ($1, $2)", "Bar", 20

    PG_DB.query "select name, age from contacts order by age" do |rs|
      rs.move_next.should be_true
      rs.read(String).should eq("Foo")
      rs.move_next.should be_true
      rs.read(String).should eq("Bar")
      rs.move_next.should be_false
    end
  end
end
