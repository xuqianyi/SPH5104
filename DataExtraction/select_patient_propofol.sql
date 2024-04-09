WITH icu_info AS (
  SELECT
      DISTINCT icu.subject_id,
      icu.hadm_id,
      icu.stay_id,
      icu.intime,
      icu.outtime,
      TIMESTAMP_DIFF(icu.outtime, icu.intime, SECOND) / (60 * 60 * 24) AS icu_length_of_stay,
      age.age,
      rank()
      OVER (
        PARTITION BY icu.subject_id
        ORDER BY icu.intime)  AS icustay_id_order
  FROM physionet-data.mimiciv_icu.icustays icu
      JOIN physionet-data.mimiciv_derived.age age ON icu.subject_id = age.subject_id AND icu.hadm_id=age.hadm_id
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
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        SUM(timestamp_diff(ie.endtime, ie.starttime, SECOND)) / 3600.0 AS duration_hours
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
        age
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
        duration_hours,
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
        duration_hours
)


SELECT *
FROM icu_delirium;