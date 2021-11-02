create database project3;
\c project3


CREATE GROUP gp_instructors;
CREATE GROUP gp_students;
CREATE GROUP gp_advisors;

do $$
begin
IF NOT EXISTS (SELECT * FROM pg_user WHERE usename = 'dean') then
raise notice 'dean does not exist, creating dean';
create role dean login password 'dean';
end if;
end
$$;





CREATE TABLE students (
    student_id serial PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department VARCHAR(255) NOT NULL,
    year INTEGER NOT NULL
);

GRANT ALL 
ON students 
TO dean;

GRANT SELECT
ON students
TO gp_students, gp_instructors, gp_advisors;

create or replace procedure create_student(
               _student_name VARCHAR(255),
	           _department VARCHAR(255),
	           _batch int
    )
    language plpgsql
    as $$
    BEGIN
          INSERT INTO students(name, department, year)
          VALUES (_student_name, _department, _batch);
    end; $$;

create or replace function create_student_transcript_table()
returns trigger
language plpgsql
as $$
declare
    pass VARCHAR(20) :=  'st' || NEW.student_id;    
    query text;   
begin
    EXECUTE format('CREATE TABLE %I (offerring_id INTEGER PRIMARY KEY, grade INTEGER);', 'transcript_' || NEW.student_id);
    query := format('CREATE ROLE %I LOGIN PASSWORD ''st'';',  'st' || NEW.student_id);
    RAISE NOTICE 'query = %', query;
    IF NOT EXISTS (SELECT * FROM pg_user WHERE usename = 'st' || NEW.student_id) then
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''st'';',  'st' || NEW.student_id);
    end if;
    RAISE notice 'student_id on insert = %', NEW.student_id;
    EXECUTE format('ALTER GROUP gp_students ADD USER %I;', 'st' || NEW.student_id);
    
    EXECUTE format('GRANT SELECT ON %I TO %I, gp_instructors, gp_advisors;', 'transcript_' || NEW.student_id, 'st' || NEW.student_id);
    EXECUTE format('GRANT ALL ON %I TO dean;', 'transcript_' || NEW.student_id, 'st' || NEW.student_id);
    return NEW;        
end; $$;

CREATE TRIGGER trigger_create_student_transcript_table
BEFORE INSERT 
ON students
FOR EACH ROW
EXECUTE PROCEDURE create_student_transcript_table();

CALL create_student('st1', 'mech', 2021);
CALL create_student('st2', 'mech', 2020);
CALL create_student('st3', 'cse', 2018);
CALL create_student('st4', 'cse', 2018);
CALL create_student('st5', 'cse', 2019);
CALL create_student('st6', 'cse', 2019);
CALL create_student('st7', 'ece', 2019);
CALL create_student('st8', 'ece', 2019);
CALL create_student('st9', 'ece', 2019);
CALL create_student('st10', 'ece', 2018);
CALL create_student('st11', 'ece', 2018);



CREATE TABLE course_catalogue (
	course_id serial PRIMARY KEY,
	course_name VARCHAR(255) NOT NULL,
	L INTEGER NOT NULL,
	T INTEGER NOT NULL,
	P INTEGER NOT NULL,
	S INTEGER NOT NULL,
	credits INTEGER NOT NULL
 );
 
 GRANT ALL
 ON course_catalogue
 TO dean;

 GRANT SELECT
 ON course_catalogue
 TO PUBLIC;

 GRANT SELECT
 ON course_catalogue
 TO gp_students, gp_instructors, gp_advisors;

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
       FROM course_catalogue
       WHERE course_catalogue.course_name = _course_name;
       if course_already_registered = 0 THEN
          INSERT INTO course_catalogue(course_name, L, T, P, S, credits)
          VALUES (_course_name, _L, _T, _P, _S, _C);
       end if;
    end; $$;

CALL register_course('course1', 2, 2, 2, 2, 1);
CALL register_course('course2', 2, 2, 2, 2, 3);
CALL register_course('course3', 2, 2, 2, 2, 3);
CALL register_course('course4', 2, 2, 2, 2, 3);
CALL register_course('course5', 2, 2, 2, 2, 3);
CALL register_course('course6', 2, 2, 2, 2, 3);
CALL register_course('course7', 2, 2, 2, 2, 7);
CALL register_course('course8', 2, 2, 2, 2, 1);

CREATE TABLE prerequisite(
         course_id INTEGER,
         prerequisite_id INTEGER,
         PRIMARY KEY(course_id, prerequisite_id),
         FOREIGN KEY(course_id) REFERENCES course_catalogue(course_id),
         FOREIGN KEY(prerequisite_id) REFERENCES course_catalogue(course_id)
);

GRANT ALL
ON prerequisite
TO dean;

GRANT SELECT
ON prerequisite
TO gp_students, gp_instructors, gp_advisors;

create or replace procedure add_prerequisite(
               _course_id int,
	           _prerequisite_id int
    )
    language plpgsql
    as $$
    BEGIN
          INSERT INTO prerequisite(course_id, prerequisite_id)
          VALUES (_course_id, _prerequisite_id);
    end; $$;

