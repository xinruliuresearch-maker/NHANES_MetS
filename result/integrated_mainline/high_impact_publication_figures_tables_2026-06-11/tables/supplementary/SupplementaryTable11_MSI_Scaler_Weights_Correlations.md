| source_table | component | reference_dataset | winsor_p01 | winsor_p99 | mean_after_winsor | sd_after_winsor | n_reference_nonmissing | dataset | n_nonmissing | n_missing | pct_nonmissing | weight | msi_a | msi_b | n_pairwise | pearson | spearman |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| msi_scaler | bmi | NHANES_2013_2018 | 17.7 | 52.8 | 29.48440984236833 | 6.966291464626639 | 5202.0 |  |  |  |  |  |  |  |  |  |  |
| msi_scaler | hba1c | NHANES_2013_2018 | 4.6 | 11.0 | 5.825009815469179 | 1.0486360492106908 | 5094.0 |  |  |  |  |  |  |  |  |  |  |
| msi_scaler | fasting_glucose_mgdl | NHANES_2013_2018 | 78.0 | 287.1100000000001 | 111.32961847389558 | 33.14524303423062 | 2490.0 |  |  |  |  |  |  |  |  |  |  |
| msi_scaler | ln_homa_ir | NHANES_2013_2018 | -0.8276311281107942 | 3.400791050406984 | 0.9712227222585836 | 0.8237469152350619 | 2446.0 |  |  |  |  |  |  |  |  |  |  |
| msi_scaler | ln_tg_hdl | NHANES_2013_2018 | -1.0171745136899422 | 2.582358762787892 | 0.6069302859886732 | 0.7595084588208144 | 2418.0 |  |  |  |  |  |  |  |  |  |  |
| msi_missing | bmi |  |  |  |  |  |  | NHANES_2013_2018 | 5202.0 | 65.0 | 98.7659008923486 |  |  |  |  |  |  |
| msi_missing | hba1c |  |  |  |  |  |  | NHANES_2013_2018 | 5094.0 | 173.0 | 96.71539775963548 |  |  |  |  |  |  |
| msi_missing | fasting_glucose_mgdl |  |  |  |  |  |  | NHANES_2013_2018 | 2490.0 | 2777.0 | 47.27548889310803 |  |  |  |  |  |  |
| msi_missing | ln_homa_ir |  |  |  |  |  |  | NHANES_2013_2018 | 2446.0 | 2821.0 | 46.44009872792861 |  |  |  |  |  |  |
| msi_missing | ln_tg_hdl |  |  |  |  |  |  | NHANES_2013_2018 | 2418.0 | 2849.0 | 45.908486804632616 |  |  |  |  |  |  |
| msi_missing | bmi |  |  |  |  |  |  | CGMacros_subjects | 40.0 | 0.0 | 100.0 |  |  |  |  |  |  |
| msi_missing | hba1c |  |  |  |  |  |  | CGMacros_subjects | 40.0 | 0.0 | 100.0 |  |  |  |  |  |  |
| msi_missing | fasting_glucose_mgdl |  |  |  |  |  |  | CGMacros_subjects | 40.0 | 0.0 | 100.0 |  |  |  |  |  |  |
| msi_missing | ln_homa_ir |  |  |  |  |  |  | CGMacros_subjects | 40.0 | 0.0 | 100.0 |  |  |  |  |  |  |
| msi_missing | ln_tg_hdl |  |  |  |  |  |  | CGMacros_subjects | 40.0 | 0.0 | 100.0 |  |  |  |  |  |  |
| msi_weights | bmi_z_nhanes_ref |  |  |  |  |  |  |  |  |  |  | 0.1596131825752739 |  |  |  |  |  |
| msi_weights | hba1c_z_nhanes_ref |  |  |  |  |  |  |  |  |  |  | 0.2245380813281983 |  |  |  |  |  |
| msi_weights | fasting_glucose_mgdl_z_nhanes_ref |  |  |  |  |  |  |  |  |  |  | 0.2246832491434801 |  |  |  |  |  |
| msi_weights | ln_homa_ir_z_nhanes_ref |  |  |  |  |  |  |  |  |  |  | 0.2281949252186954 |  |  |  |  |  |
| msi_weights | ln_tg_hdl_z_nhanes_ref |  |  |  |  |  |  |  |  |  |  | 0.162970561734352 |  |  |  |  |  |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | msi_core_complete | 40.0 | 1.0 | 1.0 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | msi_ranknorm | 40.0 | 0.9924832731670103 | 0.9902439024390248 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | msi_no_bmi | 40.0 | 0.9775689154162924 | 0.9750469043151972 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | msi_glycemia_ir | 40.0 | 0.9326264168684508 | 0.9210131332082552 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | msi_ir_lipid | 40.0 | 0.9030791206726962 | 0.902063789868668 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | msi_pca | 40.0 | 0.9970500973215696 | 0.9932457786116324 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | homa_ir_single | 40.0 | 0.865268210160986 | 0.8688555347091933 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_partial | tg_hdl_single | 40.0 | 0.7725776952194676 | 0.7879924953095686 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | msi_ranknorm | 40.0 | 0.9924832731670103 | 0.9902439024390248 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | msi_no_bmi | 40.0 | 0.9775689154162924 | 0.9750469043151972 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | msi_glycemia_ir | 40.0 | 0.9326264168684508 | 0.9210131332082552 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | msi_ir_lipid | 40.0 | 0.9030791206726962 | 0.902063789868668 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | msi_pca | 40.0 | 0.9970500973215696 | 0.9932457786116324 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | homa_ir_single | 40.0 | 0.865268210160986 | 0.8688555347091933 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_core_complete | tg_hdl_single | 40.0 | 0.7725776952194676 | 0.7879924953095686 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ranknorm | msi_no_bmi | 40.0 | 0.961685932912194 | 0.9679174484052534 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ranknorm | msi_glycemia_ir | 40.0 | 0.9148505210680162 | 0.9221388367729833 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ranknorm | msi_ir_lipid | 40.0 | 0.9080120558533448 | 0.8951219512195124 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ranknorm | msi_pca | 40.0 | 0.9873008630543344 | 0.9883677298311446 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ranknorm | homa_ir_single | 40.0 | 0.8816312796536342 | 0.8889305816135086 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ranknorm | tg_hdl_single | 40.0 | 0.766351829033332 | 0.7831144465290808 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_no_bmi | msi_glycemia_ir | 40.0 | 0.9638942452234446 | 0.954033771106942 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_no_bmi | msi_ir_lipid | 40.0 | 0.8767643714575832 | 0.8840525328330208 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_no_bmi | msi_pca | 40.0 | 0.9860402250985526 | 0.9825515947467168 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_no_bmi | homa_ir_single | 40.0 | 0.8217418721593504 | 0.8392120075046905 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_no_bmi | tg_hdl_single | 40.0 | 0.7665050730551867 | 0.7787992495309569 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_glycemia_ir | msi_ir_lipid | 40.0 | 0.7446288954051034 | 0.7574108818011259 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_glycemia_ir | msi_pca | 40.0 | 0.9575531488892896 | 0.948968105065666 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_glycemia_ir | homa_ir_single | 40.0 | 0.7905550966133134 | 0.7992495309568481 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_glycemia_ir | tg_hdl_single | 40.0 | 0.5678111953414982 | 0.6093808630393998 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ir_lipid | msi_pca | 40.0 | 0.8805922070911375 | 0.8735459662288932 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ir_lipid | homa_ir_single | 40.0 | 0.8925265832128286 | 0.877485928705441 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_ir_lipid | tg_hdl_single | 40.0 | 0.914384411016114 | 0.9392120075046908 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_pca | homa_ir_single | 40.0 | 0.8600927212468568 | 0.8589118198874298 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | msi_pca | tg_hdl_single | 40.0 | 0.738645420150098 | 0.7491557223264541 |
| msi_corr |  |  |  |  |  |  |  | CGMacros |  |  |  |  | homa_ir_single | tg_hdl_single | 40.0 | 0.6335284765113617 | 0.7054409005628518 |
| msi_corr |  |  |  |  |  |  |  | NHANES |  |  |  |  | msi_core_partial | msi_core_complete | 2368.0 | 1.0 | 1.0 |
| msi_corr |  |  |  |  |  |  |  | NHANES |  |  |  |  | msi_core_partial | msi_ranknorm | 2491.0 | 0.9514159797424384 | 0.982126830272479 |
| msi_corr |  |  |  |  |  |  |  | NHANES |  |  |  |  | msi_core_partial | msi_no_bmi | 2466.0 | 0.9663848669034738 | 0.9567713947188622 |
| msi_corr |  |  |  |  |  |  |  | NHANES |  |  |  |  | msi_core_partial | msi_glycemia_ir | 2490.0 | 0.9216239384786002 | 0.8995179178216639 |
