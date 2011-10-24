class Order < ActiveRecord::Base
  set_table_name :orders
  set_primary_key :order_id
  include Openmrs
  belongs_to :order_type, :conditions => {:retired => 0}
  belongs_to :concept, :conditions => {:retired => 0}
  belongs_to :encounter, :conditions => {:voided => 0}
  belongs_to :patient, :conditions => {:voided => 0}
  belongs_to :provider, :foreign_key => 'orderer', :class_name => 'User', :conditions => {:voided => 0}
  belongs_to :observation, :foreign_key => 'obs_id', :class_name => 'Observation', :conditions => {:voided => 0}
  has_one :drug_order # no default scope
  
  named_scope :current, :conditions => 'DATE(encounter.encounter_datetime) = CURRENT_DATE()', :include => :encounter
  named_scope :historical, :conditions => 'DATE(encounter.encounter_datetime) <> CURRENT_DATE()', :include => :encounter
  named_scope :unfinished, :conditions => ['discontinued = 0 AND auto_expire_date > NOW()']
  named_scope :finished, :conditions => ['discontinued = 1 OR auto_expire_date < NOW()']
  named_scope :arv, lambda {|order|
    arv_concept = ConceptName.find_by_name("ANTIRETROVIRAL DRUGS").concept_id
    arv_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', arv_concept])
    {:conditions => ['concept_id IN (?)', arv_drug_concepts.map(&:concept_id)]}
  }
  named_scope :labs, :conditions => ['drug_order.drug_inventory_id is NULL'], :include => :drug_order
  named_scope :prescriptions, :conditions => ['drug_order.drug_inventory_id is NOT NULL'], :include => :drug_order
  
  def after_void(reason = nil)
    # TODO Should we be voiding the associated meta obs that point back to this?
  end

  def to_s
    "#{drug_order}"
  end

  def self.prescriptions_without_dispensations_data(start_date , end_date)
      pills_dispensed_id      = ConceptName.find_by_name('PILLS DISPENSED').concept_id
      arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
      national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id

      missed_dispensations_data = self.find_by_sql(["SELECT order_id, patient_id, date_created from orders 
                   WHERE NOT EXISTS (SELECT * FROM obs
                   WHERE orders.order_id = obs.order_id AND obs.concept_id = ?)
                    AND date_created >= ? AND date_created <= ?", pills_dispensed_id, start_date , end_date ])

        prescriptions_without_dispensations = []

        missed_dispensations_data.each do |prescription|
         drug_id      = DrugOrder.find(prescription[:order_id]).drug_inventory_id
         arv_number   = PatientIdentifier.identifier(prescription[:patient_id], arv_number_id).identifier rescue ""
         national_id  = PatientIdentifier.identifier(prescription[:patient_id], national_identifier_id).identifier rescue ""
         drug_name    = Drug.find(drug_id).name

         prescriptions_without_dispensations << [prescription[:patient_id].to_s, arv_number , national_id,
                     prescription[:date_created].strftime("%Y-%m-%d %H:%M:%S") , drug_name]
        end

        prescriptions_without_dispensations
  end

  def self.dispensations_without_prescriptions_data(start_date , end_date)
      pills_dispensed_id      = ConceptName.find_by_name('PILLS DISPENSED').concept_id
      arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
      national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id

      missed_prescriptions_data = Observation.find(:all, :select =>  "person_id, value_drug, date_created",
                                                  :conditions =>["order_id IS NULL
                                                    AND date_created >= ? AND date_created <= ? AND
                                                        concept_id = ?" ,start_date , end_date, pills_dispensed_id])

        dispensations_without_prescriptions = []

        missed_prescriptions_data.each do |dispensation|
         drug_name    = Drug.find(dispensation[:value_drug]).name
         arv_number   = PatientIdentifier.identifier(dispensation[:person_id], arv_number_id)
         national_id  = PatientIdentifier.identifier(dispensation[:person_id], national_identifier_id)

         dispensations_without_prescriptions << [dispensation[:person_id].to_s, arv_number[:identifier].to_s, national_id[:identifier].to_s,
                     dispensation[:date_created].strftime("%Y-%m-%d %H:%M:%S") , drug_name]
        end

        dispensations_without_prescriptions
  end
  
  def to_s
    "#{drug_order}"
  end

  def self.treatement_orders(patient_id)

    treatment_encouter_id   = EncounterType.find_by_name("TREATMENT").id
    drug_order_id           = OrderType.find_by_name("DRUG ORDER").id
    diabetes_id             = Concept.find_by_name("DIABETES MEDICATION").id
    hypertensition_id       = Concept.find_by_name("HYPERTENSION").id

    self.find_by_sql("SELECT distinct orders.order_id, orders.concept_id,concept_name.name AS drug_name,obs.value_coded AS diagnosis_id,
                         MAX(auto_expire_date) AS end_date, MIN(start_date) AS start_date,
                         DATEDIFF(MAX(auto_expire_date), MIN(start_date))AS days,
                         DATEDIFF(NOW(), MIN(start_date)) days_so_far,
                        dose, drug.units, frequency
                        FROM obs
                        INNER JOIN encounter on encounter.encounter_id = obs.encounter_id
                        INNER JOIN orders on orders.encounter_id = encounter.encounter_id
                        INNER JOIN concept_name ON concept_name.concept_id = orders.concept_id
                        INNER JOIN drug_order ON drug_order.order_id = orders.order_id
                        INNER JOIN drug ON drug.drug_id = drug_order.drug_inventory_id
                        WHERE encounter_type = #{treatment_encouter_id} AND encounter.patient_id = #{patient_id}
                          AND encounter.voided = 0 AND orders.voided = 0
                          AND orders.order_type_id = #{drug_order_id} AND obs.value_coded IN (#{diabetes_id}, #{hypertensition_id})
                        GROUP BY order_id, obs.value_coded
                        ORDER BY drug_name, start_date DESC")
  end

  def self.aggregate_treatement_orders(patient_id)

    hypertensition_medication_id  = Concept.find_by_name("HYPERTENSION MEDICATION").id
    treatment_encouter_id         = EncounterType.find_by_name("TREATMENT").id
    drug_order_id                 = OrderType.find_by_name("DRUG ORDER").id
    diabetes_id                   = Concept.find_by_name("DIABETES MEDICATION").id
    hypertensition_id             = Concept.find_by_name("HYPERTENSION").id
    preffered_id                  = ConceptNameTag.find_by_tag("PREFERRED").id

    medication_query = "SELECT medication.drug_name AS drug_name,
      medication.days                             AS days,
      medication.units                            AS units,
      medication.dose                             AS formulation,
      SUM(medication.days_so_far)                 AS total_medication_days,
      MIN(medication.start_date)                  AS start_date,
      MAX(medication.end_date)                    AS end_date,
      medication.diagnosis_id                     AS diagnosis_id,
      DATEDIFF(NOW(), MIN(medication.start_date)) AS duration
      FROM (
        SELECT auto_expire_date AS end_date, concept_name.name AS drug_name,
          DATEDIFF(auto_expire_date, MIN(start_date)) AS days,
          DATEDIFF(NOW(), start_date) days_so_far,start_date AS start_date,
          dose, drug.units, frequency, obs.value_coded AS diagnosis_id,
          orders.concept_id AS concept_id, orders.order_id AS order_id
          FROM obs, encounter, orders, concept_name,drug_order, drug, concept_name_tag_map
          WHERE encounter_type        = #{treatment_encouter_id}
            AND encounter.patient_id  = #{patient_id}
            AND encounter.voided = 0
            AND orders.voided    = 0
            AND orders.order_type_id = #{drug_order_id}
            AND obs.value_coded IN (#{diabetes_id}, #{hypertensition_id}, #{hypertensition_medication_id})
            AND concept_name_tag_id = #{preffered_id}
            AND orders.encounter_id = encounter.encounter_id
            AND encounter.encounter_id  = obs.encounter_id
            AND concept_name.concept_id = orders.concept_id
            AND drug_order.order_id     = orders.order_id
            AND drug.drug_id = drug_order.drug_inventory_id
            AND concept_name_tag_map.concept_name_id = concept_name.concept_name_id
          GROUP BY auto_expire_date, 	concept_name.name, dose, drug.units, frequency,
                obs.value_coded, 	orders.concept_id, orders.order_id, start_date
          ORDER BY drug_name, start_date DESC) AS medication
      WHERE medication.end_date >= NOW()
      GROUP BY drug_name
      ORDER BY drug_name"

    self.find_by_sql(medication_query);
  end
end

