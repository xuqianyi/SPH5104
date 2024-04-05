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

icu_DEX AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0 THEN 1
        WHEN SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 0
        ELSE NULL
        END AS DEX,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS bothDEX_other
    FROM icu_selected icu
      JOIN physionet-data.mimiciv_icu.inputevents ie ON icu.subject_id = ie.subject_id AND icu.hadm_id = ie.hadm_id AND icu.stay_id = ie.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age
),

icu_delirium AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other, 
      CASE
        WHEN SUM(CASE WHEN ce.itemid IN (228300, 228337, 229326) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228301, 228336, 229325) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228302, 228334, 228303, 228335, 229324) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS delirium
    FROM icu_DEX icu
      JOIN physionet-data.mimiciv_icu.chartevents ce ON icu.subject_id = ce.subject_id AND icu.hadm_id = ce.hadm_id AND icu.stay_id = ce.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other
)


SELECT *
FROM icu_delirium;WITH icu_info AS (
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

icu_DEX AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0 THEN 1
        WHEN SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 0
        ELSE NULL
        END AS DEX,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS bothDEX_other
    FROM icu_selected icu
      JOIN physionet-data.mimiciv_icu.inputevents ie ON icu.subject_id = ie.subject_id AND icu.hadm_id = ie.hadm_id AND icu.stay_id = ie.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age
),

icu_delirium AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other, 
      CASE
        WHEN SUM(CASE WHEN ce.itemid IN (228300, 228337, 229326) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228301, 228336, 229325) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228302, 228334, 228303, 228335, 229324) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS delirium
    FROM icu_DEX icu
      JOIN physionet-data.mimiciv_icu.chartevents ce ON icu.subject_id = ce.subject_id AND icu.hadm_id = ce.hadm_id AND icu.stay_id = ce.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other
)


SELECT *
FROM icu_delirium;
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

icu_DEX AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0 THEN 1
        WHEN SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 0
        ELSE NULL
        END AS DEX,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS bothDEX_other
    FROM icu_selected icu
      JOIN physionet-data.mimiciv_icu.inputevents ie ON icu.subject_id = ie.subject_id AND icu.hadm_id = ie.hadm_id AND icu.stay_id = ie.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age
),

icu_delirium AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other, 
      CASE
        WHEN SUM(CASE WHEN ce.itemid IN (228300, 228337, 229326) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228301, 228336, 229325) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228302, 228334, 228303, 228335, 229324) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS delirium
    FROM icu_DEX icu
      JOIN physionet-data.mimiciv_icu.chartevents ce ON icu.subject_id = ce.subject_id AND icu.hadm_id = ce.hadm_id AND icu.stay_id = ce.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other
)


SELECT *
FROM icu_delirium;
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

icu_DEX AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0 THEN 1
        WHEN SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 0
        ELSE NULL
        END AS DEX,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS bothDEX_other
    FROM icu_selected icu
      JOIN physionet-data.mimiciv_icu.inputevents ie ON icu.subject_id = ie.subject_id AND icu.hadm_id = ie.hadm_id AND icu.stay_id = ie.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age
),

icu_delirium AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other, 
      CASE
        WHEN SUM(CASE WHEN ce.itemid IN (228300, 228337, 229326) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228301, 228336, 229325) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228302, 228334, 228303, 228335, 229324) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS delirium
    FROM icu_DEX icu
      JOIN physionet-data.mimiciv_icu.chartevents ce ON icu.subject_id = ce.subject_id AND icu.hadm_id = ce.hadm_id AND icu.stay_id = ce.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other
)


SELECT *
FROM icu_delirium;
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

icu_DEX AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0 THEN 1
        WHEN SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 0
        ELSE NULL
        END AS DEX,
      CASE
        WHEN SUM(CASE WHEN ie.itemid IN (225150, 229420) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ie.itemid IN (226224, 227210, 222168, 221668, 221385) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS bothDEX_other
    FROM icu_selected icu
      JOIN physionet-data.mimiciv_icu.inputevents ie ON icu.subject_id = ie.subject_id AND icu.hadm_id = ie.hadm_id AND icu.stay_id = ie.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age
),

icu_delirium AS(
  SELECT icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other, 
      CASE
        WHEN SUM(CASE WHEN ce.itemid IN (228300, 228337, 229326) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228301, 228336, 229325) THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN ce.itemid IN (228302, 228334, 228303, 228335, 229324) THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
        END AS delirium
    FROM icu_DEX icu
      JOIN physionet-data.mimiciv_icu.chartevents ce ON icu.subject_id = ce.subject_id AND icu.hadm_id = ce.hadm_id AND icu.stay_id = ce.stay_id
GROUP BY
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.intime,
        icu.outtime,
        icu_length_of_stay,
        age,
        DEX,
        bothDEX_other
)


SELECT *
FROM icu_delirium;
