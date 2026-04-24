-- sintaks eksekusi MLE Module JS melalui PLSQL
DECLARE
    ctx DBMS_MLE.context_handle_t;

    user_code clob:= q'~
        function extendProjectTasks(status) {
            if (status !== "Closed") {
                return true;
            }
            else {
                return false;
            }
        }

        const result = session.execute(`select id, status from lrn_project_task where project = 'Email Integration'`);
        if (result.rows.length > 0) {
            for (let row of result.rows) {
                if (extendProjectTasks(`${row.STATUS}`)) {
                    session.execute(`update lrn_project_task set end_date = end_date + 1 where id = :id`, [`${row.ID}`]);
                    console.log(`The task with the ID: ${row.ID} and the status ${row.STATUS} has been extended successfully!`);
                }


            }
        } else {
            console.log(`no data found!`);
        };
    ~';

BEGIN
    ctx:= DBMS_MLE.create_context();
    DBMS_MLE.eval(ctx, 'JAVASCRIPT', user_code);
    DBMS_MLE.drop_context(ctx);
END;