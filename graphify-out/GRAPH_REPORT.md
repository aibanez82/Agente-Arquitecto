# Graph Report - docs  (2026-10-02)

## Corpus Check
- 240 files · ~388,528 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: .class 1)

## Summary
- 1130 nodes · 2231 edges · 75 communities (67 shown, 8 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 170 edges (avg confidence: 0.83)
- Token cost: 1,400,208 input · 0 output

## Community Hubs (Navigation)
- Conciliación y METEPEC
- Entrega de cotización
- Descuentos y promoción STG→PROD
- Control humano e inventario BD
- Parches del AI Agent
- Guiones de prueba E2E
- Conversation ID y QA
- Núcleo de datos del funnel
- Seguimiento y persistencia de datos
- Tracker y disciplina CLAUDE.md
- RC4 en C#
- Migración STG y grants
- Checkpoint C1 blocked
- Constancia fiscal y multi-aseguradora
- Aislamiento STG/PROD de Meta
- Contract-First #132
- Pasarela de pago Quálitas
- Bug 12 inbound caído
- Bug 10 VIN
- Monitoreo E2E
- Checkpoint followups
- Timestamps y E2E descuentos
- Marca Insurmind
- Despliegue STG a PROD julio
- Fallos de emisión
- Gobernanza funnel #135
- Bugs de sesión
- Preguntas para Hylant
- Acreditación S1
- Trigger WhatsApp y guardas
- Cobranza y recordatorios de pago
- Session ID en Dashboard
- Tubería de mejoras de copy
- Monitores y protocolo n8n
- Atención humana S3
- Alcance del bot
- Eventos WhatsApp y follow-up
- Plan C0–C9 #140
- Payment Confirmation y freeze
- Backup de workflows n8n
- Merge por estado
- Emisión vía webservice
- Validación VIN y placas
- STOP S1 Dashboard
- Pendientes de infraestructura
- Juan y envío real
- Webhooks proactivos STG
- Contrato S2
- OPL cobranza SOAP
- Diagrama tres planos
- Bug 6 placas
- Recordatorios por fecha
- Estándar adversarial
- RC4 en Java
- Script fareceipt
- Estado unificado del lead
- RC4 en PHP
- Identificación del cliente
- Consolidación de workflows
- Alcance de cotización
- Ciclo autónomo #132
- Plataformas de conversación
- Captura de voz backlog
- Link de pago y OPL
- Agente CSF
- Detección batch de fechas
- Workflow proactivo
- S1 v1.1 Dashboard
- WSTARIFAS
- Tarifas (resumen)
- WSIMPRESION
- Re-enganche Meta
- Impresión v2
- Script listrecs
- Script OPL receipts

## God Nodes (most connected - your core abstractions)
1. `Juan Aguayo` - 57 edges
2. `Agente n8n` - 56 edges
3. `whatsapp_sessions` - 48 edges
4. `Dashboard (Next.js)` - 47 edges
5. `n8n_chat_histories` - 38 edges
6. `Arquitecto-IA-Qualitas` - 33 edges
7. `HYL-WAI#132 Dual / Contract-First` - 32 edges
8. `Bug #10 (ciudad en lugar de VIN)` - 27 edges
9. `n8n` - 26 edges
10. `dashboard_conversation_claims` - 24 edges

## Surprising Connections (you probably didn't know these)
- `Control (conversion y embudo)` --semantically_similar_to--> `Dashboard (Next.js)`  [INFERRED] [semantically similar]
  marca/insurmind-tres-planos.svg → 2026-07-07-hallazgo-agente-dashboard-canal-landing-vs-whatsapp.md
- `Conversacion (dudas, recotizacion, descuentos, emision)` --semantically_similar_to--> `n8n`  [INFERRED] [semantically similar]
  marca/insurmind-tres-planos.svg → 2026-07-05-consolidacion-workflows-n8n.md
- `genWebPay — pasarela con usucces/ufail` --conceptually_related_to--> `Django (HYL-WAI)`  [INFERRED]
  qualitas-api/Api-REST-Link-de-Pago-v1.4.pdf → 2026-07-05-handoff-despliegue-bug10-vin.md
- `Observabilidad (GA4 + Meta Business API)` --references--> `Meta Cloud API / WhatsApp`  [INFERRED]
  diagrama-arquitectura-sistema.svg → architecture/data-flow.md
- `Un viaje, una causa` --conceptually_related_to--> `Agente n8n`  [INFERRED]
  architecture/convenciones-origen.md → 2026-07-05-consolidacion-workflows-n8n.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Despliegue lockstep Bug #10 (n8n + Django)** — 2026_07_05_handoff_despliegue_bug10_vin_rollout_lockstep, 2026_07_05_handoff_despliegue_bug10_vin_vehicle_series_gate, 2026_07_05_propuesta_n8n_respuesta_handoff_bug10_deploy_script, entity_wf_bot_prod, entity_n8n_node_issue_policy, 2026_07_05_handoff_despliegue_bug10_vin_regex_vin17 [EXTRACTED 1.00]
- **Incidente Bug #12: colisión webhookId → apagón → rescate** — entity_bug_12, 2026_07_05_consolidacion_workflows_n8n_webhookid_collision, 2026_07_05_consolidacion_workflows_n8n_borrado_12_duplicados, 2026_07_05_rescate_leads_1046_1103_lista_rescate, 2026_07_05_handoff_n8n_bug12_inbound_caido_alerta_inbound_caido [EXTRACTED 1.00]
- **Aislamiento staging/prod** — 2026_07_07_handoff_agente_n8n_verificacion_aislamiento_staging_tabla_ids_prod, 2026_07_06_handoff_agente_n8n_import_staging_bug10_remap_credenciales, 2026_07_06_mensaje_juan_meta_app_staging_meta_app_staging, 2026_07_08_handoff_agente_n8n_bug15_filtro_phone_number_id_prod_phone_number_guard, entity_bug_15 [INFERRED 0.85]
- **Activación del envío real de checkpoint_followups en PROD** — 2026_07_19_handoff_juan_activar_envio_real_checkpoint_followups_doc, 2026_07_20_handoff_juan_activar_envio_real_checkpoint_followups_sin_filtro_horario_doc, 2026_07_21_handoff_juan_activar_envio_real_checkpoint_followups_noche_doc, 2026_07_21_handoff_juan_filtro_horario_checkpoint_followups_doc, entity_flags_checkpoint_followups, entity_checkpoint_followups [INFERRED 0.85]
- **Bloqueo por fecha_inicio: M47, M48 y renovación fase 2** — entity_parche_m47, entity_parche_m48, 2026_07_22_handoff_agente_n8n_renovacion_ruteo_y_copy_fase2_casuistica, entity_fecha_inicio, entity_issue_hyl_wai_114 [INFERRED 0.85]
- **Entrega del PDF de cotización al cliente** — entity_pdf_cotizacion_url, entity_api_cotizacion_detalle, entity_node_get_quotation_data, 2026_07_20_handoff_juan_issue110_entrega_cotizacion_quick_reply_fetch_quotation_document, entity_n8n_token, entity_parche_m31 [INFERRED 0.85]
- **Ciclo de delivery del port #132 (construye, audita, GO)** — 2026_07_28_reporte_juan_estado_port_132_port_dual_safe, entity_agente_n8n, entity_monitor_oilycoyote, 2026_07_30_guion_checkpoint_juan_go_no_go, entity_issue_hyl_wai_132 [EXTRACTED 1.00]
- **BD Postgres compartida Django/n8n/Dashboard** — entity_django, entity_n8n, entity_dashboard, entity_table_whatsapp_sessions, entity_table_qualitas_lead, entity_table_n8n_chat_histories [EXTRACTED 1.00]
- **Flujo de conciliación de pagos** — entity_agente_conciliacion, entity_table_conciliacion_pagos, entity_table_qualitas_polizaemitida, 2026_07_26_reporte_agente_conciliacion_dashboard_sin_conciliar_cron_stg_cron_conciliar, entity_dashboard [EXTRACTED 1.00]
- **Fuentes de verdad del estado de pago** — entity_table_qualitas_polizaemitida, entity_table_conciliacion_pagos, entity_table_qualitas_qualitasproviderreceipt, entity_laura_hylant, architecture_estatus_pago_qualitas_redirect_navegador [EXTRACTED 1.00]
- **Detección de hitos del lead (LIKE vs ledger S2 vs whatsapp_event)** — concept_detectores_like_hitos, architecture_estados_lead_funnel_s2_evidencia_falla_cerrado, architecture_whatsapp_event_canonico_propuesta_patron_outbox, entity_table_qualitas_leadfunnelevent [INFERRED 0.85]
- **Auditoría forense C1 / giro Contract-First** — auditorias_2026_08_04_resumen_auditor_externo_contract_first, auditorias_c1_auditoria_primaria, auditorias_c1_genesis_economia, entity_issue_hyl_wai_140, entity_contract_first [EXTRACTED 1.00]
- **Cruces STG→PROD por configuración compartida** — entity_bug_15, entity_bug_16, entity_bug_17, entity_bug_12 [INFERRED 0.85]
- **Carrera doble-submit + reset de sesión → deflect** — bugs_bug_20_doble_submit_session_race_landing_serve, entity_archivar_historial_chats, entity_table_whatsapp_sessions, entity_resolve_session, entity_bug_11 [EXTRACTED 1.00]
- **Cadena de emisión de póliza** — bugs_bug_10_vin_issue_policy_issue_policy, bugs_bug_09_emision_400_emitir_externo, bugs_bug_08_telefono_soap_generar_bloque_492, entity_qualitas_soap [INFERRED 0.85]
- **Flujo de control humano ↔ IA (claim → gate → release)** — entity_table_dashboard_conversation_claims, iniciativas_2026_07_24_control_humano_vs_ia_conversacion_gate_supresion, iniciativas_2026_07_24_control_humano_vs_ia_conversacion_claim_fuente_verdad, iniciativas_2026_07_24_control_humano_vs_ia_conversacion_flag_ortogonal, iniciativas_2026_07_23_inbox_contact_center_login_individual_pestana_inbox, entity_table_n8n_chat_histories, entity_workflow_retomar_conversacion [EXTRACTED 1.00]
- **Tubería KB: keyword matching → pgvector → corpus fallback** — entity_search_knowledge_base1, iniciativas_2026_07_17_decision_rag_vs_keyword_matching_kb_keyword_matching, iniciativas_2026_07_17_migracion_rag_kb_pgvector_design_vector_store_tool, entity_table_kb_chunks, entity_table_doc_chunks, entity_rag_ia_agent, entity_openai_embeddings [EXTRACTED 1.00]
- **Entrega de leads no cotizables a METEPEC** — entity_intent_router_haiku, iniciativas_2026_07_24_metepec_mapa_deteccion_deteccion_gruesa_fina, iniciativas_2026_07_20_agente_mtp_correo_metepec_rama_metepec_n8n, entity_table_leads_metepec, entity_metepec, iniciativas_2026_07_20_agente_mtp_correo_metepec_gmail_oauth2, iniciativas_2026_07_24_metepec_redefinicion_alcance_once_categorias [INFERRED 0.85]
- **Evolución de planes de promoción STG→PROD** — iniciativas_2026_08_10_plan_promocion_stg_a_prod_cross_doc, iniciativas_2026_08_12_plan_promocion_stg_a_prod_v2_doc, iniciativas_2026_08_23_plan_promocion_stg_a_prod_agil_doc, iniciativas_2026_08_14_promociones_en_20_minutos_diagnostico_y_plan_doc [INFERRED 0.85]
- **Cadena de ventanas #156 en STG: DDL → import → integración → E2E** — iniciativas_2026_08_13_runbook_ventana_ddl_stg_156_doc, iniciativas_2026_08_14_runbook_import_stg_156_doc, iniciativas_2026_08_14_runbook_integracion_active_open_doc, iniciativas_2026_08_14_caso_prueba_e2e_descuentos_stg_doc, iniciativas_2026_08_17_plan_e2e_descuentos_stg_doc [EXTRACTED 1.00]
- **Etapas Contract-First S1–S5** — entity_issue_hyl_wai_132, entity_issue_hyl_wai_135, entity_issue_hyl_wai_128, entity_issue_hyl_wai_143, entity_issue_hyl_wai_146 [EXTRACTED 1.00]
- **Cadena de checkpoints C1 en HYL-WAI#132** — iniciativas_c1_checkpoint_operativo_borrador_doc, iniciativas_c1_checkpoint_operativo_ab_v2_doc, iniciativas_c1_blocked_import_checkpoint_doc, iniciativas_c1_preflight_readonly_runbook_operador_doc, iniciativas_c1_fix_directorios_privados_operativa_doc, entity_contrato_c1_n8n_capabilities [INFERRED 0.85]
- **Guiones E2E conversacionales STG/PROD (28-31 ago)** — iniciativas_2026_08_29_pruebas_completas_stg_y_prod_caso_a, iniciativas_2026_08_29_pruebas_completas_stg_y_prod_caso_b, iniciativas_2026_08_30_caso_prueba_emision_stg_250_pasos_e1_e11, iniciativas_2026_08_31_caso_prueba_completo_prod_guion_p1_p15, entity_issue_hyl_wai_239, entity_issue_hyl_wai_232 [INFERRED 0.85]
- **Plan C (C0-C5) hacia dual** — iniciativas_c0_baseline_freeze_opcion_c_doc, iniciativas_archivo_plan_c_c2_checkpoint_ventana_draft_doc, iniciativas_archivo_plan_c_c2_matriz_nucleo_dual_runbook_borrador_doc, iniciativas_archivo_plan_c_c3_c4_prep_offline_c3_schema_gap, iniciativas_archivo_plan_c_c3_c4_prep_offline_c4_canario, iniciativas_archivo_plan_c_c3_c4_prep_offline_c5_dual_final, entity_whatsapp_conversation_id_mode [EXTRACTED 1.00]
- **Preparación offline Contract-First S1→S2→S3** — iniciativas_s1_v11_prep_dashboard, iniciativas_s2_prep_offline, iniciativas_s2_propuestas_diseno_prefreeze, iniciativas_s3_prep_offline, iniciativas_s3_input_pre_freeze, entity_contract_first [INFERRED 0.85]
- **Autoridad de control humano: claims canónico vs mirrors n8n** — entity_table_dashboard_conversation_claims, entity_mirrors_human_takeover, entity_workflow_atencion_humana, iniciativas_s2_propuestas_diseno_prefreeze_consulta_canonica_sql, iniciativas_s2_propuestas_diseno_prefreeze_mirrors_no_comparados [INFERRED 0.85]
- **Cadena de seguimiento proactivo Scheduler→Django→Retomar→historial** — entity_checkpoint_followups, iniciativas_seguimiento_leads_estancados_evaluate_checkpoint_followup_candidate, entity_workflow_retomar_conversacion, entity_table_n8n_chat_histories, entity_table_qualitas_leadfollowuppolicy [EXTRACTED 1.00]
- **Tubería de copy Mejoras → Arquitecto → Agente n8n** — entity_agente_mejoras_conversacion, entity_arquitecto, entity_agente_n8n, entity_ai_agent_node [EXTRACTED 1.00]
- **Ciclo autónomo port #132 (Arquitecto ↔ Agente n8n ↔ Juan)** — entity_arquitecto, entity_agente_n8n, entity_juan_aguayo, entity_issue_hyl_wai_132, protocolos_estandar_adversarial_desarrollo_pasada_adversarial [EXTRACTED 1.00]
- **Superficie de servicios web Quálitas (emisión, impresión, tarifas, pago, cobranza)** — qualitas_api_1_documentaci_nserviciosweb_wsemision, qualitas_api_3_wsimpresion_recupera_impresion, qualitas_api_4_wstarifas_listatarifas, qualitas_api_api_rest_link_de_pago_v1_4_genwebpay, qualitas_api_opl_servicios_web_v1_3_2_oplcollection [INFERRED 0.85]
- **Flujo de cobro Django → Quálitas (pasarela y cobranza)** — entity_generar_link_pasarela, qualitas_api_api_rest_link_de_pago_genwebpay, qualitas_api_api_rest_link_de_pago_fareceipt, entity_derivar_poliza_opl, qualitas_api_opl_servicios_web_oplcollection, entity_redirect_usucces_ufail [INFERRED 0.85]
- **Fuentes de estado de recibos para Conciliación** — qualitas_api_api_rest_link_de_pago_listrecs, qualitas_api_api_rest_link_de_pago_fareceipt, qualitas_api_opl_servicios_web_opllistreceipts, qualitas_api_opl_servicios_web_oplconciliation, entity_agente_conciliacion [INFERRED 0.85]
- **Pipeline de backup n8n** — superpowers_plans_2026_06_30_n8n_workflow_backup_gha_backup, superpowers_plans_2026_06_30_n8n_workflow_backup_backup_script, superpowers_plans_2026_06_30_n8n_workflow_backup_select_workflows, entity_n8n_api, entity_n8n_workflows_dir [EXTRACTED 1.00]
- **Funnel Google Ads -> Landing -> WhatsApp -> poliza -> pago** — entity_google_ads, entity_django, entity_n8n, entity_meta_cloud_api, entity_lead, entity_qualitas_api_soap [EXTRACTED 1.00]
- **Postgres compartida por Django, n8n y Dashboard** — entity_postgres, entity_django, entity_n8n, entity_dashboard [EXTRACTED 1.00]
- **Funciones de Insurmind: captacion, conversacion, cobranza, control** — marca_insurmind_tres_planos_captacion, marca_insurmind_tres_planos_conversacion, marca_insurmind_tres_planos_cobranza, marca_insurmind_tres_planos_control [EXTRACTED 1.00]

## Communities (75 total, 8 thin omitted)

### Community 0 - "Conciliación y METEPEC"
Cohesion: 0.06
Nodes (49): computeEstadoNegocio (FunnelV2.js), pages/api/db-leads.js (SQL_FUNNEL), Conciliación de leads_metepec por VIN en portal, Handoff Agente Conciliación — contexto leads_metepec, Reporte Conciliación: pólizas SIN CONCILIAR + cron diario stg, Cron diario conciliar.yml, Estado SIN CONCILIAR (total_recibos=0), Reporte Conciliación: leads_metepec creada en PROD (+41 more)

### Community 1 - "Entrega de cotización"
Cohesion: 0.05
Nodes (48): Handoff Juan — pdf_cotizacion_url en detalle de cotización, Fix: serializar pdf_cotizacion_url en la vista detalle, Handoff Juan — #110 entrega cotización quick reply, Fetch Quotation Document (httpRequest), Rama quoteDocumentAction? (entrega PDF por quick reply), Decisión — PDF cotización: header auth, no Postgres, Opción C: header de auth en la tool Get Quotation Data, api/cotizacion/detalle/ (api_obtener_detalle_cotizacion) (+40 more)

### Community 2 - "Descuentos y promoción STG→PROD"
Cohesion: 0.05
Nodes (40): WA Config Worker STG, Plan STG-OPERATIONAL-DUAL-MAIN@1.1.0, scripts/stg-operational-dual/manifest.json, Alberto, Arquitecto-IA-Qualitas, conversation_control_v1, detect-drift, docs/protocolos/monitores-arquitecto.md (+32 more)

### Community 3 - "Control humano e inventario BD"
Cohesion: 0.07
Nodes (42): Inventario de objetos de BD fuera de migraciones Django, Bug #5 — conversation_phase stuck en greeting, Bug #8 — _generar_bloque_492 sin teléfono, _generar_bloque_492, Migración 0032 archive PK archive_id, serve() del form de landing (qualitas/models.py), archivar_historial_chats (qualitas/utils.py), Bug #5 conversation_phase stuck en greeting (+34 more)

### Community 4 - "Parches del AI Agent"
Cohesion: 0.08
Nodes (42): Cláusula 9a Territorialidad (RC excluida en EUA/Canadá), Bloqueo M41 — RC EUA/Canadá contradice PDF, Parche M42 — no revivir oferta reintentar/agente, Regla EDGE CASE: no revivir oferta reintentar/derivar, Deducible Daños Materiales (Cláusula 1 BIS.2, varía por póliza), Parche M43 — deducible Daños Materiales conflacionado, Handoff Agente n8n — fix leak KB (#53) y [Nombre] (#54), Handoff Agente n8n — Agente MTP enganche METEPEC (+34 more)

### Community 5 - "Guiones de prueba E2E"
Cohesion: 0.07
Nodes (38): Descuento POR_VIN_40, Entorno PROD, HYL-WAI#174 fallback genérico de emisión, HYL-WAI#183 trazabilidad del historial, HYL-WAI#189 sesiones no se cierran / desempate active, HYL-WAI#192 sin red de error (errorWorkflow), HYL-WAI#197 RAG monólogo interno, HYL-WAI#207 liga de pago available (+30 more)

### Community 6 - "Conversation ID y QA"
Cohesion: 0.08
Nodes (28): Hallazgo QA: E2E shadow port #132, Gate qc: quick-reply (contrato 2), Bug Resolve Session: there is no parameter $3, Diagrama arquitectura de agentes (3 niveles), Diagrama arquitectura del sistema (funnel completo), Observabilidad (GA4 + Meta Business API), Agente QA, Gobernanza Contract-First S1–S5 (+20 more)

### Community 7 - "Núcleo de datos del funnel"
Cohesion: 0.10
Nodes (30): Lista de rescate (58 leads / 49 teléfonos), pages/api/conversation.js, Artefacto timezone whatsapp_sessions.created_at (+6h), policy_data roto (riesgo aceptado), Customer Journey — Dashboard de Leads, Mapeo conversation_phase ↔ estado Django ↔ término Hylant, Flujo de datos del ecosistema, Hitos derivados de n8n_chat_histories (+22 more)

### Community 8 - "Seguimiento y persistencia de datos"
Cohesion: 0.07
Nodes (27): Handoff Agente n8n — extender Monitor Quálitas, conversation_phase, qualitas-issues#43 (requiere_factura no persiste), LeadActionEvent, QBCImpresion (qbcenter), aibanez82/Agente-n8n:main/workflows/, Monitor Qualitas SIO PROD, WhatsApp Insurance Quotation Bot (+19 more)

### Community 9 - "Tracker y disciplina CLAUDE.md"
Cohesion: 0.08
Nodes (17): Parte de 48 horas — artefacto vivo, Parte de 48 horas (artefacto), Tablero Dual Rollout — STG (retirado), Barrido de honestidad del tracker 8 ago, Veredicto en vivo por issue (crítico/alto), Origen de las convenciones de CLAUDE.md, Bug #7 — Django no escribe estatus_pago = PAGADO, Bug #7 (estatus pago) (+9 more)

### Community 10 - "RC4 en C#"
Cohesion: 0.11
Nodes (10): cotiza_seguros.Services.Qualitas, EncoderMode, Base64Encoder, HexEncoder, RC4CryptoService, encoderMode, encoding, Key (+2 more)

### Community 11 - "Migración STG y grants"
Cohesion: 0.09
Nodes (15): Bitácora promoción STG→PROD, Manual de migración a STG — aprendizajes S1, n8n_outbound_dispatch.request_hash — qué garantiza, Arquitectura — Dashboard de Leads (OBSOLETO), readonly_leads — propuesta de grants acotados, BBDD espejo — propuesta original (superada), BBDD Espejo — Decisión de Arquitectura, Heroku Postgres (+7 more)

### Community 12 - "Checkpoint C1 blocked"
Cohesion: 0.11
Nodes (18): scripts/s1-c1/lib/binding.js, scripts/s1-c1/build-candidate.js, Contrato C1-N8N-CAPABILITIES (1.0.0/1.0.1/1.0.2), scripts/s1-c1/lib/operativa.js, scripts/s1-c1/profile-cli.js, scripts/s1-c1/lib/rutas-privadas.js, Checkpoint de import blocked C1, Ventana recovery-only durable (+10 more)

### Community 13 - "Constancia fiscal y multi-aseguradora"
Cohesion: 0.14
Nodes (18): Meta / WhatsApp Business API — Acceso y Limitaciones, Entorno staging (STG), Hostinger, Hylant, Meta WhatsApp Cloud/Graph API, whatsapp_sessions.captured_data, Derivación CURP → fecha_nacimiento + género (determinista), Diseño integración Constancia de Situación Fiscal en n8n (+10 more)

### Community 14 - "Aislamiento STG/PROD de Meta"
Cohesion: 0.20
Nodes (19): Handoff fase E2E staging Bug #10 (v2 OAuth2), Handoff import workflow Bug #10 a staging, Mensaje a Juan: Meta App de staging, Handoff URGENTE verificar cruce prod/stg, Handoff verificación aislamiento staging, Handoff Bug #15 verificar payload crudo, wamid idéntico STG/PROD, Mensaje a Juan: número test comparte webhook prod (+11 more)

### Community 15 - "Contract-First #132"
Cohesion: 0.20
Nodes (18): Reporte a Juan: estado port #132 (28 jul), Contrato cruzado C1-C3, Harness Postgres local (sabores actual/objetivo), Port dual-safe de workflows n8n (#132), Reporte a Juan: port #132 completo lado n8n, Ventana de deploy (Fase 7), Guion checkpoint con Juan 30 jul, GO/NO-GO ventana viernes (+10 more)

### Community 16 - "Pasarela de pago Quálitas"
Cohesion: 0.15
Nodes (18): generar_link_pasarela() (qualitas/services.py), HYL-WAI:docs/qualitas-documentacion-webservices/, pagos.qualitas.com.mx/api.php, API REST — Link de Pago / Servicios en Línea (Quálitas), fareceipt, genlink, genlinkSMS, genlinkWSP (+10 more)

### Community 17 - "Bug 12 inbound caído"
Cohesion: 0.15
Nodes (13): Borrado de 12 duplicados (15→3 workflows), Handoff n8n Bug #12 inbound caído, Alerta de inbound caído, Mensaje Dashboard: inbound Meta→n8n caído, Rescate de leads 1046–1103, Respuesta a Dashboard: Bug #12 resuelto, Bug #12 — Inbound Meta→n8n caído, wamid idéntico en STG y PROD (+5 more)

### Community 18 - "Bug 10 VIN"
Cohesion: 0.15
Nodes (12): Decisión Arquitecto deploy Bug #10, Handoff despliegue Bug #10 (VIN) en lockstep, Mensaje a Juan: deploy validación VIN, Propuesta Agente n8n: reconciliación + deploy Bug #10, Bug #10 — VIN↔ciudad en Issue_Policy, deploy-bug10-prod.sh, Bug #10 (ciudad en lugar de VIN), Issue #83 (VIN) (+4 more)

### Community 19 - "Monitoreo E2E"
Cohesion: 0.18
Nodes (13): Issue #74 follow-up 15 min, Pitch Insurmind 30 segundos, Guion ElevenLabs, Storyboard del video ~35 s, Agente-Monitoreo (aibanez82/Agente-Monitoreo), Diseño Sistema de Monitoreo E2E, Tres pilares: uptime, emisión, integridad de datos, Digest diario (dead man's switch) (+5 more)

### Community 20 - "Checkpoint followups"
Cohesion: 0.23
Nodes (15): Respuesta a Juan — verificación checkpoint_followups en STG, Gap: conversation_id gana sobre session_id en Retomar Conversación, Migración 0041_lead_checkpoint_followups, Handoff Juan — checkpoint_followups a producción, Guard whatsapp_sessions.status en elegibilidad, Interpolación {vehiculo}/{precio} en render_policy_message, Filtro horario 9am-8pm CDMX (outside_business_hours), checkpoint_followups (+7 more)

### Community 21 - "Timestamps y E2E descuentos"
Cohesion: 0.16
Nodes (14): n8n_chat_histories — columna created_at, HYL-WAI#87 created_at, Landing Wagtail/Django, n8n_chat_histories, Checkpoint quote_sent attempt 2 con oferta, Caso de prueba E2E Descuentos STG, El disparador real es la intención de precio, Plan y acta E2E Descuentos STG (+6 more)

### Community 22 - "Marca Insurmind"
Cohesion: 0.24
Nodes (12): Anthropic / Claude, Cinco barreras deterministas (infraestructura, no prompt), Foso: correcciones con conversaciones reales, Insurmind, HYL-WAI#241 (envío proactivo cobranza), Insurmind no es un core asegurador, Titular "Cotiza, resuelve, emite y cobra. Sin intervención.", Adenda diagrama de arquitectura Insurmind (+4 more)

### Community 23 - "Despliegue STG a PROD julio"
Cohesion: 0.16
Nodes (13): Validación E2E Bug #10 en staging, Remap de credenciales prod→STG, Transform a forma de import {name,nodes,connections,settings}, Identificadores de PROD que no deben aparecer en staging, Columna rate_limit_data, Schema drift prod/staging, Plan de despliegue a producción 14 jul, Snapshot PROD 901347b (rollback) (+5 more)

### Community 24 - "Fallos de emisión"
Cohesion: 0.15
Nodes (12): Hallazgo canal LANDING vs WHATSAPP, canal_atencion LANDING vs WHATSAPP, Bug #9 — /api/emitir-externo/ HTTP 400, POST /api/emitir-externo/, Nodo Issue Policy, Bug #1 (sesiones sin historial), Bug #9 (400 genérico emitir-externo), qualitas_asegurado (+4 more)

### Community 25 - "Gobernanza funnel #135"
Cohesion: 0.21
Nodes (12): Revisión plan funnel Fase 1 (HYL-WAI#135), Plan de arquitectura de funnel de leads Fase 1, Revisión plan funnel v2 de Juan, Gobernanza Contract-First, HYL-WAI#135 Plan funnel Fase 1, HYL-WAI#143, HYL-WAI#146, Monitor oilycoyote (+4 more)

### Community 26 - "Bugs de sesión"
Cohesion: 0.21
Nodes (10): NumeroPruebaWhatsapp (tabla inexistente en prod), WhatsApp — Mejoras de Conversación Pendientes, Bug #3 — TEST_EMAILS no filtrados en n8n, Bug #4 — Leads reales sin whatsapp_session, Bug #11 — Sesión pegada a la 1ª cotización, Bugs conocidos — índice y registro completo, Bug #2 (prefijo 52/57 session_id), Bug #3 TEST_EMAILS no filtrados (+2 more)

### Community 27 - "Preguntas para Hylant"
Cohesion: 0.18
Nodes (12): #293 suma asegurada (bot se calla), #301 descuento 40%, #320 Limitada incendio/inundación, #326 meses sin intereses, #333 conducir sin licencia, Laura (Hylant), Portal Q 360, Caso de prueba completo en PROD (+4 more)

### Community 28 - "Acreditación S1"
Cohesion: 0.24
Nodes (10): Entorno STG, Checkpoint materialización par sintético A/B (S1), Bug estado="nuevo" inexistente en ESTADOS_LEAD, scripts/s1-fixtures/materializar-par-ab.py, Par sintético A/B mismo teléfono, Runbook acreditación y checkpoint STG de S1, Rollback §9 S1, S1_DASHBOARD_MODE (blocked/read_only) (+2 more)

### Community 29 - "Trigger WhatsApp y guardas"
Cohesion: 0.20
Nodes (10): Diff anti-divergencia stg vs prod, scripts/deploy-bug10-prod.sh, Secuencia PUT + POST /activate (n8n API), Meta App dedicada a staging (hyl-wai-stg), Phone Number Guard (IF phone_number_id), Send message, Session Context Builder, WhatsApp Message Trigger (+2 more)

### Community 30 - "Cobranza y recordatorios de pago"
Cohesion: 0.20
Nodes (11): Reemisión manual de pólizas con serie inválida, docs/qualitas-api/api-rest-link-de-pago.md, HYL-WAI#144 (recordatorios de pago), Quálitas, Iniciativa Recordatorios de pago por WhatsApp, genlinkWSP/genlinkSMS (Quálitas envía por su canal), m=genWebPay, Hitos D-7, D-48h, D-24h, D-0 (+3 more)

### Community 31 - "Session ID en Dashboard"
Cohesion: 0.21
Nodes (10): Track A: Django conversation_id en shadow, Contrato S1-DUAL-STG v1.1, Conversation ID (WhatsApp/n8n), Heroku hyl-wai-production, Propuesta whatsapp_event canónico, Inventario usos de session_id en el Dashboard, dashboard_message_audit, lib/s1/* (resolve/identity/retomarBuilder) (+2 more)

### Community 32 - "Tubería de mejoras de copy"
Cohesion: 0.21
Nodes (7): Agente Mejoras Conversación, Nodo AI Agent (systemMessage), Detectores de hito por LIKE, HYL-WAI#251 ¿y la limitada?, Rol readonly_leads, GRANT SELECT de claims a n8n/readonly_leads (bloqueante), Protocolo Agente Mejoras Conversación

### Community 33 - "Monitores y protocolo n8n"
Cohesion: 0.18
Nodes (7): Canal dudas/, Protocolo Agente n8n, Monitores de sesión del Arquitecto, m2 — comentarios e issues nuevos HYL-WAI, m4 — dudas de ejecutores, m5 — informes entregados, m6 — releases Heroku STG y PROD

### Community 34 - "Atención humana S3"
Cohesion: 0.24
Nodes (11): HYL-WAI#128, Mirrors human_takeover / metepec_derived, Atencion Humana workflow, C0 Baseline y freeze opción C, S3 Input pre-freeze para el contrato, Ocho ambigüedades S3 (A1–A8), sent_by: human_agent, Modo runtime nuevo (take_send) fail-closed (+3 more)

### Community 35 - "Alcance del bot"
Cohesion: 0.18
Nodes (8): Handoff Bug #14 deflect fuera de alcance, Bug #14 — Deflect fuera de alcance, SECURITY RULE #4 del systemMessage, Bug #20 — Carrera doble-submit vs reset de sesión, AI Agent (n8n), Bug #14 (deflect fuera de alcance), qualitas-issues#20, Intent Router

### Community 36 - "Eventos WhatsApp y follow-up"
Cohesion: 0.20
Nodes (10): Propuesta tabla canónica whatsapp_event, Bug #13 — Follow-up con precio de otra forma de pago, Recargo por forma de pago fraccionada, Bug #13, Plantilla cotizacion_followup_15m, qualitas_whatsappmessage, Spec — conversación WA completa en una línea de tiempo, Spec — Dashboard muestra envíos reales de WhatsApp (+2 more)

### Community 37 - "Plan C0–C9 #140"
Cohesion: 0.25
Nodes (6): Dossier auditor externo — giro Contract-First, C1 — Auditoría primaria (SRC-ALBERTO-C1-002), C1 — Génesis y economía del plan opción C (SRC-ALBERTO-C1-003), HYL-WAI#140 plan C0–C9, Monitor oilycoyote, Borrador checkpoint operativo C1 (NO-GO)

### Community 38 - "Payment Confirmation y freeze"
Cohesion: 0.24
Nodes (10): POST /api/emitir-externo/, Issue Policy Guard (sub-workflow), Metepec Liberar workflow, METEPEC Registrar Lead workflow, Payment Confirmation, Runbook import STG #156, Trampa de webhookId en import, Freeze de SHAs, workflows STG y flags (+2 more)

### Community 39 - "Backup de workflows n8n"
Cohesion: 0.24
Nodes (9): Política de backup de workflows n8n, Backup automático de workflows n8n (descontinuado), Red de seguridad Agente-n8n:main/workflows, n8n REST API, N8N_API_KEY, docs/n8n-workflows/ (retirado), backup.mjs (n8n-backup), n8n Workflow Backup Automation Implementation Plan (+1 more)

### Community 40 - "Merge por estado"
Cohesion: 0.20
Nodes (7): HYL-WAI#179, aguayo-co/HYL-WAI, Tablas lead_cobranza_import / row / contacto, Migración Django 0033 whatsapp_conversation_id_phase2, Nomenclatura de issues por área funcional, Catálogo de prefijos de área (DCTO_, INFRA_, CONV_, PAY_, EMIS_, WA_, DASH_, DATA_), Regla de merge por estado de la rama

### Community 41 - "Emisión vía webservice"
Cohesion: 0.22
Nodes (10): Documentación Quálitas Servicios Web v3.0, Método obtenerNuevaEmision, WsEmision (cotización/emisión SOAP), Resumen Consideraciones Identificación del Cliente (Art. 492), Identificación del cliente Art. 492 (persona física/moral), Análisis del Esquema de Emisión vía Web Services, Movimientos y esquema XML de emisión, Documentación Quálitas Servicios Web v3.0 (copia) (+2 more)

### Community 42 - "Validación VIN y placas"
Cohesion: 0.25
Nodes (8): Capa 2: mapeo rígido de serie, neverError:true en Issue Policy, Regex canónica VIN-17, Gate vehicle_series.py (400 invalid_vehicle_serie), Regex placas /^[A-Z0-9]{6,7}$/, /api/emitir-externo/, Issue Policy, Validate Personal Data

### Community 43 - "STOP S1 Dashboard"
Cohesion: 0.22
Nodes (7): Agente Conversion (futuro), Alberto Ibáñez, handleLegacyProd (n8n-proactive-message.js), VALID_SESSION_PREFIXES [52,57,1], Acuse del STOP S1 (Dashboard=AFECTADO), LeadModal.js fallback 52+telefono, STOP de S1-DUAL-STG v1.0.0 (Dashboard=AFECTADO)

### Community 44 - "Pendientes de infraestructura"
Cohesion: 0.25
Nodes (6): Apagón silencioso, Historial de pendientes de infraestructura resueltos, Timezone — hallazgo, DDL y auditoría, HYL-WAI#69, Issue #74 (follow-up 15 min caído), S2-F2: PAGO_CONFIRMADO no expresable

### Community 45 - "Juan y envío real"
Cohesion: 0.56
Nodes (9): Handoff Juan — activar envío real checkpoint_followups, Handoff Juan — envío real sin filtro horario (20 jul), Handoff Juan — envío real de noche (21 jul), Handoff Juan — filtro horario 9am-8pm CDMX, WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED / DRY_RUN_DEFAULT, Advanced Scheduler (Heroku, cada 5 min), hyl-wai-production (Heroku), Iniciativa Seguimiento leads estancados (+1 more)

### Community 46 - "Webhooks proactivos STG"
Cohesion: 0.22
Nodes (8): Bug #16 — WEBHOOK_URL/N8N_TOKEN STG = PROD, WEBHOOK_URL / N8N_TOKEN, Bug #17 — Tomar conversación en STG dispara WA por PROD, Guard VERCEL_ENV, pages/api/n8n-proactive-message.js, Bug #16, Bug #17, Payment Confirmation workflow

### Community 47 - "Contrato S2"
Cohesion: 0.28
Nodes (8): Contrato S2 estados/control mínimos v1, HYL-WAI#119 (emitir-externo), HYL-WAI#130 N8N_TOKEN, qualitas-issues#57 doble respuesta humano/bot, Borradores S2 para decisión, 10 ambigüedades pre-freeze S2, Hallazgo: emitir-externo acepta escritura sin credencial, S2 Preparación offline del Arquitecto

### Community 48 - "OPL cobranza SOAP"
Cohesion: 0.22
Nodes (9): derivar_poliza_opl() (qualitas/services.py), Redirect usucces/ufail (pago_exitoso), Cargo en línea (CL) server-side, getRefOpl, oplCancelation, oplCollection, oplConciliation, oplEdition (+1 more)

### Community 49 - "Diagrama tres planos"
Cohesion: 0.28
Nodes (8): Qualitas API SOAP (emision de polizas), Captacion (landings propias y posicionadas), Cobranza (recibo por vencer y liga de pago), Control (conversion y embudo), Insurmind tres planos (diagrama de marca), Plano El asegurado - canales (landing personalizada, WhatsApp), Plano Las aseguradoras (tarificacion, emision, pagos; una o varias), Plano Insurmind: cotiza, resuelve, emite y cobra sin intervencion

### Community 50 - "Bug 6 placas"
Cohesion: 0.25
Nodes (8): SECURITY RULES / LIMITACIÓN DE ALCANCE (systemMessage), Handoff Bug #6 regex placas 6-7 caracteres, Bug #6 — Regex placas rechaza 6 caracteres, placasRegex /^[A-Z0-9]{6,7}$/, Nodo Validate Personal Data, Bug #6 (regex placas), HYL-WAI#2 (placas), AI Agent

### Community 51 - "Recordatorios por fecha"
Cohesion: 0.32
Nodes (7): subscribed_apps de WABA (limpio), Handoff Juan — recordatorios por fecha mencionada, Categorías vencimiento_1mes / quincena / fecha_explicita, Claude Haiku, Iniciativa Recordatorios por fecha mencionada, Meta WhatsApp Cloud API, Plantilla Meta de re-enganche/recordatorio

### Community 54 - "Script fareceipt"
Cohesion: 0.25
Nodes (4): casos, { execSync }, https, wptoken

### Community 57 - "Identificación del cliente"
Cohesion: 0.48
Nodes (7): Catálogos (Tipo de Persona, Ocupación, Parentesco, Entidad Federativa, Nacionalidad, Tipo de Identificación), Consideraciones Asegurado, Consideraciones Contratante, Resumen Consideraciones Identificación del Cliente (Servicio Web), Persona Física, Persona Moral, Atributos RFC / CURP del cliente

### Community 58 - "Consolidación de workflows"
Cohesion: 0.47
Nodes (6): Consolidación de workflows n8n + convención anti-colisión, Instancia n8n PROD (n8n.srv1325340), Payment Confirmation (disvKr7iVhnNnefuiqJbJ), Retomar Conversacion (96XfJZcwvlHnVJLko3G8-), WhatsApp Insurance Quotation Bot, selectWorkflows / WORKFLOW_MAP (select-workflows.mjs)

### Community 59 - "Alcance de cotización"
Cohesion: 0.53
Nodes (5): Alcance de una cotización: coberturas, deducible, vigencia, Plan n8n: parar la mentira / mirar cotización / carril determinista, QUOTE-SCOPE-CONTEXT v1.0.0, tipo_suma=2 ausente del catálogo, HYL-WAI#194 QUOTE-SCOPE-CONTEXT

### Community 60 - "Ciclo autónomo #132"
Cohesion: 0.33
Nodes (4): Canal handoffs/, Ciclo autónomo de iteración port #132, /loop del Agente n8n sobre handoffs 6.8.x, m3 — pushes de ejecutores (todas las refs)

### Community 61 - "Plataformas de conversación"
Cohesion: 0.33
Nodes (5): Ventana 24h de Meta, Evaluación plataformas de conversación WhatsApp, Botpress (evaluar a medio plazo), OpenWA (descartado), Política de IA de WhatsApp (enero 2026)

### Community 62 - "Captura de voz backlog"
Cohesion: 0.73
Nodes (3): Plan implementación backlog captura de voz, Diseño backlog captura de voz Telegram→Claude→Notion, Workflow n8n Telegram→Whisper→Claude→Notion

### Community 63 - "Link de pago y OPL"
Cohesion: 0.40
Nodes (6): API REST Link de Pago v1.4, genWebPay — pasarela con usucces/ufail, Credenciales wptoken/merchant/privatekey, Servicio Web OPL v1.3.2, oplCollection — instalación de cobranza, Servicios OPL: cancelación, edición, pago referenciado, listado de recibos

### Community 64 - "Agente CSF"
Cohesion: 0.70
Nodes (4): Agente CSF — extracción Constancia Situación Fiscal, Mismatch límite PDF 5MB código vs 2MB bucket, insurmind_extractor (Agente CSF), Supabase

### Community 65 - "Detección batch de fechas"
Cohesion: 0.60
Nodes (4): Heroku Scheduler, Categorías vencimiento_1mes / quincena / fecha_explicita, Recordatorios de seguimiento por fecha mencionada, Lead 1385 / cotización 2837 (caso real)

### Community 66 - "Workflow proactivo"
Cohesion: 0.60
Nodes (4): Meta WhatsApp Cloud API, Workflow proactivo — mensajes desde Dashboard, Ventana de 24h de Meta, Webhook POST /webhook/proactive-wa-message

### Community 67 - "S1 v1.1 Dashboard"
Cohesion: 0.67
Nodes (3): S1 v1.1 Prep offline dominio Dashboard, Alcance mínimo v1.1 (6 puntos), Suite de conformidad Dashboard (espejo scripts/s1)

### Community 68 - "WSTARIFAS"
Cohesion: 0.50
Nodes (4): WSTARIFAS — Web Service Tarifas Quálitas, listaMarcas, listaTarifas, wsTarifa.asmx (qbcenter)

### Community 69 - "Tarifas (resumen)"
Cohesion: 0.67
Nodes (3): Web Service Tarifas, Método listaMarcas, Método listaTarifas

### Community 70 - "WSIMPRESION"
Cohesion: 1.00
Nodes (3): WSIMPRESION — Web Service Impresión Quálitas, QBCImpresion/Service.asmx (QA y PROD), Recupera Impresión M15

## Ambiguous Edges - Review These
- `n8n` → `Webhook 1: lead creado (Django -> n8n)`  [AMBIGUOUS]
  diagrama-arquitectura-sistema.svg · relation: calls
- `Django (HYL-WAI)` → `Webhook 1: lead creado (Django -> n8n)`  [AMBIGUOUS]
  diagrama-arquitectura-sistema.svg · relation: calls

## Knowledge Gaps
- **188 isolated node(s):** `cotiza_seguros.Services.Qualitas`, `Key`, `encoding`, `encoderMode`, `RC4` (+183 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 269 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `n8n` and `Webhook 1: lead creado (Django -> n8n)`?**
  _Edge tagged AMBIGUOUS (relation: calls) - confidence is low._
- **What is the exact relationship between `Django (HYL-WAI)` and `Webhook 1: lead creado (Django -> n8n)`?**
  _Edge tagged AMBIGUOUS (relation: calls) - confidence is low._
- **Why does `Juan Aguayo` connect `Juan y envío real` to `Conciliación y METEPEC`, `Entrega de cotización`, `Descuentos y promoción STG→PROD`, `Control humano e inventario BD`, `Parches del AI Agent`, `Guiones de prueba E2E`, `Conversation ID y QA`, `Seguimiento y persistencia de datos`, `Aislamiento STG/PROD de Meta`, `Contract-First #132`, `Pasarela de pago Quálitas`, `Bug 10 VIN`, `Checkpoint followups`, `Timestamps y E2E descuentos`, `Fallos de emisión`, `Gobernanza funnel #135`, `Bugs de sesión`, `Trigger WhatsApp y guardas`, `Session ID en Dashboard`, `Monitores y protocolo n8n`, `Atención humana S3`, `Plan C0–C9 #140`, `Payment Confirmation y freeze`, `Merge por estado`, `STOP S1 Dashboard`, `Recordatorios por fecha`, `Estándar adversarial`, `Ciclo autónomo #132`, `Captura de voz backlog`, `Detección batch de fechas`?**
  _High betweenness centrality (0.167) - this node is a cross-community bridge._
- **Why does `Agente n8n` connect `Aislamiento STG/PROD de Meta` to `Conciliación y METEPEC`, `Entrega de cotización`, `Descuentos y promoción STG→PROD`, `Control humano e inventario BD`, `Parches del AI Agent`, `Guiones de prueba E2E`, `Conversation ID y QA`, `Seguimiento y persistencia de datos`, `Tracker y disciplina CLAUDE.md`, `Constancia fiscal y multi-aseguradora`, `Contract-First #132`, `Bug 12 inbound caído`, `Bug 10 VIN`, `Despliegue STG a PROD julio`, `Trigger WhatsApp y guardas`, `Tubería de mejoras de copy`, `Monitores y protocolo n8n`, `Alcance del bot`, `Plan C0–C9 #140`, `Payment Confirmation y freeze`, `Backup de workflows n8n`, `Juan y envío real`, `Bug 6 placas`, `Ciclo autónomo #132`?**
  _High betweenness centrality (0.146) - this node is a cross-community bridge._
- **Why does `Dashboard (Next.js)` connect `Conciliación y METEPEC` to `Entrega de cotización`, `Descuentos y promoción STG→PROD`, `Control humano e inventario BD`, `Conversation ID y QA`, `Núcleo de datos del funnel`, `Seguimiento y persistencia de datos`, `Tracker y disciplina CLAUDE.md`, `Migración STG y grants`, `Constancia fiscal y multi-aseguradora`, `Aislamiento STG/PROD de Meta`, `Contract-First #132`, `Bug 10 VIN`, `Monitoreo E2E`, `Timestamps y E2E descuentos`, `Marca Insurmind`, `Bugs de sesión`, `Session ID en Dashboard`, `Eventos WhatsApp y follow-up`, `Plan C0–C9 #140`, `Payment Confirmation y freeze`, `Merge por estado`, `Webhooks proactivos STG`, `Diagrama tres planos`, `Workflow proactivo`?**
  _High betweenness centrality (0.123) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Agente n8n` (e.g. with `Un viaje, una causa` and `Port dual-safe de workflows n8n (#132)`) actually correct?**
  _`Agente n8n` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `Dashboard (Next.js)` (e.g. with `computeEstadoNegocio (FunnelV2.js)` and `pages/api/db-leads.js (SQL_FUNNEL)`) actually correct?**
  _`Dashboard (Next.js)` has 5 INFERRED edges - model-reasoned connections that need verification._