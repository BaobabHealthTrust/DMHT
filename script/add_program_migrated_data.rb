#adding programs to migrated patients with hiv staging

diabetes_program = Program.find_by_name("DIABETES PROGRAM")
creator = User.find_by_username("admin")


Encounter.find_by_sql("
				SELECT * FROM encounter e
				WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'registration')
				AND patient_id not IN (SELECT DISTINCT(patient_id) FROM patient_program WHERE program_id = 13)").each {|patient |
				
				current = Patient.find(patient.patient_id)
				
				if current.patient_programs.in_programs(diabetes_program.name).blank?
					current = current.patient_programs.create(
							  :program_id => diabetes_program.id,
                              :creator => creator.id,
							  :date_enrolled => patient.encounter_datetime)
          puts "working program for patient #{patient.patient_id}"
        end
         
				}

 concept_name = ConceptName.find_all_by_name("Pre-treatment")

  state = ProgramWorkflowState.find(:first, :conditions => ["concept_id IN (?)",concept_name.map{|c|c.concept_id}] ).program_workflow_state_id

PatientProgram.find_by_sql("
        SELECT * FROM patient_program
        WHERE patient_program_id NOT IN (SELECT patient_program_id FROM patient_state)").each {|program|
        states = PatientState.new(
          :patient_program_id => program.patient_program_id,
          :start_date => program.date_enrolled,
          :state => state,
          :creator => creator.id
          )
        states.save!

       
          puts "working states for patient #{pg.patient_id}"
  
        }
