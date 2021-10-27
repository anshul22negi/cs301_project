create database project;
\c project


CREATE TABLE instructors(
              instructor_id serial PRIMARY KEY,
              instructor_name VARCHAR(255) NOT NULL,
              department VARCHAR(255) NOT NULL
);

CREATE TABLE courses(
              course_id serial PRIMARY KEY,
              course_name VARCHAR(255) NOT NULL,
	          L INTEGER NOT NULL,
	          T INTEGER NOT NULL,
	          P INTEGER NOT NULL,
	          S INTEGER NOT NULL,     
              C INTEGER NOT NULL
);

CREATE TABLE offerings(
              course_id INTEGER NOT NULL,
              instructor_id INTEGER NOT NULL,
              section INTEGER NOT NULL,
              semester INTEGER NOT NULL,
              Year INTEGER NOT NULL,
              running VARCHAR(255) NOT NULL,
              slot varchar(255) NOT NULL,
              PRIMARY KEY (course_id, section, semester, year)  
);

CREATE TABLE prerequisites(
              course_id INTEGER NOT NULL,
              prerequisite INTEGER NOT NULL

);
CREATE TABLE Students(
               student_id serial PRIMARY KEY,
               student_name VARCHAR(255) NOT NULL,
               department VARCHAR(255) NOT NULL,
               batch INTEGER NOT NULL
);

CREATE TABLE Tickets(
               ticket serial PRIMARY KEY,
               student_id INTEGER,
	           course_id INTEGER,
               section INTEGER NOT NULL,
               semester BOOLEAN,
               year  INTEGER,
	           instructor_approval BOOLEAN,
	           batch_advisor_approval BOOLEAN,
               dean_approval BOOLEAN
);



========================================================================================

Procedures:

create or replace procedure register_course(
               _course_name VARCHAR(255),
	           _L int,
	           _T int,
	           _P int,
	           _S int,     
               _C int
    )
    language plpgsql
    as $$
    declare
        course_already_registered integer;
    BEGIN
       SELECT COUNT(*)
       INTO course_already_registered
       FROM courses
       WHERE courses.course_name = _course_name;

       if course_already_registered = 0 THEN
          INSERT INTO courses(course_name, L, T, P, S, C)
          VALUES (_course_name, _L, _T, _P, _S, _C);
       end if;
    end; $$;

-----------------------------
create or replace procedure register_instructor(
               _instructor_name VARCHAR(255),
	           _department VARCHAR(255)
    )
    language plpgsql
    as $$
    BEGIN
          INSERT INTO instructors(instructor_name, department)
          VALUES (_instructor_name, _department);
    
    end; $$;

--------------------------------------------
create or replace procedure register_student(
               _student_name VARCHAR(255),
	           _department VARCHAR(255),
	           _batch int
    )
    language plpgsql
    as $$
    BEGIN
          INSERT INTO students(student_name, department, batch)
          VALUES (_student_name, _department, _batch);
    end; $$;

--------------------------------------------
create or replace procedure add_prerequisite(
               _course_id int,
	           _prerequisite VARCHAR(255)
    )
    language plpgsql
    as $$
    declare
        course_present integer;
    BEGIN
       SELECT COUNT(*)
       INTO course_present
       FROM courses
       WHERE courses.course_id = _course_id;

       if course_present > 0 then
          INSERT INTO prerequisites(course_id, prerequisite)
          VALUES (_course_id, _prerequisite);
       end if;
    end; $$;