CALL add_prerequisite(6, 5);
CALL add_prerequisite(6, 4);
CALL add_prerequisite(3,2);


CREATE TABLE slots(
        slot INTEGER PRIMARY KEY              
);

GRANT ALL
ON slots
TO dean;

GRANT SELECT
ON slots
TO PUBLIC;

GRANT SELECT
ON slots
TO gp_students, gp_instructors, gp_advisors;

CREATE OR REPLACE PROCEDURE add_slot(
        _slot INT
    )
    language  plpgsql
    as $$
    begin
        INSERT INTO slots(slot) VALUES (_slot);
    end;$$;

CALL add_slot(1);
CALL add_slot(2);
CALL add_slot(3);
CALL add_slot(4);
CALL add_slot(5);
CALL add_slot(6);

CREATE TABLE instructors(
    instructor_id serial PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department VARCHAR(255) NOT NULL
);

GRANT ALL
ON instructors
TO dean;

GRANT SELECT
ON instructors
TO gp_students, gp_instructors, gp_advisors;

create or replace function new_instructor_table()
returns trigger
language plpgsql
as $$
declare
      table_name varchar(255) := 'ins_' || NEW.instructor_id;
      query text;
begin 
    EXECUTE format('CREATE TABLE %I (ticket_id INTEGER PRIMARY KEY, offerring_id INTEGER, student_id INTEGER, instructor_approval boolean);', 'instructor_tickets_' || NEW.instructor_id);
    query := format('CREATE ROLE %I LOGIN PASSWORD ''ins'';',  'ins' || NEW.instructor_id);
    RAISE NOTICE 'query = %', query; 
    IF NOT EXISTS (SELECT * FROM pg_user WHERE usename = 'ins' || NEW.instructor_id) then
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''ins'';',  'ins' || NEW.instructor_id);
    end if;
    RAISE notice 'instructor_ticket_id on insert = %', NEW.instructor_id;
    EXECUTE format('ALTER GROUP gp_instructors ADD USER %I;', 'ins' || NEW.instructor_id);
    
    EXECUTE format('GRANT SELECT ON %I TO gp_students, gp_instructors, gp_advisors;', 'instructor_tickets_' || NEW.instructor_id);
    EXECUTE format('GRANT ALL ON %I TO dean;', 'instructor_tickets_' || NEW.instructor_id, 'ins' || NEW.instructor_id);
    return NEW;        
end; $$;

CREATE TRIGGER new_instructor_table
BEFORE INSERT 
ON instructors
FOR EACH ROW
EXECUTE PROCEDURE new_instructor_table();

create or replace procedure register_instructor(
               _instructor_name VARCHAR(255),
	           _department VARCHAR(255)
    )
    language plpgsql
    as $$
    BEGIN
          INSERT INTO instructors(name, department)
          VALUES (_instructor_name, _department);
    
    end; $$;

CALL register_instructor('ins1','cse');
CALL register_instructor('ins2','cse');
CALL register_instructor('ins3','ece');
CALL register_instructor('ins4','ece');
CALL register_instructor('ins5','mech');


CREATE TABLE batch_advisors(
    advisor_id serial PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    year INTEGER NOT NULL,
    department VARCHAR(255) NOT NULL
);

GRANT ALL
ON batch_advisors 
TO dean;

GRANT SELECT
ON batch_advisors
TO gp_students, gp_instructors, gp_advisors;

create or replace function new_advisor_table()
returns trigger
language plpgsql
as $$
declare
      table_name varchar(255) := 'adv_' || NEW.advisor_id;
      query text;
begin 
    EXECUTE format('CREATE TABLE %I (ticket_id INTEGER PRIMARY KEY, offerring_id INTEGER, student_id INTEGER, advisor_approval boolean);', 'advisor_tickets_' || NEW.advisor_id);
    query := format('CREATE ROLE %I LOGIN PASSWORD ''ba'';',  'ba' || NEW.advisor_id);
    RAISE NOTICE 'query = %', query; 
    IF NOT EXISTS (SELECT * FROM pg_user WHERE usename = 'ba' || NEW.advisor_id) then
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''ba'';',  'ba' || NEW.advisor_id);
    end if;
    RAISE notice 'advisor_ticket_id on insert = %', NEW.advisor_id;
    EXECUTE format('ALTER GROUP gp_advisors ADD USER %I;', 'ba' || NEW.advisor_id);
    
    EXECUTE format('GRANT SELECT ON %I TO %I, gp_instructors, gp_advisors, gp_students;', 'advisor_tickets_' || NEW.advisor_id, 'ba' || NEW.advisor_id);
    EXECUTE format('GRANT ALL ON %I TO dean;', 'advisor_tickets_' || NEW.advisor_id, 'ba' || NEW.advisor_id);
    return NEW;        
end; $$;

CREATE TRIGGER new_advisor_table
BEFORE INSERT 
ON batch_advisors
FOR EACH ROW
EXECUTE PROCEDURE new_advisor_table();

