SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='course_catalogue';


===============
create database project3;
\c project3

create role dean
login
password 'dean';



CREATE GROUP gp_instructors;



CREATE GROUP gp_students;

CREATE GROUP gp_advisors;


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

create or replace procedure register_student(
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
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''st'';',  'st' || NEW.student_id);
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



CALL register_student('st1', 'mech', 2017);
CALL register_student('st2', 'mech', 2017);
CALL register_student('st3', 'cse', 2018);
CALL register_student('st4', 'cse', 2018);
CALL register_student('st5', 'cse', 2019);
CALL register_student('st6', 'cse', 2019);
CALL register_student('st7', 'ece', 2019);
CALL register_student('st8', 'ece', 2019);
CALL register_student('st9', 'ece', 2019);
CALL register_student('st10', 'ece', 2018);
CALL register_student('st11', 'ece', 2018);



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

CALL register_course('course1', 2, 2, 2, 2, 4);
CALL register_course('course2', 2, 2, 2, 2, 3);
CALL register_course('course3', 2, 2, 2, 2, 3);
CALL register_course('course4', 2, 2, 2, 2, 1);
CALL register_course('course5', 2, 2, 2, 2, 4);
CALL register_course('course6', 2, 2, 2, 2, 3);

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
TO PUBLIC;

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
TO PUBLIC;

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
    EXECUTE format('CREATE TABLE %I (ticket_id INTEGER PRIMARY KEY, offering_id INTEGER, student_id INTEGER, instructor_approval boolean);', 'instructor_tickets_' || NEW.instructor_id);
    query := format('CREATE ROLE %I LOGIN PASSWORD ''ins'';',  'ins' || NEW.instructor_id);
    RAISE NOTICE 'query = %', query; 
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''ins'';',  'ins' || NEW.instructor_id);
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
TO PUBLIC;

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
    EXECUTE format('CREATE TABLE %I (ticket_id INTEGER PRIMARY KEY, offering_id INTEGER, student_id INTEGER, advisor_approval boolean);', 'advisor_tickets_' || NEW.advisor_id);
    query := format('CREATE ROLE %I LOGIN PASSWORD ''ba'';',  'ba' || NEW.advisor_id);
    RAISE NOTICE 'query = %', query; 
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''ba'';',  'ba' || NEW.advisor_id);
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

GRANT SELECT
ON offerings
TO PUBLIC;

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

GRANT SELECT
ON offering_batches
TO PUBLIC;

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

-- the next call must be run under login of ins1
-- call instructor_creates_offering(1, 1, 2021,1,2,7.5);
-- call instructor_creates_offering_batches(1, 'cse', 2018);
-- call instructor_creates_offering_batches(1, 'cse', 2019);

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
        else
            raise notice 'student cgpa is considered';
            current_cgpa := total_grade_points_earned / total_credits_earned;
        end if;

        
        if current_cgpa < cgpa_requirement then
             RAISE EXCEPTION '****** student cgpa = % but cgpa requirement = %. student not eligible******', current_cgpa, cgpa_requirement;
        else
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
               ticket_id INTEGER PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	           student_id INTEGER NOT NULL,
               FOREIGN KEY (student_id) REFERENCES students (student_id),
               FOREIGN KEY (offering_id) REFERENCES offerings (offering_id)

               
);
/*
CREATE TRIGGER trigger_check_slot_before_registration
BEFORE INSERT OR UPDATE 
ON Tickets_global
FOR EACH ROW
EXECUTE PROCEDURE check_slot_before_registration();

CREATE TRIGGER trigger_check_batch_before_registration
BEFORE INSERT OR UPDATE 
ON Tickets_global
FOR EACH ROW
EXECUTE PROCEDURE check_batch_before_registration();

CREATE TRIGGER trigger_check_prerequisite_before_registration
BEFORE INSERT OR UPDATE 
ON Tickets_global
FOR EACH ROW
EXECUTE PROCEDURE check_prerequisite_before_registration();

CREATE TRIGGER trigger_check_cgpa_before_registration
BEFORE INSERT OR UPDATE 
ON Tickets_global
FOR EACH ROW
EXECUTE PROCEDURE check_cgpa_before_registration();
*/
CREATE TABLE dean_tickets(
               ticket_id serial PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	           student_id INTEGER NOT NULL,
               dean_verdict boolean

);

GRANT ALL PRIVILEGES ON Tickets_global 
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
    Ticket_id_created integer; 
    num_entrys integer;
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
    if current_total_credits + current_course_credits <= 1.25 * avg_credits then
            raise notice 'student satisfying 1.25 limit'; 
            INSERT INTO registrations(offering_id, student_id)
            VALUES (_offering_id, _student_id);
    else

            SELECT MAX(ticket_id)
            INTO ticket_id_created
            FROM Tickets_global T;

            SELECT count(*)
            INTO num_entrys
            FROM Tickets_global T;

            if num_entrys = 0 then
                ticket_id_created := 0;
            end if;

            ticket_id_created := ticket_id_created + 1;

            raise notice 'credit limit exceeded, ticket raised';
            INSERT INTO Tickets_global(ticket_id, offering_id, student_id) 
            VALUES (ticket_id_created, _offering_id, _student_id);
    end if;                    
end; $$;
--/////////////////


-- call register_student(1,1);
-- call register_student(2,1);

