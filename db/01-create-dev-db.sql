-- DEV
CREATE DATABASE video_server_dev WITH ENCODING = 'UTF8' OWNER = postgres;

\connect video_server_dev
CREATE EXTENSION pg_trgm;

CREATE EXTENSION unaccent;