create or replace procedure register_advisor(
               _advisor_name VARCHAR(255),
               _year INT,
	           _department VARCHAR(255)
    )
    language plpgsql
    as $$
    BEGIN
          INSERT INTO batch_advisors(name, year, department)
          VALUES (_advisor_name, _year, _department);
    
    end; $$;

CALL register_advisor('adv1',2017, 'cse');
CALL register_advisor('adv2',2018, 'cse');
CALL register_advisor('adv3',2019, 'cse');
CALL register_advisor('adv4',2017, 'ece');
CALL register_advisor('adv5',2019, 'ece');
CALL register_advisor('adv6',2018, 'ece');
CALL register_advisor('adv7',2017, 'mech');
CALL register_advisor('adv8',2018, 'mech');
CALL register_advisor('adv9',2019, 'mech');


------------------------

CREATE TABLE offerings(
    offering_id INTEGER PRIMARY KEY,
    instructor_id INTEGER,
    course_id INTEGER, 
    year  INTEGER,
    semester INTEGER,
    slot   INTEGER, 		
    cgpa FLOAT,
    FOREIGN KEY(instructor_id) REFERENCES instructors(instructor_id),
    FOREIGN KEY(course_id) REFERENCES course_catalogue(course_id),
    FOREIGN KEY(slot) REFERENCES slots(slot),
    UNIQUE (instructor_id, course_id, year, semester, slot, cgpa)
);

GRANT ALL
ON offerings
TO dean;

GRANT ALL 
ON offerings
TO gp_instructors,gp_advisors;

GRANT SELECT
ON offerings
TO gp_students;


CREATE TABLE offering_batches(
    offering_id INTEGER,
    department VARCHAR(255) NOT NULL,
    year INTEGER NOT NULL,
    PRIMARY KEY (offering_id, department, year),
    FOREIGN KEY(offering_id) REFERENCES offerings(offering_id)
);

GRANT ALL
ON offering_batches
TO dean;

GRANT ALL 
ON offering_batches
TO gp_instructors,gp_advisors;

GRANT SELECT
ON offering_batches
TO gp_students;

create or replace procedure instructor_creates_offering(
        _instructor_id integer, 
        _course_id integer,  
        _year integer, 
        _semester integer,
        _slot integer,
        _cgpa float)

language  plpgsql
as $$
declare
    offering_id_created integer;
    num_entrys integer;
begin
    -- insert into offerings
    SELECT MAX(offering_id)
    INTO offering_id_created
    FROM offerings o;

    SELECT count(*)
    INTO num_entrys
    FROM offerings o;

    if num_entrys = 0 then
        offering_id_created := 0;
    end if;

    offering_id_created := offering_id_created + 1;

    INSERT INTO offerings(offering_id, instructor_id, course_id, year, semester, slot, cgpa)
    VALUES (offering_id_created, _instructor_id, _course_id, _year, _semester, _slot, _cgpa);

    raise notice 'offering_id created = %', offering_id_created;
    raise notice 'now insert batches for this offering';

    -- create separate offerings_{o}
    EXECUTE format('CREATE TABLE %I (student_id INTEGER PRIMARY KEY, grade INTEGER);', 'offering_' || offering_id_created);
    EXECUTE format('GRANT ALL ON %I TO %I;', 'offering_' || offering_id_created, 'ins' || _instructor_id);
    EXECUTE format('GRANT ALL ON %I TO dean;', 'offering_' || offering_id_created);
                
end; $$;

create or replace procedure instructor_creates_offering_batches(
        _offering_id integer,
        _department VARCHAR(255),
        _year integer 
        )
language  plpgsql
as $$
begin
    INSERT INTO offering_batches(offering_id, department, year)
    VALUES (_offering_id, _department, _year);                  
end; $$;

-- PAUSE 1: switch login
/*

-------------------------------------------------------------
-- LOGIN ins1 pass:ins
-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(1, 1, 2021,1,1,7.5);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(1, 'cse', 2019);
-- LOGOUT ins1 pass:ins
-------------------------------------------------------------

-------------------------------------------------------------
-- LOGIN ins2 pass:ins
-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(2, 2, 2021,1,1,6);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(2, 'cse', 2019);
call instructor_creates_offering_batches(2, 'cse', 2018);


-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(2, 3, 2021,1,2,7);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(3, 'cse', 2019);
call instructor_creates_offering_batches(3, 'cse', 2018);

-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(2, 2, 2020,1,1,7);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(4, 'cse', 2019);
call instructor_creates_offering_batches(4, 'cse', 2018);

-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(2, 5, 2021,1,3,9);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(5, 'cse', 2019);
call instructor_creates_offering_batches(5, 'cse', 2018);


-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(2, 5, 2021,2,1,4);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(6, 'cse', 2019);
call instructor_creates_offering_batches(6, 'cse', 2018);

-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(2, 7, 2020,2,1,4);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(7, 'cse', 2019);
call instructor_creates_offering_batches(7, 'cse', 2018);

-- LOGOUT ins2 pass:ins
-------------------------------------------------------------

- LOGIN admin
insert into transcript_4 values(4, 8);

*/

