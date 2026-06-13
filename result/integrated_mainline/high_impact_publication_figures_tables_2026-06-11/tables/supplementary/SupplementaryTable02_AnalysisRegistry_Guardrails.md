| source_table | phase | analysis_unit | question | input | output | status | risk | do_not_write | preferred_language | severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| registry | 0.0 | scope | What is the no-digestion manuscript claim space? | completed Phase 0-5 and dry-lab booster outputs | scope, analysis registry, overclaim guardrails | completed |  |  |  |  |
| registry | 1.0 | evidence audit | Which current results are main, supplementary, or exploratory? | all key result CSV files | evidence grade and crosswalk | completed |  |  |  |  |
| registry | 2.0 | tables/figures | What are the manuscript-ready tables and figure datasets? | NHANES, CGMacros, prediction, external boundary result tables | main tables, figure data, draft figures | completed |  |  |  |  |
| registry | 3.0 | manuscript skeleton | How should the no-digestion paper be written? | evidence grade and tables | abstract, title options, outline, figure storyboard | completed |  |  |  |  |
| registry | 4.0 | submission readiness | What remains before submission if digestion experiments are excluded? | all Phase 0-3 outputs | readiness audit, limitations, checklists, next actions | completed |  |  |  |  |
| guardrails |  |  |  |  |  |  | Cross-dataset causal overclaim | DEHP causes higher PPGR in CGMacros. | DEHP oxidative profile is associated with MSI in NHANES; MSI is expressed as PPGR vulnerability in CGMacros. | high |
| guardrails |  |  |  |  |  |  | Mediator overclaim | MSI mediates the causal effect of DEHP on PPGR. | MSI is a bridge phenotype linking population exposure signals with dynamic CGM phenotypes. | high |
| guardrails |  |  |  |  |  |  | Food matrix overclaim | Digestibility-risk is experimentally validated digestion kinetics. | Digestibility-risk is a dry-lab food matrix proxy requiring expert/photo/database validation. | high |
| guardrails |  |  |  |  |  |  | Prediction overclaim | The model precisely predicts individual glucose excursions for clinical use. | The MSI-enhanced model improves high-response meal risk stratification and calibration. | medium |
| guardrails |  |  |  |  |  |  | External validation overclaim | Stanford/T1D-UOM externally validate the CGMacros MSI model. | External datasets provide transportability boundaries and directional macro-response support. | medium |
