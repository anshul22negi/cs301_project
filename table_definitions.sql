create database project;
\c project


CREATE TABLE instructors(
              instructor_id serial PRIMARY KEY,
              instructor_name VARCHAR(255) NOT NULL,
              department VARCHAR(255) NOT NULL
);

CREATE TABLE batch_advisors(
              advisor_id serial PRIMARY KEY,
              advisor_name VARCHAR(255) NOT NULL,
              year INTEGER NOT NULL,
              department VARCHAR(255) NOT NULL
);

CREATE TABLE course_catalogue(
              course_id serial PRIMARY KEY,
              course_name VARCHAR(255) NOT NULL,
	           L INTEGER NOT NULL,
	           T INTEGER NOT NULL,
	           P INTEGER NOT NULL,
	           S INTEGER NOT NULL,     
              Credits INTEGER NOT NULL
);

CREATE TABLE offerings(
              offering_id serial PRIMARY KEY,
              course_id INTEGER NOT NULL,
              instructor_id INTEGER NOT NULL,
              section INTEGER NOT NULL,
              semester INTEGER NOT NULL,
              Year INTEGER NOT NULL,
              running VARCHAR(255) NOT NULL,
              slot varchar(255) NOT NULL,
              cgpa_requirement INTEGER NOT NULL,

              FOREIGN KEY (course_id) REFERENCES course_catalogue(course_id),
              FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id),
              FOREIGN KEY (slot) REFERENCES Slots(slot),
              UNIQUE (course_id, instructor_id, section, semester, year, slot)
);

CREATE TABLE prerequisites(
              course_id INTEGER NOT NULL,
              prerequisite_id INTEGER NOT NULL,

              PRIMARY KEY (course_id, prerequisite_id),
              FOREIGN KEY (course_id) REFERENCES course_catalogue(course_id),
              FOREIGN KEY (prerequisite_id) REFERENCES course_catalogue(course_id)              

);

CREATE TABLE Slots(
              slot VARCHAr(255) PRIMARY KEY
);

CREATE TABLE offering_batches(
              offering_id INTEGER NOT NULL,
              department INTEGER NOT NULL,
              batch INTEGER NOT NULL,
              PRIMARY KEY (offering_id, department, batch),
              FOREIGN KEY (offering_id) REFERENCES offerings(offering_id)
);

CREATE TABLE Students(
               student_id serial PRIMARY KEY,
               student_name VARCHAR(255) NOT NULL,
               department VARCHAR(255) NOT NULL,
               batch INTEGER NOT NULL
);

CREATE TABLE Registrations(
               offering_id INTEGER NOT NULL,
               student_id INTEGER NOT NULL,
               PRIMARY KEY (offering_id, student_id),
               FOREIGN KEY (offering_id) REFERENCES offerings(offering_id),
               FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE Tickets_global(
               ticket_id serial PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	            student_id INTEGER NOT NULL,
               FOREIGN KEY (student_id) REFERENCES students (student_id),
               FOREIGN KEY (offering_id) REFERENCES offerings (offering_id)

               
);

CREATE TABLE Dean_tickets ( 
               ticket_id INTEGER NOT NULL PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	            student_id INTEGER NOT NULL,
               Instructor_decision BOOLEAN,
               Batch_advisor_decision BOOLEAN,
               Dean_decision BOOLEAN,     

               FOREIGN KEY (ticket_id) REFERENCES Tickets_global(ticket_id)         
);

CREATE TABLE Advisor_tickets_1 ( 
               ticket_id INTEGER NOT NULL PRIMARY KEY,
               offering_id INTEGER NOT NULL,
	            student_id INTEGER NOT NULL,
               Instructor_decision BOOLEAN,
               Batch_advisor_decision BOOLEAN,

               FOREIGN KEY (ticket_id) REFERENCES Tickets_global(ticket_id)            
);

CREATE TABLE Instructor_ticket_1 (
               ticket_id INTEGER NOT NULL PRIMARY KEY,
               offering_id INTEGER NOT NULL,
               student_id INTEGER NOT NULL,
               Instructor_decision BOOLEAN,

                FOREIGN KEY (ticket_id) REFERENCES Tickets_global(ticket_id) 
);