create or replace function fetch_offering_student(
        _current_year integer,
        _current_semester integer,
        _student_id integer
    )
returns table(
        offering_id integer, 
        course_name VARCHAR,
        ins_name VARCHAR
) as $$
begin
    return query
    SELECT o.offering_id, c.course_name, i.name
    FROM offerings o, course_catalogue c, instructors i, offering_batches ob, students s
    WHERE s.student_id = _student_id
        AND o.year = _current_year
        AND o.semester = _current_semester
        AND o.offering_id = ob.offering_id
        AND ob.department = s.department
        AND ob.year = s.year
        AND o.course_id = c.course_id
        AND o.instructor_id = i.instructor_id;  
end; $$ language  plpgsql;

-- select * from fetch_offering_student(2021, 1, 1);


CREATE TABLE registrations(    
    offering_id INTEGER,
    student_id INTEGER,
    PRIMARY KEY (offering_id, student_id),
    FOREIGN KEY(offering_id) REFERENCES offerings(offering_id),
    FOREIGN KEY(student_id) REFERENCES students(student_id)
);

GRANT ALL
ON registrations
TO dean;

GRANT ALL
ON registrations
TO gp_students, gp_instructors, gp_advisors;


create or replace function check_slot_before_registration(
)
returns trigger
language plpgsql
as $$
declare
        clash_present integer := 0;
        current_course_year integer;
        current_course_semester integer;
        current_course_slot integer;

begin
        select o.year, o.semester, o.slot
        into current_course_year, current_course_semester, current_course_slot
        from offerings o
        where o.offering_id = NEW.offering_id;

        raise notice '% % %', current_course_year, current_course_semester, current_course_slot;

        SELECT COUNT(*)
        INTO clash_present
        FROM registrations r, offerings o
        WHERE  r.student_id = NEW.student_id
            AND r.offering_id = o.offering_id
            AND o.year = current_course_year
            AND o.semester = current_course_semester
            AND o.slot = current_course_slot;
        
        if clash_present >= 1 then
                RAISE EXCEPTION 'same student cannot have two courses with same slot in the same semester';
        elsif clash_present = 0 then
                RAISE notice 'NO SLOT CLASH PRESENT';
                return NEW;        
        end if;          
end; $$;

CREATE TRIGGER trigger_check_slot_before_registration
BEFORE INSERT OR UPDATE 
ON registrations
FOR EACH ROW
EXECUTE PROCEDURE check_slot_before_registration();

-- trigger for batch check
create or replace function check_batch_before_registration(
)
returns trigger
language plpgsql
as $$
declare
        student_year integer;
        student_department VARCHAR;
        batch_exists integer;

begin
        select year, department
        into student_year, student_department
        from students s
        where s.student_id = NEW.student_id;

        raise notice 'student_year = % student_department = %', student_year, student_department;

        select count(*)
        into batch_exists
        from offering_batches ob
        where ob.offering_id = NEW.offering_id
            AND ob.department = student_department
            AND ob.year = student_year;       
        
        if batch_exists = 0 then
                RAISE EXCEPTION 'students batch not eligible for registering in this offering';
        elsif batch_exists >= 1 then
                raise notice 'student belongs to a valid batch';
                return NEW;        
        end if;          
end; $$;

CREATE TRIGGER trigger_check_batch_before_registration
BEFORE INSERT OR UPDATE 
ON registrations
FOR EACH ROW
EXECUTE PROCEDURE check_batch_before_registration();


-- check for prerequisite
create or replace function check_prerequisite_before_registration(
)
returns trigger
language plpgsql
as $$
declare
    current_course_id integer;
    all_prerequisite_satisfied integer := 1;
    current_prerequisite_satisfied integer;
    cur refcursor;
    rec record;
    rec1 record;
    current_prerequisite_id integer;
    minimum_pass_grade integer = 4;
begin
        select o.course_id
        into current_course_id
        from offerings o
        where o.offering_id = NEW.offering_id;

        open cur for 
        select prerequisite_id
        from prerequisite
        where course_id = current_course_id;

        loop
            fetch cur into rec;
            exit when not found;
            current_prerequisite_id := rec.prerequisite_id;

            /*select count(*)
            into current_prerequisite_satisfied
            from transcript_{student_id} t, offerings o
            where t.offering_id = o.offering_id
                  AND o.course_id = rec.prerequisite_id;*/

            EXECUTE format('select count(*) from %I t, offerings o '
            'where t.offerring_id = o.offering_id AND o.course_id = $1 AND t.grade > $2', 'transcript_' || NEW.student_id)
            INTO current_prerequisite_satisfied
            USING rec.prerequisite_id, minimum_pass_grade;

            /*current_prerequisite_satisfied := 0;
            for rec1 in execute format('select * from %I t, offerings o where t.offerring_id = o.offering_id AND o.course_id = %I;', 'transcript_' || NEW.student_id, current_prerequisite_id) 
            loop
                current_prerequisite_satisfied := current_prerequisite_satisfied + 1;
            end loop;*/
            
            
            if current_prerequisite_satisfied = 0 then
                all_prerequisite_satisfied := 0;
            end if;            
        end loop;

        if all_prerequisite_satisfied = 0 then
            RAISE EXCEPTION '****** all prerequisites not satisfied for this course ******';
        elsif all_prerequisite_satisfied = 1 then
            RAISE NOTICE 'ALL PREREQUISITES ARE SATISFIED';
            return NEW;
        end if;                      
