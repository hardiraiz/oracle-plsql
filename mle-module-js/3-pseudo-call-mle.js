// sintaks eksekusi MLE Module JS langsung di MLE
function extendProjectTasks( status ) {
    if (status !== "Closed") {
        return true;
    }
    else {
        return false;
    }
}

for ( var row of apex.conn.execute( "select id, status from lrn_project_task where project = :project", { project: "Email Integration" } ).rows ) {
    if ( extendProjectTasks( row.STATUS )) {
        apex.conn.execute( "update lrn_project_task set end_date = end_date + 1 where id = :id", { id: row.ID } );
        console.log("The task with the ID: " + row.ID + " and the status " + row.STATUS + " has been extended successfully!")
    }
}