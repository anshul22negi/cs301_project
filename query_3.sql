SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='course_catalogue';


===============
create database project3;
\c project3

create role dean
login
password 'dean';

create role ba1
login
password 'ba1';

create role ba2
login
password 'ba2';

CREATE GROUP gp_instructors;

create role ins1
login
password 'ins1';

create role ins2
login
password 'ins2';

create role ins3
login
password 'ins3';

create role ins4
login
password 'ins4';

create role ins5
login
password 'ins5';

CREATE GROUP gp_students;


CREATE TABLE students (
    student_id serial PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL
);

GRANT ALL 
ON students 
TO dean;

GRANT SELECT
ON students
TO gp_students, gp_instructors;

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
    
    EXECUTE format('GRANT SELECT ON %I TO %I;', 'transcript_' || NEW.student_id, 'st' || NEW.student_id);
    EXECUTE format('GRANT ALL ON %I TO dean;', 'transcript_' || NEW.student_id, 'st' || NEW.student_id);
    return NEW;        
end; $$;

CREATE TRIGGER trigger_create_student_transcript_table
BEFORE INSERT 
ON students
FOR EACH ROW
EXECUTE PROCEDURE create_student_transcript_table();

INSERT INTO students(name, department, year) VALUES ('st1','mech',2017);
INSERT INTO students(name, department, year) VALUES ('st2','mech',2017);
INSERT INTO students(name, department, year) VALUES ('st3','cse',2018);
INSERT INTO students(name, department, year) VALUES ('st4','cse',2018);
INSERT INTO students(name, department, year) VALUES ('st5','cse',2019);
INSERT INTO students(name, department, year) VALUES ('st6','cse',2019);
INSERT INTO students(name, department, year) VALUES ('st7','ece',2019);
INSERT INTO students(name, department, year) VALUES ('st8','ece',2019);
INSERT INTO students(name, department, year) VALUES ('st9','ece',2019);
INSERT INTO students(name, department, year) VALUES ('st10','ece',2018);
INSERT INTO students(name, department, year) VALUES ('st11','ece',2018);


CREATE TABLE course_catalogue (
	course_id serial PRIMARY KEY,
	course_name VARCHAR(50) NOT NULL,
	L INTEGER NOT NULL,
	T INTEGER NOT NULL,
	P INTEGER NOT NULL,
	S INTEGER NOT NULL,
	credits INTEGER NOT NU+LL
 );
 
 GRANT ALL
 ON course_catalogue
 TO dean;

 GRANT SELECT
 ON course_catalogue
 TO PUBLIC;

 GRANT SELECT
 ON course_catalogue
 TO gp_students, gp_instructors;

 INSERT INTO course_catalogue(course_name, L, T, P, S, credits) VALUES ('course1', 2,2,2,2,4);
 INSERT INTO course_catalogue(course_name, L, T, P, S, credits) VALUES ('course2', 2,2,2,2,3);
 INSERT INTO course_catalogue(course_name, L, T, P, S, credits) VALUES ('course3', 2,2,2,2,3);
 INSERT INTO course_catalogue(course_name, L, T, P, S, credits) VALUES ('course4', 2,2,2,2,1);
 INSERT INTO course_catalogue(course_name, L, T, P, S, credits) VALUES ('course5', 2,2,2,2,4);
 INSERT INTO course_catalogue(course_name, L, T, P, S, credits) VALUES ('course6', 2,2,2,2,3);

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
TO gp_students, gp_instructors;

INSERT INTO prerequisite(course_id, prerequisite_id) VALUES (6,5);
INSERT INTO prerequisite(course_id, prerequisite_id) VALUES (6,4);
INSERT INTO prerequisite(course_id, prerequisite_id) VALUES (3,2);


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
TO gp_students, gp_instructors;

INSERT INTO slots(slot) VALUES (1);
INSERT INTO slots(slot) VALUES (2);
INSERT INTO slots(slot) VALUES (3);
INSERT INTO slots(slot) VALUES (4);
INSERT INTO slots(slot) VALUES (5);
INSERT INTO slots(slot) VALUES (6);


CREATE TABLE instructors(
    instructor_id serial PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL
);

GRANT ALL
ON instructors
TO dean;

GRANT SELECT
ON instructors
TO PUBLIC;

GRANT SELECT
ON instructors
TO gp_students, gp_instructors;

INSERT INTO instructors(name, department) VALUES ('ins1','cse');
ALTER GROUP gp_instructors ADD USER ins1;
INSERT INTO instructors(name, department) VALUES ('ins2','cse');
ALTER GROUP gp_instructors ADD USER ins2;
INSERT INTO instructors(name, department) VALUES ('ins3','ece');
ALTER GROUP gp_instructors ADD USER ins3;
INSERT INTO instructors(name, department) VALUES ('ins4','ece');
ALTER GROUP gp_instructors ADD USER ins4;
INSERT INTO instructors(name, department) VALUES ('ins5','mech');
ALTER GROUP gp_instructors ADD USER ins5;


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
TO gp_instructors;

GRANT SELECT
ON offerings
TO gp_students;


CREATE TABLE offering_batches(
    offering_id INTEGER,
    department VARCHAR(50) NOT NULL,
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
TO gp_instructors;

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
        _department VARCHAR(50),
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
TO gp_students, gp_instructors;


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
    if current_total_credits + current_course_credits <= 1.25 * avg_credits then
            raise notice 'student satisfying 1.25 limit'; 
            INSERT INTO registrations(offering_id, student_id)
            VALUES (_offering_id, _student_id);
    else
            raise notice 'credit limit exceeded, ticket raised';
            -- TODO:
            -- INSERT INTO global_tickets_table(student_id, course_id, instructor_id, year, semester, slot,instructor_approval, batch_advisor_approval, dean_approval) 
            -- VALUES(_student_id, _course_id, _instructor_id,  _year, _semester, _slot, NULL, NULL, NULL);
    end if;                    
end; $$;

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