end; $$;

CREATE TRIGGER trigger_check_prerequisite_before_registration
BEFORE INSERT OR UPDATE 
ON registrations
FOR EACH ROW
EXECUTE PROCEDURE check_prerequisite_before_registration();


-- check cgpa
create or replace function check_cgpa_before_registration(
)
returns trigger
language plpgsql
as $$
declare
    cgpa_requirement integer;
    total_grade_points_earned integer := 0;
    total_credits_earned integer := 0;
    current_cgpa integer := 0;
    current_course_credits integer;
    cur refcursor;
    rec record;
    minimum_pass_grade integer = 4;
    _year integer;
    _semester integer;
    _batch_year integer;
begin
        SELECT o.cgpa, o.year, o.semester
        INTO cgpa_requirement, _year, _semester
        FROM offerings o
        WHERE o.offering_id = NEW.offering_id;

        /*execute format('open cur for '
                       'select * '
                       'from %I;', 'transcript_' || NEW.student_id);*/
        /*open cur for
        select *
        from transcript_7;*/

        for rec in execute format('select * '
                                  'from %I;', 'transcript_' || NEW.student_id)
        loop
            --fetch cur into rec;
            --exit when not found;
            -- if rec.grade > minimum_pass_grade then
                SELECT c.credits
                INTO current_course_credits
                FROM course_catalogue c, offerings o
                WHERE o.offering_id = rec.offerring_id
                    AND c.course_id = o.course_id;

                total_grade_points_earned := total_grade_points_earned + (current_course_credits * rec.grade);
                total_credits_earned := total_credits_earned + current_course_credits;
            --end if;
        end loop;

        select year
        into _batch_year
        from students
        WHERE students.student_id = NEW.student_id;

        

        if _year = _batch_year and _semester = 1 then
            raise notice 'student is in first year first semester so cgpa is not considered';
            current_cgpa := 10;        
        elsif total_credits_earned = 0 then
            raise NOTICE 'since credits earned in previous two semesters is zero cgpa check not applied';
            current_cgpa := 10;
        else
            raise notice 'student cgpa is considered';
            current_cgpa := total_grade_points_earned / total_credits_earned;
        end if;

        
        if current_cgpa < cgpa_requirement then
             RAISE EXCEPTION '****** student cgpa = % but cgpa requirement = %. student not eligible******', current_cgpa, cgpa_requirement;
        else
            RAISE NOTICE 'CGPA CRITERIA IS SATISFIED';
            return NEW;
        end if;                      
end; $$;

CREATE TRIGGER trigger_check_cgpa_before_registration
BEFORE INSERT OR UPDATE 
ON registrations
FOR EACH ROW
EXECUTE PROCEDURE check_cgpa_before_registration();


----------------

CREATE TABLE Tickets_global(
               ticket_id serial PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	           student_id INTEGER NOT NULL,
               FOREIGN KEY (student_id) REFERENCES students (student_id),
               FOREIGN KEY (offering_id) REFERENCES offerings (offering_id)

               
);

CREATE TABLE dean_tickets(
               ticket_id serial PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	           student_id INTEGER NOT NULL,
               dean_verdict boolean

);

GRANT ALL ON Tickets_global 
TO dean, gp_instructors, gp_students, gp_advisors;


create or replace procedure register_student(
        _offering_id int,
        _student_id int            
)
language  plpgsql
as $$
declare 
    _year integer;
    _semester integer;
    credits_1     float;
    credits_2     float;
    avg_credits     float;
    current_course_credits integer;
    current_total_credits integer;
    _batch_year integer; 
    _found integer;   
