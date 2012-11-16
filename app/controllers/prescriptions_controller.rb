class PrescriptionsController < GenericPrescriptionsController
  
  #data cleaning :- moved from patient.rb
  def current_diagnoses(patient_id)
    patient = Patient.find(patient_id)
    patient.encounters.current.all(:include => [:observations]).map{|encounter|
      encounter.observations.all(
        :conditions => ["obs.concept_id = ? OR obs.concept_id = ?",
          ConceptName.find_by_name("DIAGNOSIS").concept_id,
          ConceptName.find_by_name("DIAGNOSIS, NON-CODED").concept_id])
    }.flatten.compact
  end

  def load_frequencies_and_dosages
    drugs = MedicationService.dosages(params[:concept_id])
    render :text => drugs.to_json
  end
  
  def advanced_drug_details(drug_info)
    
    insulin = false
    if (drug_info[0].downcase.include? "insulin") && ((drug_info[0].downcase.include? "lente") ||
          (drug_info[0].downcase.include? "soluble")) || ((drug_info[0].downcase.include? "glibenclamide") && (drug_info[1] == ""))

      if(drug_info[0].downcase == "insulin, lente")     # due to error noticed when searching for drugs
        drug_info[0] = "LENTE INSULIN"
      end

      if(drug_info[0].downcase == "insulin, soluble")     # due to error noticed when searching for drugs
        drug_info[0] = "SOLUBLE INSULIN"
      end

      name = "%"+drug_info[0]+"%"
      insulin = true

    else

      # do not remove the '(' in the following string
      name = "%"+drug_info[0]+"%"+drug_info[1]+"%"

    end

    drug_details = Array.new

    concept_name_id = ConceptName.find_by_name("DRUG FREQUENCY CODED").concept_id

    drugs = Drug.find(:all, :select => "concept.concept_id AS concept_id, concept_name.name AS name,
        drug.dose_strength AS strength, drug.name AS formulation",
      :joins => "INNER JOIN concept       ON drug.concept_id = concept.concept_id
               INNER JOIN concept_name  ON concept_name.concept_id = concept.concept_id",
      :conditions => ["drug.name LIKE ? OR (concept_name.name LIKE ? AND COALESCE(drug.dose_strength, 0) = ? " +
          "AND COALESCE(drug.units, '') = ?)", name, "%" + drug_info[0] + "%", drug_info[3], drug_info[4]],
      :group => "concept.concept_id, drug.name, drug.dose_strength")

    # raise drugs.to_yaml
    
    unless(insulin)

      drug_frequency = drug_info[2].upcase rescue nil

      preferred_concept_name_id = Concept.find_by_name(drug_frequency).concept_id
      preferred_dmht_tag_id = ConceptNameTag.find_by_tag("preferred_dmht").concept_name_tag_id

      drug_frequency = ConceptName.find(:first, :select => "concept_name.name",
        :joins => "INNER JOIN concept_answer ON concept_name.concept_id = concept_answer.answer_concept
                                INNER JOIN concept_name_tag_map cnmp
                                  ON  cnmp.concept_name_id = concept_name.concept_name_id",
        :conditions => ["concept_answer.concept_id = ? AND concept_name.concept_id = ? AND voided = 0
                                  AND cnmp.concept_name_tag_id = ?", concept_name_id, preferred_concept_name_id, preferred_dmht_tag_id])

      drugs.each do |drug|

        drug_details += [:drug_concept_id => drug.concept_id,
          :drug_name => drug.name, :drug_strength => drug.strength,
          :drug_formulation => drug.formulation, :drug_prn => 0, :drug_frequency => drug_frequency.name]

      end

    else

      drugs.each do |drug|

        drug_details += [:drug_concept_id => drug.concept_id,
          :drug_name => drug.name, :drug_strength => drug.strength,
          :drug_formulation => drug.formulation, :drug_prn => 0, :drug_frequency => ""]

      end rescue []

    end

    drug_details

  end
 
  def advanced_prescription
    @patient = Patient.find(params[:patient_id] || params[:id] || session[:patient_id]) rescue nil

    @orders = MedicationService.current_orders(@patient) rescue []

    diabetes_id = Concept.find_by_name("DIABETES MEDICATION").id

    @patient_diabetes_treatements     = []
    @patient_hypertension_treatements = []

    DiabetesService.treatments(@patient).map{|treatement|


      if (treatement.diagnosis_id.to_i == diabetes_id && DiabetesService.treatments(@patient).first.start_date.to_date == treatement.start_date.to_date)
        @patient_diabetes_treatements << treatement
      elsif(DiabetesService.treatments(@patient).first.start_date.to_date == treatement.start_date.to_date)
        @patient_hypertension_treatements << treatement
      end
    }
    #raise @patient_diabetes_treatements.to_yaml
    redirect_to "/prescriptions/advanced_new?patient_id=#{params[:patient_id] || session[:patient_id]}" and return if @patient_diabetes_treatements.blank?   #@orders.blank?
    render :template => 'prescriptions/advanced_prescription', :layout => 'complications'
  end
  
  def advanced_new
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil

    diabetes_id = Concept.find_by_name("DIABETES MEDICATION").id

    @patient_diabetes_treatements     = []
    @patient_hypertension_treatements = []

    DiabetesService.treatments(@patient).map{|treatement|

      if (treatement.diagnosis_id.to_i == diabetes_id)
        @patient_diabetes_treatements << treatement
      else
        @patient_hypertension_treatements << treatement
      end
    }

  end
  
  def advanced_create
    (params[:prescriptions] || []).each{|prescription|
      @suggestion = prescription[:suggestion]
      @patient    = Patient.find(prescription[:patient_id] || session[:patient_id]) rescue nil
      @encounter  = MedicationService.current_treatment_encounter(@patient)

      diagnosis_name = prescription[:diagnosis]

      diabetes_clinic = false

      values = "coded_or_text group_id boolean coded drug datetime numeric modifier text".split(" ").map{|value_name|
        prescription["value_#{value_name}"] unless prescription["value_#{value_name}"].blank? rescue nil
      }.compact

      next if values.length == 0
      prescription.delete(:value_text) unless prescription[:value_coded_or_text].blank?

      prescription[:encounter_id]  = @encounter.encounter_id
      prescription[:obs_datetime]  = @encounter.encounter_datetime ||= Time.now()
      prescription[:person_id]     = @encounter.patient_id

      diagnosis_observation = Observation.create("encounter_id" => prescription[:encounter_id],
        "concept_name" => prescription[:concept_name],
        "obs_datetime" => prescription[:obs_datetime],
        "person_id" => prescription[:person_id],
        "value_coded_or_text" => prescription[:value_coded_or_text])

      prescription[:diagnosis]    = diagnosis_observation.id

      @diagnosis = Observation.find(prescription[:diagnosis]) rescue nil
      diabetes_clinic = true if (['DIABETES MEDICATION','HYPERTENSION','PERIPHERAL NEUROPATHY'].include?(diagnosis_name))

      if diabetes_clinic
        prescription[:drug_strength] =  "" unless !prescription[:drug_strength].nil?

        prescription[:formulation] = [prescription[:generic], prescription[:drug_strength], prescription[:frequency]]

        drug_info = DiabetesService.drug_details(prescription[:formulation], diagnosis_name).first

        # raise drug_info.inspect

        prescription[:formulation]    = drug_info[:drug_formulation]
        prescription[:frequency]      = drug_info[:drug_frequency]
        prescription[:prn]            = drug_info[:drug_prn]
        prescription[:dose_strength]  = drug_info[:drug_strength]
      end

      unless (@suggestion.blank? || @suggestion == '0')
        @order = DrugOrder.find(@suggestion)
        DrugOrder.clone_order(@encounter, @patient, @diagnosis, @order)
      else
        @formulation = (prescription[:formulation] || '').upcase

        @drug = Drug.find_by_name(@formulation) rescue nil

        unless @drug
          flash[:notice] = "No matching drugs found for formulation #{prescription[:formulation]}"
          render :new
          return
        end
        start_date = Time.now
        auto_expire_date = Time.now + prescription[:duration].to_i.days
        prn = prescription[:prn]
        if prescription[:type_of_prescription] == "variable"
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, prescription[:morning_dose], 'MORNING', prn) unless prescription[:morning_dose] == "Unknown" || prescription[:morning_dose].to_f == 0
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, prescription[:afternoon_dose], 'AFTERNOON', prn) unless prescription[:afternoon_dose] == "Unknown" || prescription[:afternoon_dose].to_f == 0
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, prescription[:evening_dose], 'EVENING', prn) unless prescription[:evening_dose] == "Unknown" || prescription[:evening_dose].to_f == 0
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, prescription[:night_dose], 'NIGHT', prn)  unless prescription[:night_dose] == "Unknown" || prescription[:night_dose].to_f == 0
        else
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, prescription[:dose_strength], prescription[:frequency], prn)
        end
      end

    }

    if(@patient)
      redirect_to "/prescriptions/advanced_prescription?patient_id=#{@patient.id}"
    else
      redirect_to "/prescriptions/advanced_prescription?patient_id=#{params[:patient_id]}"
    end
    
  end
end
