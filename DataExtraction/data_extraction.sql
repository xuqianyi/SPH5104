WITH icu_info AS (
  SELECT
      DISTINCT icu.subject_id,
      icu.hadm_id,
      icu.stay_id,
      icu.intime,
      icu.outtime,
      TIMESTAMP_DIFF(icu.outtime, icu.intime, SECOND) / (60 * 60 * 24) AS icu_length_of_stay,
      age.age,
      weight.weight,
      rank()
      OVER (
        PARTITION BY icu.subject_id
        ORDER BY icu.intime)  AS icustay_id_order
  FROM physionet-data.mimiciv_icu.icustays icu
      JOIN physionet-data.mimiciv_derived.age age ON icu.subject_id = age.subject_id AND icu.hadm_id=age.hadm_id
      JOIN physionet-data.mimiciv_derived.first_day_weight weight ON icu.subject_id = weight.subject_id AND icu.stay_id=weight.stay_id
),

icu_selected AS(
  SELECT *
  FROM icu_info
  WHERE icustay_id_order=1
    AND age>=18
    AND stay_id IN (SElECT stay_id from physionet-data.mimiciv_derived.ventilation WHERE ventilation_status='InvasiveVent')
    AND subject_id IN (
      SELECT DISTINCT subject_id
      FROM physionet-data.mimiciv_derived.bg
      WHERE pao2fio2ratio<=300
)),

icu_propofol AS(
  SELECT DISTINCT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        weight,
        SUM(timestamp_diff(ie.endtime, ie.starttime, SECOND)) / 3600.0 AS duration_hours,
        AVG(ie.rate) / 1000.0 * 60.0 AS avg_dose,
        MAX(ie.rate) / 1000.0 * 60.0 AS max_dose
    FROM icu_selected icu
      JOIN physionet-data.mimiciv_icu.inputevents ie ON icu.subject_id = ie.subject_id AND icu.hadm_id = ie.hadm_id AND icu.stay_id = ie.stay_id
WHERE ie.itemid IN (226224, 227210, 222168) -- Propofol itemids
  AND ie.starttime >= TIMESTAMP_ADD(icu.intime, INTERVAL 8 HOUR) -- Starts after 8 hours of ICU intime
  AND NOT EXISTS ( -- Ensure no use of other sedatives
      SELECT 1
      FROM physionet-data.mimiciv_icu.inputevents other_ie
      WHERE other_ie.subject_id = icu.subject_id
        AND other_ie.hadm_id = icu.hadm_id
        AND other_ie.stay_id = icu.stay_id
        AND other_ie.itemid IN (225150, 229420, 221668, 221385) -- Other sedatives itemids
    )
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        weight
HAVING duration_hours > 0
),

icu_delirium AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay AS icu_length_of_stay_day,
        age,
        weight,
        duration_hours,
        avg_dose,
        max_dose,
      CASE
        WHEN SUM(CASE WHEN ce.itemid IN (228300, 228337, 229326) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228301, 228336, 229325) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228302, 228334, 228303, 228335, 229324) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS delirium
    FROM icu_propofol icu
      JOIN physionet-data.mimiciv_icu.chartevents ce ON icu.subject_id = ce.subject_id AND icu.hadm_id = ce.hadm_id AND icu.stay_id = ce.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        weight,
        duration_hours,
        avg_dose,
        max_dose
),

gcs_agg AS (
    SELECT 
        stay_id, 
        AVG(g.gcs) AS avg_gcs, 
        AVG(g.gcs_motor) AS avg_gcs_motor, 
        AVG(g.gcs_verbal) AS avg_gcs_verbal, 
        AVG(g.gcs_eyes) AS avg_gcs_eyes
    FROM 
        physionet-data.mimiciv_derived.gcs g
    GROUP BY 
        stay_id
),
od_agg AS (
    SELECT 
        stay_id, 
        AVG(o2_flow) AS avg_o2_flow, 
        AVG(o2_flow_additional) AS avg_o2_flow_additional
    FROM 
        physionet-data.mimiciv_derived.oxygen_delivery
    GROUP BY 
        stay_id
),
sapsii_agg AS (
    SELECT 
        stay_id, 
        AVG(s.sapsii) AS avg_sapsii, 
        AVG(s.sapsii_prob) AS avg_sapsii_prob
    FROM 
        physionet-data.mimiciv_derived.sapsii s
    GROUP BY 
        stay_id
),
sofa_agg AS (
    SELECT 
        stay_id, 
        AVG(s.uo_24hr) AS avg_uo_24hr, 
        AVG(s.meanbp_min) AS avg_meanbp_min
    FROM 
        physionet-data.mimiciv_derived.sofa s
    GROUP BY 
        stay_id
),
vitalsign_agg AS (
    SELECT 
        stay_id, 
        AVG(v.heart_rate) AS avg_heart_rate, 
        AVG(v.mbp) AS avg_mbp,
        AVG(v.resp_rate) AS avg_resp_rate,
        AVG(v.temperature) AS avg_temperature,
        AVG(v.spo2) AS avg_spo2,
        AVG(v.glucose) AS avg_glucose,
    FROM 
        physionet-data.mimiciv_derived.vitalsign v
    GROUP BY 
        stay_id
)



SELECT delirium, icu.subject_id, icu.hadm_id, icu.stay_id, icu_length_of_stay_day, age, weight, duration_hours, avg_dose, max_dose,
        icud.gender,
        avg_gcs, avg_gcs_motor, avg_gcs_verbal, avg_gcs_eyes,
        avg_o2_flow, avg_o2_flow_additional,
        avg_sapsii, avg_sapsii_prob,
        avg_uo_24hr, avg_meanbp_min,
        avg_heart_rate, avg_mbp,avg_resp_rate,avg_temperature,avg_spo2, avg_glucose,
        hosp.admission_type, hosp.insurance, hosp.marital_status, hosp.race
FROM icu_delirium icu
  LEFT JOIN physionet-data.mimiciv_derived.icustay_detail icud ON icu.stay_id=icud.stay_id
  LEFT JOIN gcs_agg gcs ON icu.stay_id=gcs.stay_id
  LEFT JOIN od_agg od ON icu.stay_id=od.stay_id
  LEFT JOIN sapsii_agg sa ON icu.stay_id=sa.stay_id
  LEFT JOIN sofa_agg so ON icu.stay_id=so.stay_id
  LEFT JOIN vitalsign_agg vt ON icu.stay_id=vt.stay_id
  LEFT JOIN physionet-data.mimiciv_hosp.admissions hosp ON icu.hadm_id=hosp.hadm_id
;