begin
    -- calculate the 1.25 * average of credits of previouse two semesters
    SELECT c.credits, o.year, o.semester
    INTO current_course_credits, _year, _semester 
    FROM course_catalogue c, offerings o
    WHERE o.offering_id = _offering_id
        AND c.course_id = o.course_id;      

    SELECT sum(c.credits), count(*)
    INTO current_total_credits, _found
    FROM registrations r, offerings o, course_catalogue c
    WHERE   r.student_id = _student_id
            AND r.offering_id = o.offering_id
            AND o.year = _year
            AND o.semester = _semester
            AND c.course_id = o.course_id;
    
    if _found  = 0 then
        current_total_credits := 0;
    end if;
    
    SELECT sum(c.credits), count(*)
    INTO credits_1, _found
    FROM registrations r, offerings o, course_catalogue c
    WHERE   r.student_id = _student_id
            AND r.offering_id = o.offering_id
            AND o.year = _year - 1
            AND o.semester = 2
            AND c.course_id = o.course_id;
    if _found = 0 then
        credits_1 := 0;
    end if;
    
    if _semester = 2 then
            SELECT sum(credits), count(*)
            INTO credits_2, _found
            FROM registrations r, offerings o, course_catalogue c
            WHERE   r.student_id = _student_id
                    AND r.offering_id = o.offering_id
                    AND o.year = _year
                    AND o.semester = 1
                    AND c.course_id = o.course_id;
            if _found = 0 then
                credits_2 := 0;
            end if;
    elsif _semester = 1 then
            SELECT sum(credits), count(*)
            INTO credits_2, _found
            FROM registrations r, offerings o, course_catalogue c
            WHERE   r.student_id = _student_id
                    AND r.offering_id = o.offering_id
                    AND o.year = _year - 1
                    AND o.semester = 1
                    AND c.course_id = o.course_id;
            if _found = 0 then
                credits_2 := 0;
            end if;           
    end if;

    select year
    into _batch_year
    from students
    WHERE students.student_id = _student_id;

    if _year = _batch_year and _semester = 1 then
        raise notice 'student is in first year first semester so avg_credits is not considered';
        avg_credits = 1000000;
    elsif _year = _batch_year and _semester = 2 then
        raise notice 'student is in first year second semester so avg_credits is first semester credits';
        avg_credits = credits_2;
    else
        raise notice 'student is in second year or more so avg_credits is avg of previouse two semesters';
        avg_credits := (credits_1 + credits_2)/2;
    end if;

    --raise notice 'current_total_credits = % + current_course_credits = % <= 1.25 * avg_credits = %', current_total_credits, current_course_credits,  1.25 * avg_credits;
    if avg_credits = 0 then
        raise notice 'no courses taken in the previouse two semesters thus credit limit not applies';
        avg_credits = 1000000;
    end if;

    if current_total_credits + current_course_credits <= 1.25 * avg_credits then
            raise notice 'student satisfying 1.25 limit'; 
            INSERT INTO registrations(offering_id, student_id)
            VALUES (_offering_id, _student_id);
    else
            raise notice 'credit limit exceeded, ticket raised';
            -- TODO:
            --INSERT INTO Tickets_global(offering_id, student_id) 
            --VALUES (_offering_id, _student_id);
    end if;                    
end; $$;

/*

PAUSE 2:

-------------------------------------------------------------------------
-- LOGIN st5, pass = st
-- off_id, student_id
-- check for slot and batch
call register_student(1,5);

 -- check for slot clash and it failss
call register_student(2,5);

 -- check for prerequisite which will fail because course 3 has prerequisite 2 
 -- for which student 5 is not registerd
 call register_student(3,5);

-- check for credit limit which is exceeded
-- offering 6 is of sem 2 and has 3 credits
-- in semester 1 student has registered for offering 1 which is a one credit course
call register_student(6,5);

-- registering in offering 7 with 7 credits 
-- to test the above condition again
call register_student(7,5);

-- run again to test, now it passes the credit limit test
 
------------------------------------------------------------------------
--ADMIN
insert into transcript_5 values(1,2);
insert into transcript_5 values(7,2);
------------------------------------------------------------------------
--LOGIN st5
-- cgpa criteria not met
call register_student(6,5);
-- LOGOUT st5
-------------------------------------------------------------------------
--ADMIN
update transcript_5 t set grade = 8 where t.offerring_id = 1;
update transcript_5 t set grade = 8 where t.offerring_id = 7;
------------------------------------------------------------------------
--LOGIN st5
-- cgpa criteria met now
call register_student(6,5);
-- LOGOUT st5
-------------------------------------------------------------------------
--ADMIN
delete from transcript_5;
delete from transcript_4;
-------------------------------------------------------------------------



-- LOGIN st4, pass = st
-- off_id, student_id

-- check batch, fails because batch not allowed
call register_student(1,4);

-- check batch, passes because batch allowed
call register_student(2,4);

-- LOGOUT st4
-------------------------------------------------------------
*/

-- upload offerings grade
create or replace procedure instructor_uploads_grades(
    _offering_id integer
)
language  plpgsql
SECURITY DEFINER
as $$
begin
execute format('COPY %I '
               'FROM ''D:\Uday\github_repos\cs301_project\grades.csv'' '
               'DELIMITER '','' CSV HEADER;', 'offering_' || _offering_id);
end; $$;

REVOKE EXECUTE ON PROCEDURE instructor_uploads_grades FROM gp_students;
GRANT EXECUTE ON PROCEDURE instructor_uploads_grades TO gp_instructors;

-- dean approves grades of the offering and writes them to the trasncript 
-- tables of the student

create or replace procedure dean_approves_grades_transcript(
    _offering_id integer
)
language  plpgsql
as $$
declare
    rec record;
begin
    for rec in execute format('select * '
                              'from %I;', 'offering_' || _offering_id)
    loop
        --execute format('insert into %I values($1, $2)', 'transcript_' || rec.student_id)
        --using _offering_id, rec.grade;
        execute format('insert into %I values($1, $2) on conflict(offerring_id) do update set grade = excluded.grade', 'transcript_' || rec.student_id)
        using _offering_id, rec.grade;
    end loop;