-- upload offerings grade
create or replace procedure instructor_uploads_grades(
    _offering_id integer
)
language  plpgsql
SECURITY DEFINER
as $$
begin
execute format('COPY %I '
               'FROM ''D:\grades.csv'' '
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

--------------tickets approvals ----------------





CREATE OR REPLACE PROCEDURE instructor_receives_tickets(
        ins_id integer          
    )
    language  plpgsql
    as $$
    declare
       TABLENAME varchar(255) := 'instructor_tickets_' || ins_id; 
    BEGIN
       execute 'INSERT INTO ' || 'instructor_tickets_' || ins_id || '(ticket_id, offering_id, student_id) 
       SELECT T.ticket_id, T.offering_id, T.student_id FROM Tickets_global AS T, Offerings AS O
       WHERE O.offering_id = T.offering_id AND O.instructor_id = '|| ins_id || ';';

    -- DELETE FROM Tickets_global WHERE ticket_id in (SELECT ticket_id FROM TABLENAME);
    END; $$; 



create or replace function check_instructor_verdict()
returns trigger
language plpgsql
as $$
declare
      ins_id integer;
      decision boolean;
begin
        SELECT O.instructor_id 
        INTO ins_id 
        FROM offerings AS O, tickets_global AS T
        WHERE O.offering_id = NEW.offering_id;
        
        execute 'SELECT instructor_approval 
        FROM ' || 'instructor_tickets_' || ins_id || ' AS T
        WHERE T.ticket_id = ' || new.ticket_id || ';'
        INTO decision;
        
        raise notice 'decision %', decision;

        if decision=null THEN        
            return null;
        ELSE
            return new;
        end if;
end; $$;



CREATE OR REPLACE PROCEDURE advisor_receives_tickets(
        advisor_id integer          
    )
    language  plpgsql
    as $$
    declare
       ins_table varchar(255);
       ins_id integer;
       ticket_id_ integer;
       offering_id_ integer;
       student_id_ integer;
    BEGIN
       
       execute 'DROP TRIGGER IF EXISTS check_instructor_verdict ON advisor_tickets_' || advisor_id || ';';
       execute 'CREATE TRIGGER check_instructor_verdict
       BEFORE INSERT 
       ON ' || 'advisor_tickets_' || advisor_id || ' 
       FOR EACH ROW
       EXECUTE PROCEDURE check_instructor_verdict();';
       student_id_ := advisor_id;

       
              execute 'INSERT INTO advisor_tickets_' || advisor_id || '(ticket_id, offering_id, student_id)
       SELECT T.ticket_id, T.offering_id, T.student_id FROM Tickets_global AS T,  Students AS S, batch_advisors AS B
       WHERE T.student_id = S.student_id AND B.department = S.department AND B.year = S.year AND B.advisor_id = '|| advisor_id || ';';
            



    END; $$;


create or replace function check_advisor_verdict()
returns trigger
language plpgsql
as $$
declare
      table_name varchar(255);
      adv_id integer;
      decision boolean;
      new_ticket_id integer;
begin
        SELECT B.advisor_id 
        INTO adv_id 
        FROM students AS S, tickets_global AS T, batch_advisors AS B  
        WHERE NEW.student_id = S.student_id AND S.department = B.department AND S.year = B.year;

        table_name := 'advisor_tickets_' || adv_id;
        new_ticket_id := new.ticket_id;

        EXECUTE FORMAT('SELECT advisor_approval
        FROM %I
        WHERE %I.ticket_id = %L;', table_name, table_name, new_ticket_id)
        INTO decision; 
 
        if decision=null THEN   
            return null;
        else      
            return new;
        end if;
end; $$;


CREATE TRIGGER check_advisor_verdict
BEFORE INSERT 
ON dean_tickets
FOR EACH ROW
EXECUTE PROCEDURE check_advisor_verdict();    

CREATE OR REPLACE PROCEDURE dean_receives_tickets(       
    )
    language  plpgsql
    as $$
    BEGIN
    

    

       INSERT INTO dean_tickets(ticket_id, offering_id, student_id) 
       SELECT T.ticket_id, T.offering_id, T.student_id FROM Tickets_global AS T;
       

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
       EXECUTE FORMAT('UPDATE %I set instructor_approval = %L WHERE ticket_id = %L;', TABLENAME, decision, ticket_id_value);
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
       EXECUTE FORMAT('UPDATE %I set advisor_approval = %L WHERE ticket_id = %L;', TABLENAME, decision, ticket_id_value);
    END; $$;   

CREATE OR REPLACE PROCEDURE dean_decision(
      ticket_id_value integer,
      decision boolean
    )     
    language plpgsql
    as $$
    BEGIN
       UPDATE dean_tickets set dean_verdict = decision WHERE ticket_id = ticket_id_value;
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
        IF NEW.dean_verdict = true then
            raise notice 'ticket approved';
            INSERT INTO registrations(offering_id, student_id)
            VALUES (new.offering_id, new.student_id);
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

     EXECUTE 'INSERT INTO ' || offering_table || '(student_id) VALUES(' || NEW.student_id || ');';
     EXECUTE 'INSERT INTO ' || grades_table || '(offering_id) VALUES(' || NEW.offering_id || ');';

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

        EXECUTE FORMAT('open %I for 
        select DISTINCT offerings.year, offerings.semester
        from offerings, %I AS T
        where offerings.offering_id = T.offering_id
        order by offerings.year, offerings.semester;', cur1,table_name);

        loop
            fetch cur1 into rec1;
            exit when not found;
            current_semester := rec1.semester;
            current_year := rec1.year;
            
            raise notice 'current semester %',current_semester;
            raise notice 'current year %',current_year;
            raise notice '               ';

            EXECUTE FORMAT(open cur2 for 
            select T.offering_id, T.grade, C.credits
            FROM offerings AS O, %I AS T, course_catalogues AS C
            WHERE O.semester = current_semester AND O.year = current_year AND O.offering_id = T.offering_id AND O.course_id = C.course_id;,
            table_name, current_semester, current_year);
               
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







