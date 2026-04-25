-- Create database for lldap
CREATE DATABASE lldap;

-- Create database for langfuse
CREATE DATABASE langfuse;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE lldap TO admin;
GRANT ALL PRIVILEGES ON DATABASE devenv TO admin;
GRANT ALL PRIVILEGES ON DATABASE langfuse TO admin;