end; $$;
REVOKE EXECUTE ON PROCEDURE dean_approves_grades_transcript FROM gp_students;
REVOKE EXECUTE ON PROCEDURE dean_approves_grades_transcript FROM gp_instructors;
GRANT EXECUTE ON PROCEDURE dean_approves_grades_transcript TO dean;

/*

PAUSE 3:
-- LOGIN ins1 pass:ins
-- ins_id, course_id, year, sem, slot, cgpa 
call instructor_creates_offering(1, 8, 2021,2,6,7.5);   
-- offering_id. b_dep, b_year
call instructor_creates_offering_batches(8, 'cse', 2019);
call instructor_creates_offering_batches(8, 'cse', 2018);
-- LOGOUT ins1 pass:ins

-- LOGIN st4, pass = st
call register_student(8,4);
-- LOGOUT st4

-- LOGIN st5, pass = st
call register_student(8,5);
-- LOGOUT st5

-- LOGIN ins1 pass:ins
select * from offering_8;
call instructor_uploads_grades(8);
select * from offering_8;
-- LOGOUT ins1 pass:ins

-- LOGIN dean pass:dean
select * from transcript_4;
select * from transcript_5;
call dean_approves_grades_transcript(8);
select * from transcript_4;
select * from transcript_5;
-- LOGOUT dean pass:dean




*/
-------------------------------------------------------------

--------------tickets approvals ----------------





CREATE OR REPLACE PROCEDURE instructor_receives_tickets(
        ins_id integer          
    )
    language  plpgsql
    as $$
    declare
       TABLENAME varchar(255) := 'instructor_tickets_' || ins_id; 
    BEGIN
       INSERT INTO TABLENAME(ticket_id, offerring_id, student_id) 
       SELECT T.ticket_id, T.offering_id, T.student_id FROM Tickets_global AS T
       WHERE ins_id = T.instructor_id;

    -- DELETE FROM Tickets_global WHERE ticket_id in (SELECT ticket_id FROM TABLENAME);
    END; $$; 



create or replace function check_instructor_verdict()
returns trigger
language plpgsql
as $$
declare
      table_name varchar(255);
      ins_id varchar(255);
      decision boolean;
begin
        SELECT offerings.instructor_id 
        INTO ins_id 
        FROM offerings AS O, tickets_global AS T 
        WHERE O.offering_id = T.offering_id AND O.student_id = T.student_id;

        table_name := 'instructor_tickets_' + ins_id;
        
        SELECT instructor_approval
        INTO decision 
        FROM table_name
        WHERE table_name.ticket_id = new.ticket_id;
 
        if decision<>null THEN        
            return new;
        end if;
end; $$;



CREATE OR REPLACE PROCEDURE advisor_receives_tickets(
        advisor_id integer          
    )
    language  plpgsql
    as $$
    declare
       TABLENAME varchar(255) := 'advisor_tickets_' || adv_id; 
       ins_table varchar(255);
       ins_id integer;
    BEGIN
       
       CREATE TRIGGER check_instructor_verdict
       BEFORE INSERT 
       ON TABLENAME
       FOR EACH ROW
       EXECUTE PROCEDURE check_instructor_verdict();

       INSERT INTO TABLENAME(ticket_id, offerring_id, student_id) 
       SELECT T.ticket_id, T.offering_id, T.student_id FROM Tickets_global AS T, Students AS S, batch_advisors AS B 
       WHERE advisor_id = B.advisor_id AND T.student_id = S.student_id AND B.department = S.department AND B.year = S.year;

    END; $$;


create or replace function check_advisor_verdict()
returns trigger
language plpgsql
as $$
declare
      table_name varchar(255);
      adv_id varchar(255);
      decision boolean;
begin
        SELECT batch_advisors.advisor_id 
        INTO adv_id 
        FROM offerings AS O, tickets_global AS T, batch_advisors AS B  
        WHERE O.offering_id = T.offering_id AND O.student_id = T.student_id AND O.department = B.department AND O.year = B.year;

        table_name := 'advisor_tickets_' + adv_id;
        
        SELECT advisor_approval
        INTO decision 
        FROM table_name
        WHERE table_name.ticket_id = new.ticket_id;
 
        if decision<>null THEN        
            return new;
        end if;
end; $$;



CREATE OR REPLACE PROCEDURE dean_receives_tickets(       
    )
    language  plpgsql
    as $$
    BEGIN
    
       CREATE TRIGGER check_advisor_verdict
       BEFORE INSERT 
       ON dean_tickets
       FOR EACH ROW
       EXECUTE PROCEDURE check_advisor_verdict();    
    

       INSERT INTO dean_tickets(ticket_id, offerring_id, student_id) 
       SELECT T.ticket_id, T.offering_id, T.student_id FROM Tickets_global;
       
       DELETE FROM Tickets_global WHERE ticket_id in (SELECT ticket_id FROM TABLENAME);
    END; $$;

