select sample_series.identifier, sample.identifier, sample_history.changed_date sample_date,
        aliquot.tube_aliquot_id, max(aliquot_history.changed_date) aliquot_date,
	state.identifier as atype, seq_phase.identifier as phase, 
	seq_type.identifier as stype, seq_app.identifier as sapp
	from sample 
       left join sample_series on(sample.sample_series_id=sample_series.sample_series_id)
       left join sample_history on(sample.sample_id=sample_history.sample_id)
       left join tube_aliquot as aliquot on(sample.sample_id=aliquot.sample_id)
       left join tube_aliquot_history as aliquot_history on(aliquot.tube_aliquot_id=aliquot_history.tube_aliquot_id)
       left join dbo.state as state on (aliquot.state_id=state.state_id) 
       left join dbo.category as seq_phase  on (aliquot.seq_state_category_id=seq_phase.category_id)
       left join dbo.category as seq_type on (aliquot.seq_type_category_id=seq_type.category_id)
       left join dbo.category as seq_app on (aliquot.seq_application_category_id=seq_app.category_id)
       where sample_history.changed_action='I' and sample_series.identifier like 'SX%'
       group by sample_series.identifier, sample.sample_id, sample.identifier,sample_history.changed_date,
       	     aliquot.tube_aliquot_id,state.identifier,seq_phase.identifier,
	     seq_type.identifier,seq_app.identifier
       order by sample_history.changed_date, sample.sample_id asc;


select category.identifier as phase from category where category_type='Phase';