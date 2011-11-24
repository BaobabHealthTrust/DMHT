module MedicationService

  def self.arv(drug)
    arv_drugs.map(&:concept_id).include?(drug.concept_id)
  end

  def self.arv_drugs
    arv_concept       = ConceptName.find_by_name("ANTIRETROVIRAL DRUGS").concept_id
    arv_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', arv_concept])
    arv_drug_concepts
  end

  def self.tb_medication(drug)
    tb_drugs.map(&:concept_id).include?(drug.concept_id)
  end

  def self.tb_drugs
    tb_medication_concept       = ConceptName.find_by_name("Tuberculosis treatment drugs").concept_id
    tb_medication_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', tb_medication_concept])
    tb_medication_drug_concepts
  end

end
