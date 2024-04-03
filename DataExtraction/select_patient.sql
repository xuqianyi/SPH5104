WITH icu_info AS (SELECT
      distinct icu.subject_id,
      icu.hadm_id,
      icu.stay_id,
      icu.intime,
      icu.outtime,
      TIMESTAMP_DIFF(icu.outtime, icu.intime, SECOND) / (60 * 60 * 24) AS icu_length_of_stay,
      age.age,
      rank()
      OVER (
        PARTITION BY icu.subject_id
        ORDER BY icu.intime )                                      AS icustay_id_order
    FROM physionet-data.mimiciv_icu.icustays icu
      JOIN physionet-data.mimiciv_hosp.patients pat ON icu.subject_id = pat.subject_id
      JOIN physionet-data.mimiciv_derived.age age ON icu.subject_id = age.subject_id AND icu.hadm_id=age.hadm_id
    WHERE icu.stay_id in (SElECT stay_id from physionet-data.mimiciv_derived.ventilation WHERE ventilation_status='InvasiveVent') 
    and icu.subject_id in (select distinct ce.subject_id
from physionet-data.mimiciv_icu.chartevents ce, physionet-data.mimiciv_derived.bg bg
where ce.subject_id=bg.subject_id 
  and ce.hadm_id=bg.hadm_id
  and ce.charttime=bg.charttime
  and ce.subject_id=bg.subject_id 
  and ce.hadm_id=bg.hadm_id
  and bg.po2/bg.fio2<=300))

SELECT *
FROM icu_info
WHERE icustay_id_order=1
AND age>=18;