CREATE OR REPLACE PROCEDURE instructor_decision(
      ins_id integer,
      ticket_id_value integer,
      decision boolean
    )     
    language plpgsql
    as $$
    declare 
       TABLENAME varchar(255) := 'instructor_tickets_' || ins_id; 
    BEGIN
       UPDATE TABLENAME set instructor_approval = decision WHERE ticket_id = ticket_id_value;
    END; $$;   

     
CREATE OR REPLACE PROCEDURE advisor_decision(
      adv_id integer,
      ticket_id_value integer,
      decision boolean
    )     
    language plpgsql
    as $$
    declare 
       TABLENAME varchar(255) := 'advisor_tickets_' || adv_id; 
    BEGIN
       UPDATE TABLENAME set advisor_approval = decision WHERE ticket_id = ticket_id_value;
    END; $$;   

CREATE OR REPLACE PROCEDURE dean_decision(
      ticket_id_value integer,
      decision boolean
    )     
    language plpgsql
    as $$
    BEGIN
       UPDATE dean_tickets set dean_approval = decision WHERE ticket_id = ticket_id_value;
    END; $$;   



create or replace function resolve_tickets()
returns trigger
language plpgsql
as $$
declare
      table_name varchar(255);
      adv_id varchar(255);
      decision boolean;
begin
        IF NEW.dean_approval = true then
            raise notice 'ticket approved';
            INSERT INTO registrations(offering_id, student_id)
            VALUES (_offering_id, _student_id);
        ELSE 
            raise notice 'ticket rejected';
        END IF;
        return NEW;

end; $$;

CREATE TRIGGER resolve_tickets
AFTER UPDATE
ON dean_tickets
FOR EACH ROW
EXECUTE PROCEDURE resolve_tickets(); 


create or replace function post_registration()
returns trigger 
language plpgsql
as $$
declare 
     offering_table varchar(255);
     grades_table varchar(255);
BEGIN
     offering_table := 'offering_' || NEW.offering_id;
     grades_table := 'transcript_' || NEW.student_id;

     INSERT INTO offering_table(student_id) VALUES(NEW.student_id);
     INSERT INTO grades_table(offering_id) VALUES(NEW.offering_id);

END; $$;

CREATE TRIGGER post_registration
AFTER INSERT 
ON registrations
FOR EACH ROW
EXECUTE PROCEDURE post_registration();


create or replace PROCEDURE return_gradesheet(
     student_id integer
)
language  plpgsql
AS $$
declare 
    table_name varchar(255) := 'transcript_' || NEW.student_id;
    student_name varchar(255);
    student_department varchar(255);
    student_year integer;
    cur1 refcursor;
    cur2 refcursor;
    rec1 record;
    rec2 record;
    current_semester integer;
    current_year integer;
    total_credits integer :=0;
    total_points integer :=0;
    cgpa integer :=0;
    sgpa integer :=0;
    credits_this_sem integer :=0;
    points_this_sem integer :=0;
    current_credit integer;
    current_grade integer;
    current_offering integer;
begin
    select student_name,department, year  
    INTO student_name, student_department, student_year
    from students AS S
    WHERE S.student_id = student_id;

    raise notice 'student name %',student_name ;
    raise notice 'department %',student_department;
    raise notice 'starting year %',student_year;
    raise notice '               ';
    raise notice '*********************';
    raise notice '               ';

        open cur1 for 
        select DISTINCT offerings.year, offerings.semester
        from offerings, table_name
        where offerings.offering_id = table_name.offering_id
        order by offerings.year, offerings.semester;

        loop
            fetch cur1 into rec1;
            exit when not found;
            current_semester := rec1.semester;
            current_year := rec1.year;
            
            raise notice 'current semester %',current_semester;
            raise notice 'current year %',current_year;
            raise notice '               ';

            open cur2 for 
            select T.offering_id, T.grade, C.credits
            FROM offerings AS O, table_name AS T, course_catalogues AS C
            WHERE O.semester = current_semester AND O.year = current_year AND O.offering_id = T.offering_id AND O.course_id = C.course_id;
               
            raise notice 'offering_id grade'; 
            raise notice '             ';
            credits_this_sem := 0;
            points_this_sem := 0;
            LOOP
                fetch cur2 into rec2;
                exit when not found;

                current_offering = rec2.offering_id;
                current_grade = rec2.grade;
                current_credit = rec2.credits;
                
                raise notice '% %',current_offering, current_grade;
                raise notice '            ';


                credits_this_sem := credits_this_sem + current_credit;
                points_this_sem := points_this_sem + current_credit*current_grade;

            end loop;

            sgpa := points_this_sem / credits_this_sem;
            total_points := total_points + points_this_sem;
            total_credits := total_credits + credits_this_sem;

            cgpa:= total_points / total_credits;

            raise notice 'sgpa %',sgpa;
            raise notice 'cgpa %',cgpa;
            raise notice '  ';
            raise notice '***************************';
            raise notice '         ';







        end loop;
    

END; $$;







