-- This SQL script migrates all keycloak tables from the "public" schema to the target schema "keycloak"
DO $$
DECLARE
    -- Define your target schema and your list of tables here
    -- 
    -- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
    target_schema TEXT := 'keycloak';
    table_list TEXT[] := ARRAY['databasechangeloglock', 'client_session_role', 'redirect_uris', 'user_federation_provider', 'realm_required_credential', 'realm_smtp_config', 'composite_role', 'user_role_mapping', 'realm_events_listeners', 'web_origins', 'scope_mapping', 'user_federation_config', 'databasechangelog', 'client_session_note', 'user_session', 'federated_identity', 'identity_provider_config', 'protocol_mapper_config', 'realm_supported_locales', 'user_session_note', 'realm_enabled_event_types', 'identity_provider_mapper', 'idp_mapper_config', 'client_session_prot_mapper', 'client_node_registrations', 'user_required_action', 'client_session_auth_status', 'user_federation_mapper', 'user_federation_mapper_config', 'client_session', 'authentication_flow', 'authentication_execution', 'authenticator_config_entry', 'authenticator_config', 'required_action_config', 'client_user_session_note', 'keycloak_role', 'keycloak_group', 'group_attribute', 'user_group_membership', 'group_role_mapping', 'realm_default_groups', 'protocol_mapper', 'policy_config', 'resource_scope', 'resource_policy', 'scope_policy', 'associated_policy', 'broker_link', 'fed_user_group_membership', 'fed_user_required_action', 'fed_user_role_mapping', 'admin_event_entity', 'federated_user', 'component', 'username_login_failure', 'identity_provider', 'client_initial_access', 'user_entity', 'client_auth_flow_bindings', 'fed_user_consent', 'offline_client_session', 'client_scope_attributes', 'client_scope_role_mapping', 'client_scope', 'default_client_scope', 'user_consent_client_scope', 'fed_user_consent_cl_scope', 'resource_server_resource', 'resource_server_scope', 'resource_attribute', 'resource_uris', 'required_action_provider', 'role_attribute', 'offline_user_session', 'credential', 'fed_user_credential', 'migration_model', 'client', 'user_consent', 'resource_server_perm_ticket', 'realm', 'client_scope_client', 'realm_attribute', 'realm_localizations', 'client_attributes', 'resource_server_policy', 'resource_server', 'component_config', 'event_entity', 'user_attribute', 'fed_user_attribute', 'org', 'org_domain'];

    t_name TEXT;
    table_exists BOOLEAN;
BEGIN
    -- Ensure the target schema exists
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', target_schema);

    -- Loop through each table in your array
    FOREACH t_name IN ARRAY table_list LOOP

        -- Check if the table actually exists in the public schema
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = t_name
        ) INTO table_exists;

        -- If it exists, move it. If not, skip it without throwing an error.
        IF table_exists THEN
            EXECUTE format('ALTER TABLE public.%I SET SCHEMA %I', t_name, target_schema);
            RAISE NOTICE 'Successfully moved table: public.% to %', t_name, target_schema;
        ELSE
            RAISE NOTICE 'Skipped: table public.% does not exist', t_name;
        END IF;

    END LOOP;
END $$;
