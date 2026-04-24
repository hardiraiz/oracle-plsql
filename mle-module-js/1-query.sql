-- query untuk mendapatkan list data yang akan diubah
select * from lrn_project_task 
where project = 'Email Integration' 
    and status != 'Closed'