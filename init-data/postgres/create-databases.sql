-- -- ####################
-- -- ####### BASE #######

-- --keycloak
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak';
CREATE DATABASE keycloak with owner keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
GRANT ALL PRIVILEGES ON SCHEMA public TO keycloak;

-- --keycloak-public
CREATE USER keycloak_public WITH ENCRYPTED PASSWORD 'keycloak_public';
CREATE DATABASE keycloak_public with owner keycloak_public;
GRANT ALL PRIVILEGES ON DATABASE keycloak_public TO keycloak_public;
GRANT ALL PRIVILEGES ON SCHEMA public TO keycloak_public;


-- -- ####################
-- -- ###### ONECX #######

-- -- onecx_ai_provider
CREATE USER onecx_ai_provider WITH ENCRYPTED PASSWORD 'onecx_ai_provider';
CREATE DATABASE onecx_ai_provider with owner onecx_ai_provider;
GRANT ALL PRIVILEGES ON DATABASE onecx_ai_provider TO onecx_ai_provider;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_ai_provider;

-- -- onecx_announcement
CREATE USER onecx_announcement WITH ENCRYPTED PASSWORD 'onecx_announcement';
CREATE DATABASE onecx_announcement with owner onecx_announcement;
GRANT ALL PRIVILEGES ON DATABASE onecx_announcement TO onecx_announcement;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_announcement;

-- -- onecx_bookmark
CREATE USER onecx_bookmark WITH ENCRYPTED PASSWORD 'onecx_bookmark';
CREATE DATABASE onecx_bookmark with owner onecx_bookmark;
GRANT ALL PRIVILEGES ON DATABASE onecx_bookmark TO onecx_bookmark;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_bookmark;

-- -- onecx_chat
CREATE USER onecx_chat WITH ENCRYPTED PASSWORD 'onecx_chat';
CREATE DATABASE onecx_chat with owner onecx_chat;
GRANT ALL PRIVILEGES ON DATABASE onecx_chat TO onecx_chat;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_chat;

-- -- onecx_help
CREATE USER onecx_help WITH ENCRYPTED PASSWORD 'onecx_help';
CREATE DATABASE onecx_help with owner onecx_help;
GRANT ALL PRIVILEGES ON DATABASE onecx_help TO onecx_help;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_help;

-- -- onecx_parameter
CREATE USER onecx_parameter WITH ENCRYPTED PASSWORD 'onecx_parameter';
CREATE DATABASE onecx_parameter with owner onecx_parameter;
GRANT ALL PRIVILEGES ON DATABASE onecx_parameter TO onecx_parameter;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_parameter;

-- -- onecx_permission
CREATE USER onecx_permission WITH ENCRYPTED PASSWORD 'onecx_permission';
CREATE DATABASE onecx_permission with owner onecx_permission;
GRANT ALL PRIVILEGES ON DATABASE onecx_permission TO onecx_permission;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_permission;

-- -- onecx_product_store
CREATE USER onecx_product_store WITH ENCRYPTED PASSWORD 'onecx_product_store';
CREATE DATABASE onecx_product_store with owner onecx_product_store;
GRANT ALL PRIVILEGES ON DATABASE onecx_product_store TO onecx_product_store;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_product_store;

-- -- onecx_tenant
CREATE USER onecx_tenant WITH ENCRYPTED PASSWORD 'onecx_tenant';
CREATE DATABASE onecx_tenant with owner onecx_tenant;
GRANT ALL PRIVILEGES ON DATABASE onecx_tenant TO onecx_tenant;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_tenant;

-- -- onecx_theme
CREATE USER onecx_theme WITH ENCRYPTED PASSWORD 'onecx_theme';
CREATE DATABASE onecx_theme with owner onecx_theme;
GRANT ALL PRIVILEGES ON DATABASE onecx_theme TO onecx_theme;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_theme;

-- -- onecx_search_config
CREATE USER onecx_search_config WITH ENCRYPTED PASSWORD 'onecx_search_config';
CREATE DATABASE onecx_search_config with owner onecx_search_config;
GRANT ALL PRIVILEGES ON DATABASE onecx_search_config TO onecx_search_config;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_search_config;

-- -- onecx_user_profile_avatar
CREATE USER onecx_user_profile_avatar WITH ENCRYPTED PASSWORD 'onecx_user_profile_avatar';
CREATE DATABASE onecx_user_profile_avatar with owner onecx_user_profile_avatar;
GRANT ALL PRIVILEGES ON DATABASE onecx_user_profile_avatar TO onecx_user_profile_avatar;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_user_profile_avatar;

-- -- onecx_user_profile
CREATE USER onecx_user_profile WITH ENCRYPTED PASSWORD 'onecx_user_profile';
CREATE DATABASE onecx_user_profile with owner onecx_user_profile;
GRANT ALL PRIVILEGES ON DATABASE onecx_user_profile TO onecx_user_profile;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_user_profile;

-- -- onecx_welcome
CREATE USER onecx_welcome WITH ENCRYPTED PASSWORD 'onecx_welcome';
CREATE DATABASE onecx_welcome with owner onecx_welcome;
GRANT ALL PRIVILEGES ON DATABASE onecx_welcome TO onecx_welcome;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_welcome;

-- -- onecx_workspace
CREATE USER onecx_workspace WITH ENCRYPTED PASSWORD 'onecx_workspace';
CREATE DATABASE onecx_workspace with owner onecx_workspace;
GRANT ALL PRIVILEGES ON DATABASE onecx_workspace TO onecx_workspace;
GRANT ALL PRIVILEGES ON SCHEMA public TO onecx_workspace;
