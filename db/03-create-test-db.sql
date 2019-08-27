-- DEV
CREATE DATABASE video_server_test WITH ENCODING = 'UTF8' OWNER = postgres;

\connect video_server_test
CREATE EXTENSION pg_trgm;

CREATE EXTENSION unaccent;

