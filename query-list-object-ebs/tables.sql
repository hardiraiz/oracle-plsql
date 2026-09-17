select owner, table_name 
from all_tables
where
    owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
    or (owner = 'ONT' AND table_name LIKE '%XXX%')
    or (owner = 'APPS' AND table_name LIKE '%XXX%')
order by 1; -- APPS (XXX, XFB, FWDP, PDA, FEIS, ONT (XXX))

select owner,view_name from all_views
where
    owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
    or (owner = 'ONT' AND view_name LIKE '%XXX%')
    or (owner = 'APPS' AND view_name LIKE '%XXX%')
order by 1; -- APPS (XXX, XFB, FWDP [FLOW DOCUMENT], PDA, FEIS, ONT (XXX))

select SEQUENCE_OWNER,SEQUENCE_NAME from all_sequences
where
    SEQUENCE_OWNER in ('XFB', 'FWDP', 'PDA', 'FEIS') 
    or (SEQUENCE_OWNER = 'ONT' AND SEQUENCE_NAME LIKE '%XXX%')
    or (SEQUENCE_OWNER = 'APPS' AND SEQUENCE_NAME LIKE '%XXX%')
order by 1;

select owner,object_name from all_objects
where object_type = 'PACKAGE'
    and (
        owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
        or (owner = 'ONT' AND object_name LIKE '%XXX%')
        or (owner = 'APPS' AND object_name LIKE '%XXX%')
    )
order by 1;

select owner,object_name from all_objects
where object_type = 'PACKAGE BODY'
    and (
        owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
        or (owner = 'ONT' AND object_name LIKE '%XXX%')
        or (owner = 'APPS' AND object_name LIKE '%XXX%')
    )
order by 1;

-- select owner,object_name from all_objects
-- where 
-- object_type = 'PACKAGE BODY'
-- and object_name like '%SPK%' 
-- and owner = 'ONT'
-- XFB, FWDP, PDA, FEIS, ONT (XXX)
-- order by 1;

select owner,object_name from all_objects
where object_type = 'PROCEDURE'
    and (
        owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
        or (owner = 'ONT' AND object_name LIKE '%XXX%')
        or (owner = 'APPS' AND object_name LIKE '%XXX%')
    )
order by 1;

-- select owner,object_name from all_objects
-- where 
-- object_type = 'PROCEDURE'
-- and object_name like '%SPK%'
-- and owner = 'ONT' -- XFB, FWDP, PDA, FEIS, ONT (XXX)
-- order by 1;

select owner,object_name from all_objects
where object_type = 'FUNCTION'
    and (
        owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
        or (owner = 'ONT' AND object_name LIKE '%XXX%')
        or (owner = 'APPS' AND object_name LIKE '%XXX%')
    )
order by 1;

-- select owner,object_name from all_objects
-- where 
-- object_type = 'FUNCTION'
-- and object_name like '%SPK%'
-- and owner = 'ONT' -- XFB, FWDP, PDA, FEIS, ONT (XXX)
-- order by 1;

select owner,object_name from all_objects
where object_type = 'DIRECTORY'
    and (
        owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
        or (owner = 'ONT' AND object_name LIKE '%XXX%')
        or (owner = 'APPS' AND object_name LIKE '%XXX%')
    )
order by 1; -- MEMANG KOSONG

-- select owner,object_name from all_objects
-- where 
-- object_type = 'DIRECTORY'
-- and owner = 'APPS' -- XFB, FWDP, PDA, FEIS, ONT (XXX)
-- and object_name like '%SPK%'
-- order by 1; -- NULL

select * from FND_EXECUTABLES_FORM_V
where 
    creation_date >= :P_DATE
    and (
        executable_name like '%XXX%' OR executable_name like '%XFB%' OR
        executable_name like '%FWDP%' OR executable_name like '%PDA%' OR
        executable_name like '%FEIS%' OR executable_name like '%ONT%'
    )
order by 
    creation_date desc;

select * from FND_CONCURRENT_PROGRAMS_VL
where 
    creation_date >= :P_DATE
    and (
        concurrent_program_name like '%XXX%' OR concurrent_program_name like '%XFB%' OR
        concurrent_program_name like '%FWDP%' OR concurrent_program_name like '%PDA%' OR
        concurrent_program_name like '%FEIS%' OR concurrent_program_name like '%ONT%'
    )
order by 
    creation_date desc;
-- where creation_date>=:P_DATE order by creation_date desc;

select  ffv.form_id "Form ID",
        ffv.form_name "Form Name",
        ffv.user_form_name "User Form Name",
        ffv.description "Form Description",
        ffcr.sequence "Sequence",
        ffcr.description "Personalization Rule Name"
from    fnd_form_vl ffv,
        fnd_form_custom_rules ffcr
where   1=1
        and ffv.form_name = ffcr.form_name
order by ffv.form_name,
        ffcr.sequence;


select * from FND_FORM_VL       
where 
    creation_date >=:P_DATE 
    and (
        form_name like '%XXX%' OR form_name like '%XFB%' OR
        form_name like '%FWDP%' OR form_name like '%PDA%' OR
        form_name like '%FEIS%' OR form_name like '%ONT%'
    )
order by creation_date asc;
-- where FORM_NAME LIKE '%ONT%' and creation_date >=:P_DATE order by creation_date asc; -- XFB, FWDP, PDA, FEIS, ONT (XXX)


select owner, table_name, select_priv, insert_priv, delete_priv, update_priv, references_priv, alter_priv, index_priv 
from table_privileges
where
        owner in ('XFB', 'FWDP', 'PDA', 'FEIS') 
    or (owner = 'ONT' AND table_name LIKE '%XXX%')
    or (owner = 'APPS' AND table_name LIKE '%XXX%')
order by 1;
-- where owner = 'APPS' and table_name LIKE '%XXX%'; -- XFB, FWDP, PDA, FEIS, ONT (XXX)
-- where table_name = trim(:p_name);


-- SEQUENCE SCHEMA APPS (XXX, XFB, FWDP, PDA, FEIS, ONT)

SELECT * FROM fnd_lookups
WHERE 
created_by > 1000
and creation_date >= :P_DATE
order by creation_date asc;

SELECT * FROM fnd_lookup_values
WHERE 
created_by > 1000
and creation_date >= :P_DATE
order by creation_date asc;

desc FND_DESCRIPTIVE_FLEXS;
desc FND_DESCR_FLEX_CONTEXTS;

SELECT * FROM FND_DESCR_FLEX_CONTEXTS
WHERE 
created_by > 1000
and creation_date >= :P_DATE
order by creation_date asc;

SELECT DISTINCT CREATED_BY FROM FND_DESCRIPTIVE_FLEXS ORDER BY CREATED_BY ASC;
