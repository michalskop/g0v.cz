-- tables for cron projects

-- Table: public.jobs

-- DROP TABLE public.jobs;

CREATE TABLE public.jobs
(
  code text NOT NULL,
  name text,
  "interval" integer,
  min_time double precision,
  max_time double precision,
  active boolean NOT NULL DEFAULT true,
  CONSTRAINT jobs_pkey PRIMARY KEY (code)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.jobs
  OWNER TO postgres;
GRANT ALL ON TABLE public.jobs TO author;

-- Table: public.runs

-- DROP TABLE public.runs;

CREATE TABLE public.runs
(
  id integer NOT NULL DEFAULT nextval('runs_id_seq'::regclass),
  job_code text NOT NULL,
  start_date timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
  end_date timestamp with time zone,
  status text NOT NULL DEFAULT 'running',
  message text,
  CONSTRAINT runs_pkey PRIMARY KEY (id),
  CONSTRAINT runs_job_code_fkey FOREIGN KEY (job_code)
      REFERENCES public.jobs (code) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.runs
  OWNER TO postgres;
GRANT ALL ON TABLE public.runs TO author;
grant usage on public.runs_id_seq to author;

-- View: public.not_started_in_time

-- DROP VIEW public.not_started_in_time;

CREATE OR REPLACE VIEW public.not_started_in_time AS
 SELECT mr.start_date,
    mr.job_code,
    j.code,
    j.name,
    j."interval",
    j.min_time,
    j.max_time,
    j.active,
    clock_timestamp() - mr.start_date AS interval_since_last
   FROM ( SELECT max(r.start_date) AS start_date,
            r.job_code
           FROM runs r
          GROUP BY r.job_code) mr
     LEFT JOIN jobs j ON mr.job_code = j.code
  WHERE mr.start_date < (clock_timestamp() - '00:00:01'::interval * j."interval"::double precision) AND j.active;

ALTER TABLE public.not_started_in_time
  OWNER TO postgres;
GRANT SELECT ON TABLE public.not_started_in_time TO author;

-- View: public.not_finished_in_time

-- DROP VIEW public.not_finished_in_time;

CREATE OR REPLACE VIEW public.not_finished_in_time AS
 SELECT r.id,
    r.job_code,
    r.start_date,
    r.end_date,
    r.status,
    r.message,
    j.code,
    j.name,
    j."interval",
    j.min_time,
    j.max_time,
    j.active
   FROM runs r
     LEFT JOIN jobs j ON r.job_code = j.code
  WHERE r.start_date < (clock_timestamp() - '00:00:01'::interval * j.max_time) AND r.status = 'running'::text AND r.end_date IS NULL AND j.active;

ALTER TABLE public.not_finished_in_time
  OWNER TO postgres;
GRANT SELECT ON TABLE public.not_finished_in_time TO author;

-- View: public.finished_not_solved

-- DROP VIEW public.finished_not_solved;

CREATE OR REPLACE VIEW public.finished_not_solved AS
 SELECT r.id,
    r.job_code,
    r.start_date,
    r.end_date,
    r.status,
    r.message,
    j.code,
    j.name,
    j."interval",
    j.min_time,
    j.max_time,
    j.active,
    (r.end_date - r.start_date) < ('00:00:01'::interval * j."interval"::double precision) AS in_time
   FROM runs r
     LEFT JOIN jobs j ON r.job_code = j.code
  WHERE (r.status = ANY (ARRAY['running'::text, 'fail'::text, 'finished'::text])) AND r.end_date IS NOT NULL;

ALTER TABLE public.finished_not_solved
  OWNER TO postgres;
GRANT ALL ON TABLE public.finished_not_solved TO postgres;
GRANT SELECT ON TABLE public.finished_not_solved TO author;

-- View: public.last_day

-- DROP VIEW public.last_day;

CREATE OR REPLACE VIEW public.last_day AS
 SELECT r.id,
    r.job_code,
    r.start_date,
    r.end_date,
    r.status,
    r.message,
    j.code,
    j.name,
    j."interval",
    j.min_time,
    j.max_time,
    j.active
   FROM runs r
     LEFT JOIN jobs j ON r.job_code = j.code
  WHERE (clock_timestamp() - r.start_date) < '1 day'::interval
  ORDER BY j.name, r.status;

ALTER TABLE public.last_day
  OWNER TO postgres;
GRANT ALL ON TABLE public.last_day TO postgres;
GRANT SELECT ON TABLE public.last_day TO author;
