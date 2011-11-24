module PatientService
	require 'bean'

  def self.remote_demographics(person_obj)
    demo = demographics(person_obj)

    demographics = {
                   "person" =>
                   {"attributes" => {
                      "occupation" => demo['person']['occupation'],
                      "cell_phone_number" => demo['person']['cell_phone_number']
                    } ,
                    "addresses" => 
                     { "address2"=> demo['person']['addresses']['location'],
                       "city_village" => demo['person']['addresses']['city_village'],
                       "address1"  => demo['person']['addresses']['address1'],
                       "county_district" => ""
                     },
                    "age_estimate" => person_obj.birthdate_estimated ,
                    "birth_month"=> person_obj.birthdate.month ,
                    "patient" =>{"identifiers"=>
                                {"National id"=> demo['person']['patient']['identifiers']['National id'] }
                               },
                    "gender" => person_obj.gender.first ,
                    "birth_day" => person_obj.birthdate.day ,
                    "date_changed" => demo['person']['date_changed'] ,
                    "names"=>
                      {
                        "family_name2" => demo['person']['names']['family_name2'],
                        "family_name" => demo['person']['names']['family_name'] ,
                        "given_name" => demo['person']['names']['given_name']
                      },
                    "birth_year" => person_obj.birthdate.year }
                    }
  end

  def self.demographics(person_obj)

    if person_obj.birthdate_estimated==1
      birth_day = "Unknown"
      if person_obj.birthdate.month == 7 and person_obj.birthdate.day == 1
        birth_month = "Unknown"
      else
        birth_month = person_obj.birthdate.month
      end
    else
      birth_month = person_obj.birthdate.month
      birth_day = person_obj.birthdate.day
    end

    demographics = {"person" => {
      "date_changed" => person_obj.date_changed.to_s,
      "gender" => person_obj.gender,
      "birth_year" => person_obj.birthdate.year,
      "birth_month" => birth_month,
      "birth_day" => birth_day,
      "names" => {
        "given_name" => person_obj.names[0].given_name,
        "family_name" => person_obj.names[0].family_name,
        "family_name2" => person_obj.names[0].family_name2
      },
      "addresses" => {
        "county_district" => person_obj.addresses[0].county_district,
        "city_village" => person_obj.addresses[0].city_village,
        "address1" => person_obj.addresses[0].address1,
        "address2" => person_obj.addresses[0].address2
      },
    "attributes" => {"occupation" => self.get_attribute(person_obj, 'Occupation'),
                     "cell_phone_number" => self.get_attribute(person_obj, 'Cell Phone Number')}}}
 
    if not person_obj.patient.patient_identifiers.blank? 
      demographics["person"]["patient"] = {"identifiers" => {}}
      person_obj.patient.patient_identifiers.each{|identifier|
        demographics["person"]["patient"]["identifiers"][identifier.type.name] = identifier.identifier
      }
    end

    return demographics
  end
  
  def self.current_treatment_encounter(patient, date = Time.now(), provider = user_person_id)
    type = EncounterType.find_by_name("TREATMENT")
    encounter = patient.encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= patient.encounters.create(:encounter_type => type.id,:encounter_datetime => date, :provider_id => provider)

  end
  
  def self.phone_numbers(person_obj)
    phone_numbers = {}

    phone_numbers['Cell phone number'] = self.get_attribute(person_obj, 'Cell phone number') rescue nil
    phone_numbers['Office phone number'] = self.get_attribute(person_obj, 'Office phone number') rescue nil
    phone_numbers['Home phone number'] = self.get_attribute(person_obj, 'Home phone number') rescue nil

    phone_numbers
  end

  def self.initial_encounter
    Encounter.find_by_sql("SELECT * FROM encounter ORDER BY encounter_datetime LIMIT 1").first
  end
  
  def self.create_remote_person(received_params)
    #raise known_demographics.to_yaml

    #Format params for BART
     new_params = received_params[:person]
     known_demographics = Hash.new()
     new_params['gender'] == 'F' ? new_params['gender'] = "Female" : new_params['gender'] = "Male"

       known_demographics = {
                  "occupation"=>"#{new_params[:occupation]}",
                   "patient_year"=>"#{new_params[:birth_year]}",
                   "patient"=>{
                    "gender"=>"#{new_params[:gender]}",
                    "birthplace"=>"#{new_params[:addresses][:address2]}",
                    "creator" => 1,
                    "changed_by" => 1
                    },
                   "p_address"=>{
                    "identifier"=>"#{new_params[:addresses][:state_province]}"},
                   "home_phone"=>{
                    "identifier"=>"#{new_params[:home_phone_number]}"},
                   "cell_phone"=>{
                    "identifier"=>"#{new_params[:cell_phone_number]}"},
                   "office_phone"=>{
                    "identifier"=>"#{new_params[:office_phone_number]}"},
                   "patient_id"=>"",
                   "patient_day"=>"#{new_params[:birth_day]}",
                   "patientaddress"=>{"city_village"=>"#{new_params[:addresses][:city_village]}"},
                   "patient_name"=>{
                    "family_name"=>"#{new_params[:names][:family_name]}",
                    "given_name"=>"#{new_params[:names][:given_name]}", "creator" => 1
                    },
                   "patient_month"=>"#{new_params[:birth_month]}",
                   "patient_age"=>{
                    "age_estimate"=>"#{new_params[:age_estimate]}"
                    },
                   "age"=>{
                    "identifier"=>""
                    },
                   "current_ta"=>{
                    "identifier"=>"#{new_params[:addresses][:county_district]}"}
                  }


    servers = GlobalProperty.find(:first, :conditions => {:property => "remote_servers.parent"}).property_value.split(/,/) rescue nil

    server_address_and_port = servers.to_s.split(':')

    server_address = server_address_and_port.first
    server_port = server_address_and_port.second

    return nil if servers.blank?

    wget_base_command = "wget --quiet --load-cookies=cookie.txt --quiet --cookies=on --keep-session-cookies --save-cookies=cookie.txt"

    login = GlobalProperty.find(:first, :conditions => {:property => "remote_bart.username"}).property_value.split(/,/) rescue ''
    password = GlobalProperty.find(:first, :conditions => {:property => "remote_bart.password"}).property_value.split(/,/) rescue ''
    location = GlobalProperty.find(:first, :conditions => {:property => "remote_bart.location"}).property_value.split(/,/) rescue nil
    machine = GlobalProperty.find(:first, :conditions => {:property => "remote_machine.account_name"}).property_value.split(/,/) rescue ''
    post_data = known_demographics
    post_data["_method"]="put"

    local_demographic_lookup_steps = [ 
      "#{wget_base_command} -O /dev/null --post-data=\"login=#{login}&password=#{password}\" \"http://localhost/session\"",
      "#{wget_base_command} -O /dev/null --post-data=\"_method=put&location=#{location}\" \"http://localhost/session\"",
      "#{wget_base_command} -O - --post-data=\"#{post_data.to_param}\" \"http://localhost/patient/create_remote\""
    ]

    results = []
    servers.each{|server|
      command = "ssh #{machine}@#{server_address} '#{local_demographic_lookup_steps.join(";\n")}'"
      output = `#{command}`
      results.push output if output and output.match(/person/)
    }
    result = results.sort{|a,b|b.length <=> a.length}.first

    result ? person = JSON.parse(result) : nil
    begin
        person["person"]["addresses"]["address1"] = "#{new_params[:addresses][:address1]}"
        person["person"]["names"]["middle_name"] = "#{new_params[:names][:middle_name]}"
        person["person"]["occupation"] = known_demographics["occupation"]
        person["person"]["cell_phone_number"] = known_demographics["cell_phone"]["identifier"]
        person["person"]["home_phone_number"] = known_demographics["home_phone"]["identifier"]
        person["person"]["office_phone_number"] = known_demographics["office_phone"]["identifier"]
        person["person"]["attributes"].delete("occupation")
        person["person"]["attributes"].delete("cell_phone_number")
        person["person"]["attributes"].delete("home_phone_number")
        person["person"]["attributes"].delete("office_phone_number")
    rescue
    end   
    person
  end
  
  def self.find_remote_person(known_demographics)

    servers = GlobalProperty.find(:first, :conditions => {:property => "remote_servers.parent"}).property_value.split(/,/) rescue nil

    server_address_and_port = servers.to_s.split(':')

    server_address = server_address_and_port.first
    server_port = server_address_and_port.second

    return nil if servers.blank?

    wget_base_command = "wget --quiet --load-cookies=cookie.txt --quiet --cookies=on --keep-session-cookies --save-cookies=cookie.txt"
    # use ssh to establish a secure connection then query the localhost
    # use wget to login (using cookies and sessions) and set the location
    # then pull down the demographics
    # TODO fix login/pass and location with something better

    login = GlobalProperty.find(:first, :conditions => {:property => "remote_bart.username"}).property_value.split(/,/) rescue ""
    password = GlobalProperty.find(:first, :conditions => {:property => "remote_bart.password"}).property_value.split(/,/) rescue ""
    location = GlobalProperty.find(:first, :conditions => {:property => "remote_bart.location"}).property_value.split(/,/) rescue nil
    machine = GlobalProperty.find(:first, :conditions => {:property => "remote_machine.account_name"}).property_value.split(/,/) rescue ''

    post_data = known_demographics
    post_data["_method"]="put"

    local_demographic_lookup_steps = [ 
      "#{wget_base_command} -O /dev/null --post-data=\"login=#{login}&password=#{password}\" \"http://localhost/session\"",
      "#{wget_base_command} -O /dev/null --post-data=\"_method=put&location=#{location}\" \"http://localhost/session\"",
      "#{wget_base_command} -O - --post-data=\"#{post_data.to_param}\" \"http://localhost/people/demographics\""
    ]

    results = []
    servers.each{|server|
      command = "ssh #{machine}@#{server_address} '#{local_demographic_lookup_steps.join(";\n")}'"
      output = `#{command}`
      results.push output if output and output.match /person/
    }
    # TODO need better logic here to select the best result or merge them
    # Currently returning the longest result - assuming that it has the most information
    # Can't return multiple results because there will be redundant data from sites
    result = results.sort{|a,b|b.length <=> a.length}.first
    result ? person = JSON.parse(result) : nil
    #Stupid hack to structure the hash for openmrs 1.7
    person["person"]["occupation"] = person["person"]["attributes"]["occupation"]
    person["person"]["cell_phone_number"] = person["person"]["attributes"]["cell_phone_number"]
    person["person"]["home_phone_number"] =  person["person"]["attributes"]["home_phone_number"]
    person["person"]["office_phone_number"] = person["person"]["attributes"]["office_phone_number"]
    person["person"]["attributes"].delete("occupation")
    person["person"]["attributes"].delete("cell_phone_number")
    person["person"]["attributes"].delete("home_phone_number")
    person["person"]["attributes"].delete("office_phone_number")

    person
  end
  
  def self.find_remote_person_by_identifier(identifier)
    known_demographics = {:person => {:patient => { :identifiers => {"National id" => identifier }}}}
    find_remote_person(known_demographics)
  end
  
  def self.find_person_by_demographics(person_demographics)
    national_id = person_demographics["person"]["patient"]["identifiers"]["National id"] rescue nil
    results = search_by_identifier(national_id) unless national_id.nil?
    return results unless results.blank?

    gender = person_demographics["person"]["gender"] rescue nil
    given_name = person_demographics["person"]["names"]["given_name"] rescue nil
    family_name = person_demographics["person"]["names"]["family_name"] rescue nil

    search_params = {:gender => gender, :given_name => given_name, :family_name => family_name }

    results = person_search(search_params)
  end
  
  def self.checks_if_labs_results_are_avalable_to_be_shown(patient , session_date , task)
    lab_result = Encounter.find(:first,:order => "encounter_datetime DESC",
                                :conditions =>["DATE(encounter_datetime) <= ? 
                                AND patient_id = ? AND encounter_type = ?",
                                session_date.to_date ,patient.id,
                                EncounterType.find_by_name('LAB RESULTS').id])

    give_lab_results = Encounter.find(:first,:order => "encounter_datetime DESC",
                                :conditions =>["DATE(encounter_datetime) >= ? 
                                AND patient_id = ? AND encounter_type = ?",
                                lab_result.encounter_datetime.to_date , patient.id,
                                EncounterType.find_by_name('GIVE LAB RESULTS').id]) rescue nil

    if not lab_result.blank? and give_lab_results.blank?
      task.encounter_type = 'GIVE LAB RESULTS'
      task.url = "/encounters/new/give_lab_results?patient_id=#{patient.id}"
      return task
    end

    if not give_lab_results.blank?
      if not give_lab_results.observations.collect{|obs|obs.to_s.squish}.include?('Laboratory results given to patient: Yes')
        task.encounter_type = 'GIVE LAB RESULTS'
        task.url = "/encounters/new/give_lab_results?patient_id=#{patient.id}"
        return task
      end if not (give_lab_results.encounter_datetime.to_date == session_date.to_date)
    end

  end
  
  def self.tb_next_form(location , patient , session_date = Date.today)
    task = Task.first rescue Task.new()
    
    if patient.patient_programs.in_uncompleted_programs(['TB PROGRAM', 'MDR-TB PROGRAM']).blank?
      #Patient has no active TB program ...'
      ids = Program.find(:all,:conditions =>["name IN(?)",['TB PROGRAM', 'MDR-TB PROGRAM']]).map{|p|p.id}
      last_active = PatientProgram.find(:first,:order => "date_completed DESC,date_created DESC",
                    :conditions => ["patient_id = ? AND program_id IN(?)",patient.id,ids])

      if not last_active.blank?
        state = last_active.patient_states.last.program_workflow_state.concept.fullname rescue 'NONE'
        task.encounter_type = state
        task.url = "/patients/show/#{patient.id}"
        return task
      end
    end
     
    #we get the sequence of clinic questions(encounters) form the GlobalProperty table
    #property: list.of.clinical.encounters.sequentially
    #property_value: ?

    #valid privileges for ART visit ....
    #1. Manage TB Reception Visits - TB RECEPTION
    #2. Manage TB initial visits - TB_INITIAL
    #3. Manage Lab orders - LAB ORDERS
    #4. Manage sputum submission - SPUTUM SUBMISSION
    #5. Manage Lab results - LAB RESULTS
    #6. Manage TB registration - TB REGISTRATION
    #7. Manage TB followup - TB VISIT
    #8. Manage HIV status updates - UPDATE HIV STATUS
    #8. Manage prescriptions - TREATMENT
    #8. Manage dispensations - DISPENSING

    tb_encounters =  [
                      'SOURCE OF REFERRAL','UPDATE HIV STATUS','LAB ORDERS',
                      'SPUTUM SUBMISSION','LAB RESULTS','TB_INITIAL',
                      'TB RECEPTION','TB REGISTRATION','TB VISIT','TB ADHERENCE',
                      'TB CLINIC VISIT','ART_INITIAL','VITALS','HIV STAGING',
                      'ART VISIT','ART ADHERENCE','TREATMENT','DISPENSING'
                     ] 
    user_selected_activities = User.current_user.activities.collect{|a| a.upcase }.join(',') rescue []
    if user_selected_activities.blank? or tb_encounters.blank?
      task.url = "/patients/show/#{patient.id}"
      return task
    end
    art_reason = patient.person.observations.recent(1).question("REASON FOR ART ELIGIBILITY").all rescue nil
    reason_for_art = art_reason.map{|c|ConceptName.find(c.value_coded_name_id).name}.join(',') rescue ''
    
    tb_reception_attributes = []
    tb_obs = Encounter.find(:first,:order => "encounter_datetime DESC",
                    :conditions => ["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                    session_date,patient.id,EncounterType.find_by_name('TB RECEPTION').id]).observations rescue []
    (tb_obs || []).each do | obs |
      tb_reception_attributes << obs.to_s.squish.strip 
    end

    tb_encounters.each do | type |
      task.encounter_type = type 

      case type
        when 'SOURCE OF REFERRAL'
          next if patient_tb_status(patient).match(/treatment/i)

          if ['Lighthouse','Martin Preuss Centre'].include?(Location.current_health_center.name)
            if not (location.current_location.name.match(/Chronic Cough/) or 
              location.current_location.name.match(/TB Sputum Submission Station/i))
              next
            end
          end

          source_of_referral = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["encounter_datetime <= ?
                                      AND patient_id = ? AND encounter_type = ?",
                                      (session_date.to_date).strftime('%Y-%m-%d 23:59:59'),
                                      patient.id,EncounterType.find_by_name(type).id])

          if source_of_referral.blank? and user_selected_activities.match(/Manage Source of Referral/i) 
            task.url = "/encounters/new/source_of_referral?patient_id=#{patient.id}"
            return task
          elsif source_of_referral.blank? and not user_selected_activities.match(/Manage Source of Referral/i) 
            task.url = "/patients/show/#{patient.id}"
            return task
          end 
        when 'UPDATE HIV STATUS'
          next_task = checks_if_labs_results_are_avalable_to_be_shown(patient , session_date , task)
          return next_task unless next_task.blank?

          next if patient_hiv_status(patient).match(/Positive/i)
          if not patient.patient_programs.blank?
            next if patient.patient_programs.collect{|p|p.program.name}.include?('HIV PROGRAM') 
          end

          hiv_status = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["encounter_datetime >= ? AND encounter_datetime <= ?
                                      AND patient_id = ? AND encounter_type = ?",(session_date.to_date - 3.month).strftime('%Y-%m-%d 00:00:00'),
                                      (session_date.to_date).strftime('%Y-%m-%d 23:59:59'),patient.id,EncounterType.find_by_name(type).id])

          if hiv_status.observations.map{|s|s.to_s.split(':').last.strip}.include?('Positive')
            next 
          end if not hiv_status.blank?

          if hiv_status.blank? and user_selected_activities.match(/Manage HIV Status Visits/i)
            task.url = "/encounters/new/hiv_status?show&patient_id=#{patient.id}"
            return task
          elsif hiv_status.blank? and not user_selected_activities.match(/Manage HIV Status Visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end

          xray = Observation.find(Observation.find(:first,
                    :order => "obs_datetime DESC,date_created DESC", 
                    :conditions => ["person_id = ? AND concept_id = ? AND DATE(obs_datetime) <= ?", 
                    patient.id, ConceptName.find_by_name("Refer to x-ray?").concept_id,
                    session_date.to_date])).to_s.strip.squish.upcase rescue ''

          if xray.match(/: Yes/i)
            task.encounter_type = "Xray scan"
            task.url = "/patients/show/#{patient.id}"
            return task
          end

          
          refered_to_htc_concept_id = ConceptName.find_by_name("Refer to HTC").concept_id

          refered_to_htc = Observation.find(Observation.find(:first,
                    :order => "obs_datetime DESC,date_created DESC",
                    :conditions => ["person_id = ? AND concept_id = ? AND DATE(obs_datetime) <= ?", 
                    patient.id, refered_to_htc_concept_id,
                    session_date.to_date])).to_s.strip.squish.upcase rescue nil

          if ('Refer to HTC: Yes'.upcase == refered_to_htc)
            task.encounter_type = 'Refered to HTC'
            task.url = "/patients/show/#{patient.id}"
            return task
          end

          if ('Refer to HTC: NO'.upcase == refered_to_htc) and location.name.upcase == "TB HTC"
            refered_to_htc = Encounter.find(:first,
              :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id",
              :order => "encounter_datetime DESC,date_created DESC",
              :conditions => ["patient_id = ? and concept_id = ? AND value_coded = ?",
              patient.id,refered_to_htc_concept_id,ConceptName.find_by_name('YES').concept_id])

            loc_name = refered_to_htc.observations.map do | obs |
              next unless obs.to_s.match(/Workstation location/i)
              obs.to_s.gsub('Workstation location:','').squish 
            end

            task.encounter_type = "#{loc_name}"
            task.url = "/patients/show/#{patient.id}"
            return task
          end
        when 'VITALS' 

          if not patient_hiv_status(patient).match(/Positive/i) and not patient_tb_status(patient).match(/treatment/i)
            next
          end 

          first_vitals = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                  :conditions =>["patient_id = ? AND encounter_type = ?",
                                  patient.id,EncounterType.find_by_name(type).id])

          if not patient_tb_status(patient).match(/treatment/i) and not tb_reception_attributes.include?('Any need to see a clinician: Yes')
            next
          end if not patient_hiv_status(patient).match(/Positive/i)

          if patient_tb_status(patient).match(/treatment/i) and not patient_hiv_status(patient).match(/Positive/i)
            next
          end if not first_vitals.blank?

          vitals = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                  :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                  session_date.to_date,patient.id,EncounterType.find_by_name(type).id])

          if vitals.blank? and user_selected_activities.match(/Manage Vitals/i) 
            task.encounter_type = 'VITALS'
            task.url = "/encounters/new/vitals?patient_id=#{patient.id}"
            return task
          elsif vitals.blank? and not user_selected_activities.match(/Manage Vitals/i) 
            task.encounter_type = 'VITALS'
            task.url = "/patients/show/#{patient.id}"
            return task
          end 

        when 'TB RECEPTION'
          reception = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                     :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                     session_date.to_date,patient.id,EncounterType.find_by_name(type).id])

          if reception.blank? and user_selected_activities.match(/Manage TB Reception Visits/i)
            task.url = "/encounters/new/tb_reception?show&patient_id=#{patient.id}"
            return task
          elsif reception.blank? and not user_selected_activities.match(/Manage TB Reception Visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end
        when 'LAB ORDERS'
          next if patient_tb_status(patient).match(/treatment/i)

          if ['Lighthouse','Martin Preuss Centre'].include?(Location.current_health_center.name)
            if not (location.current_location.name.match(/Chronic Cough/) or 
              location.current_location.name.match(/TB Sputum Submission Station/i))
              next
            end
          end

          lab_order = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["DATE(encounter_datetime) <= ? AND patient_id = ? AND encounter_type = ?",
                                      session_date.to_date ,patient.id,EncounterType.find_by_name(type).id])

          next_lab_encounter =  next_lab_encounter(patient , lab_order , session_date)

          if (lab_order.encounter_datetime.to_date == session_date.to_date)
            task.encounter_type = 'NONE'
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not lab_order.blank? 

          if user_selected_activities.match(/Manage Lab Orders/i)
            task.url = "/encounters/new/lab_orders?show&patient_id=#{patient.id}"
            return task
          elsif not user_selected_activities.match(/Manage Lab Orders/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if (next_lab_encounter.blank? or next_lab_encounter == 'NO LAB ORDERS')
        when 'SPUTUM SUBMISSION'
          previous_sputum_sub = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["DATE(encounter_datetime) <= ? AND patient_id = ? AND encounter_type = ?",
                                      session_date.to_date ,patient.id,EncounterType.find_by_name(type).id])

          next_lab_encounter =  next_lab_encounter(patient , previous_sputum_sub , session_date)

          if (previous_sputum_sub.encounter_datetime.to_date == session_date.to_date)
            task.encounter_type = 'NONE'
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not previous_sputum_sub.blank? 

          if not next_lab_encounter.blank?
            next
          end if not (next_lab_encounter == "NO LAB ORDERS")

          if next_lab_encounter.blank? and previous_sputum_sub.encounter_datetime.to_date == session_date.to_date
            task.encounter_type = 'NONE'
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not previous_sputum_sub.blank?

          if user_selected_activities.match(/Manage Sputum Submissions/i)
            task.url = "/encounters/new/sputum_submission?show&patient_id=#{patient.id}"
            return task
          elsif not user_selected_activities.match(/Manage Sputum Submissions/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if (next_lab_encounter.blank?)
        when 'LAB RESULTS'
          lab_result = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["DATE(encounter_datetime) <= ? AND patient_id = ? AND encounter_type = ?",
                                      session_date.to_date ,patient.id,EncounterType.find_by_name(type).id])

          next_lab_encounter =  next_lab_encounter(patient , lab_result , session_date)

          if not next_lab_encounter.blank?
            next
          end if not (next_lab_encounter == "NO LAB ORDERS")

          if user_selected_activities.match(/Manage Lab Results/i)
            task.url = "/encounters/new/lab_results?show&patient_id=#{patient.id}"
            return task
          elsif not user_selected_activities.match(/Manage Lab Results/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if (next_lab_encounter.blank?)
        when 'TB CLINIC VISIT'

          next if patient_tb_status(patient).match(/treatment/i)

          obs_ans = Observation.find(Observation.find(:first, 
                    :order => "obs_datetime DESC,date_created DESC",
                    :conditions => ["person_id = ? AND concept_id = ? AND DATE(obs_datetime) = ?",patient.id, 
                    ConceptName.find_by_name("ANY NEED TO SEE A CLINICIAN").concept_id,session_date])).to_s.strip.squish rescue nil

          if not obs_ans.blank?
            next if obs_ans.match(/ANY NEED TO SEE A CLINICIAN: NO/i)
            if obs_ans.match(/ANY NEED TO SEE A CLINICIAN: YES/i)
              tb_visits = Encounter.find(:all,:order => "encounter_datetime DESC,date_created DESC",
                            :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                            session_date.to_date,patient.id,EncounterType.find_by_name('TB VISIT').id])
              if (tb_visits.length == 1) 
                roles = User.current_user.user_roles.map{|u|u.role}.join(',') rescue ''
                if not (roles.match(/Clinician/i) or roles.match(/Doctor/i))
                    task.encounter_type = 'TB VISIT'
                    task.url = "/patients/show/#{patient.id}"
                    return task
                elsif user_selected_activities.match(/Manage TB Treatment Visits/i)
                  task.encounter_type = 'TB VISIT'
                  task.url = "/encounters/new/tb_visit?show&patient_id=#{patient.id}"
                  return task
                elsif not user_selected_activities.match(/Manage TB Treatment Visits/i)
                  task.encounter_type = 'TB VISIT'
                  task.url = "/patients/show/#{patient.id}"
                  return task
                end
              end
            end
          end

          visit_type = Observation.find(Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ? AND DATE(obs_datetime) = ?", 
                    patient.id, ConceptName.find_by_name("TYPE OF VISIT").concept_id,session_date])).to_s.strip.squish rescue nil

          if not visit_type.blank?  #and obs_ans.match(/ANY NEED TO SEE A CLINICIAN: NO/i)
            next if visit_type.match(/Reason for visit: Follow-up/i)
          end if obs_ans.blank?

          clinic_visit = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                      session_date.to_date ,patient.id,EncounterType.find_by_name(type).id])


          if clinic_visit.blank? and user_selected_activities.match(/Manage TB clinic visits/i)
            task.url = "/encounters/new/tb_clinic_visit?show&patient_id=#{patient.id}"
            return task
          elsif clinic_visit.blank? and not user_selected_activities.match(/Manage TB clinic visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end 

          clinic_visit = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["patient_id = ? AND encounter_type = ?",
                                      patient.id,EncounterType.find_by_name(type).id])

          clinic_visit_obs = clinic_visit.observations.map{|o|
            o.to_s.upcase.strip.squish
          }.include?("REFER TO X-RAY?: YES") rescue false

          if clinic_visit_obs
            if user_selected_activities.match(/Manage TB clinic visits/i)
              task.url = "/encounters/new/tb_clinic_visit?show&patient_id=#{patient.id}"
              return task
            elsif not user_selected_activities.match(/Manage TB clinic visits/i)
              task.url = "/patients/show/#{patient.id}"
              return task
            end 
          end if clinic_visit_obs

        when 'TB_INITIAL'
          #next if not patient.tb_status.match(/treatment/i)
          tb_initial = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["patient_id = ? AND encounter_type = ?",
                                      patient.id,EncounterType.find_by_name(type).id])

          next if not tb_initial.blank?

          #enrolled_in_tb_program = patient.patient_programs.collect{|p|p.program.name}.include?('TB PROGRAM') rescue false

          if user_selected_activities.match(/Manage TB initial visits/i)
            task.url = "/encounters/new/tb_initial?show&patient_id=#{patient.id}"
            return task
          elsif not user_selected_activities.match(/Manage TB initial visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end 
        when 'ART_INITIAL'
          next unless patient_hiv_status(patient).match(/Positive/i)
        
          enrolled_in_hiv_program = Concept.find(Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ?",patient.id, 
            ConceptName.find_by_name("Patient enrolled in IMB HIV program").concept_id]).value_coded).concept_names.map{|c|c.name}[0].upcase rescue nil
      
          next unless enrolled_in_hiv_program == 'YES'
  
          enrolled_in_hiv_program = patient.patient_programs.collect{|p|p.program.name}.include?('HIV PROGRAM') rescue false
          next if enrolled_in_hiv_program 

          art_initial = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
                                         patient.id,EncounterType.find_by_name(type).id],
                                         :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

          if art_initial.blank? and user_selected_activities.match(/Manage HIV first visits/i)
            task.url = "/encounters/new/art_initial?show&patient_id=#{patient.id}"
            return task
          elsif art_initial.blank? and not user_selected_activities.match(/Manage HIV first visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end
        when 'HIV STAGING'
          #checks if vitals have been taken already 
          vitals = checks_if_vitals_are_need(patient,session_date,task,user_selected_activities)
          return vitals unless vitals.blank?

          enrolled_in_hiv_program = Concept.find(Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ?",patient.id, 
            ConceptName.find_by_name("Patient enrolled in IMB HIV program").concept_id]).value_coded).concept_names.map{|c|c.name}[0].upcase rescue nil

          next if enrolled_in_hiv_program == 'NO'
          next if patient.patient_programs.blank?
          next if not patient.patient_programs.collect{|p|p.program.name}.include?('HIV PROGRAM') 

          next unless patient_hiv_status(patient).match(/Positive/i)
          hiv_staging = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["patient_id = ? AND encounter_type = ?",
                                      patient.id,EncounterType.find_by_name(type).id])

          if hiv_staging.blank? and user_selected_activities.match(/Manage HIV staging visits/i) 
            extended_staging_questions = get_global_property_value('use.extended.staging.questions')
            extended_staging_questions = extended_staging_questions.property_value == 'yes' rescue false
            task.url = "/encounters/new/hiv_staging?show&patient_id=#{patient.id}" if not extended_staging_questions 
            task.url = "/encounters/new/llh_hiv_staging?show&patient_id=#{patient.id}" if extended_staging_questions
            return task
          elsif hiv_staging.blank? and not user_selected_activities.match(/Manage HIV staging visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if (reason_for_art.upcase ==  'UNKNOWN' or reason_for_art.blank?)
        when 'TB REGISTRATION'
          #checks if patient needs to be stage before continuing
          next_task = need_art_enrollment(task,patient,location,session_date,user_selected_activities,reason_for_art)
          return next_task if not next_task.blank? and user_selected_activities.match(/Manage HIV staging visits/i)

          next unless patient_tb_status(patient).match(/treatment/i)
          tb_registration = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["patient_id = ? AND encounter_type = ?",
                                      patient.id,EncounterType.find_by_name(type).id])

          next if not tb_registration.blank?
          #enrolled_in_tb_program = patient.patient_programs.collect{|p|p.program.name}.include?('TB PROGRAM') rescue false

          #checks if vitals have been taken already 
          vitals = checks_if_vitals_are_need(patient,session_date,task,user_selected_activities)
          return vitals unless vitals.blank?

    
          if user_selected_activities.match(/Manage TB Registration visits/i)
            task.url = "/encounters/new/tb_registration?show&patient_id=#{patient.id}"
            return task
          elsif not user_selected_activities.match(/Manage TB Registration visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end
        when 'TB VISIT'
          if patient_is_child?(patient) or patient_hiv_status(patient).match(/Positive/i)
            clinic_visit = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["patient_id = ? AND encounter_type = ?",
                                      patient.id,EncounterType.find_by_name('TB CLINIC VISIT').id])
            #checks if vitals have been taken already 
            vitals = checks_if_vitals_are_need(patient,session_date,task,user_selected_activities)
            return vitals unless vitals.blank?


            if clinic_visit.blank? and user_selected_activities.match(/Manage TB Clinic Visits/i)
              task.encounter_type = "TB CLINIC VISIT"
              task.url = "/encounters/new/tb_clinic_visit?show&patient_id=#{patient.id}"
              return task
            elsif clinic_visit.blank? and not user_selected_activities.match(/Manage TB Clinic Visits/i)
              task.encounter_type = "TB CLINIC VISIT"
              task.url = "/patients/show/#{patient.id}"
              return task
            end if not patient_tb_status(patient).match(/treatment/i)
          end

          #checks if vitals have been taken already 
          vitals = checks_if_vitals_are_need(patient,session_date,task,user_selected_activities)
          return vitals unless vitals.blank?

          if not patient_tb_status(patient).match(/treatment/i)
            next
          end if not tb_reception_attributes.include?('Reason for visit: Follow-up')

          tb_registration = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["patient_id = ? AND encounter_type = ?",
                                      patient.id,EncounterType.find_by_name('TB REGISTRATION').id])

          tb_followup = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                      :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                      session_date.to_date,patient.id,EncounterType.find_by_name(type).id])

          if (tb_followup.encounter_datetime.to_date == tb_registration.encounter_datetime.to_date)
			      next
          end if not tb_followup.blank? and not tb_registration.blank?

          if tb_registration.blank?
            task.encounter_type = 'TB PROGRAM ENROLMENT'
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not tb_reception_attributes.include?('Reason for visit: Follow-up')

          if tb_followup.blank? and user_selected_activities.match(/Manage TB Treatment Visits/i)
            task.url = "/encounters/new/tb_visit?show&patient_id=#{patient.id}"
            return task
          elsif tb_followup.blank? and not user_selected_activities.match(/Manage TB Treatment Visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end

          obs_ans = Observation.find(Observation.find(:first, 
                    :order => "obs_datetime DESC,date_created DESC",
                    :conditions => ["person_id = ? AND concept_id = ? AND DATE(obs_datetime) = ?",patient.id, 
                    ConceptName.find_by_name("ANY NEED TO SEE A CLINICIAN").concept_id,session_date])).to_s.strip.squish rescue nil

          if not obs_ans.blank?
            next if obs_ans.match(/ANY NEED TO SEE A CLINICIAN: NO/i)
            if obs_ans.match(/ANY NEED TO SEE A CLINICIAN: YES/i)
              tb_visits = Encounter.find(:all,:order => "encounter_datetime DESC,date_created DESC",
                            :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                            session_date.to_date,patient.id,EncounterType.find_by_name('TB VISIT').id])
              if (tb_visits.length == 1) 
                roles = User.current_user.user_roles.map{|u|u.role}.join(',') rescue ''
                if not (roles.match(/Clinician/i) or roles.match(/Doctor/i))
                    task.encounter_type = 'TB VISIT'
                    task.url = "/patients/show/#{patient.id}"
                    return task
                elsif user_selected_activities.match(/Manage TB Treatment Visits/i)
                  task.encounter_type = 'TB VISIT'
                  task.url = "/encounters/new/tb_visit?show&patient_id=#{patient.id}"
                  return task
                elsif not user_selected_activities.match(/Manage TB Treatment Visits/i)
                  task.encounter_type = 'TB VISIT'
                  task.url = "/patients/show/#{patient.id}"
                  return task
                end
              end
            end
          end
        when 'ART VISIT'  
          next unless patient.patient_programs.collect{|p|p.program.name}.include?('HIV PROGRAM') rescue false
          clinic_visit = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                    :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                    session_date.to_date,patient.id,EncounterType.find_by_name('TB CLINIC VISIT').id])
          goto_art_visit = clinic_visit.observations.map{|obs| obs.to_s.strip.upcase }.include? 'ART visit:  Yes'.upcase rescue false
          goto_art_visit_answered = clinic_visit.observations.map{|obs| obs.to_s.strip.upcase }.include? 'ART visit:'.upcase rescue false

          next if not goto_art_visit and goto_art_visit_answered
          

          pre_art_visit = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                    :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                    session_date.to_date,patient.id,EncounterType.find_by_name('PART_FOLLOWUP').id])

          if pre_art_visit.blank? and user_selected_activities.match(/Manage pre ART visits/i)
            task.encounter_type = 'Pre ART visit'
            task.url = "/encounters/new/pre_art_visit?show&patient_id=#{patient.id}"
            return task
          elsif pre_art_visit.blank? and not user_selected_activities.match(/Manage pre ART visits/i)
            task.encounter_type = 'Pre ART visit'
            task.url = "/patients/show/#{patient.id}"
            return task
          end if reason_for_art.upcase ==  'UNKNOWN' or reason_for_art.blank?

          art_visit = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                    :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                    session_date.to_date,patient.id,EncounterType.find_by_name(type).id])

          if art_visit.blank? and user_selected_activities.match(/Manage ART visits/i)
            task.url = "/encounters/new/art_visit?show&patient_id=#{patient.id}"
            return task
          elsif art_visit.blank? and not user_selected_activities.match(/Manage ART visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not reason_for_art.upcase ==  'UNKNOWN'
        when 'TB ADHERENCE'
          drugs_given_before = (not drug_given_before(patient,session_date).prescriptions.blank?) rescue false
           
          tb_adherence = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                    :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                    session_date.to_date,patient.id,EncounterType.find_by_name(type).id])

          if tb_adherence.blank? and user_selected_activities.match(/Manage TB adherence/i)
            task.url = "/encounters/new/tb_adherence?show&patient_id=#{patient.id}"
            return task
          elsif tb_adherence.blank? and not user_selected_activities.match(/Manage TB adherence/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if drugs_given_before
        when 'ART ADHERENCE'
          art_drugs_given_before = (not drug_given_before(patient,session_date).arv.prescriptions.blank?) rescue false

          art_adherence = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                    :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                    session_date.to_date,patient.id,EncounterType.find_by_name(type).id])

          if art_adherence.blank? and user_selected_activities.match(/Manage ART adherence/i)
            task.url = "/encounters/new/art_adherence?show&patient_id=#{patient.id}"
            return task
          elsif art_adherence.blank? and not user_selected_activities.match(/Manage ART adherence/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if art_drugs_given_before
        when 'TREATMENT' 
          tb_treatment_encounter = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                   :joins => "INNER JOIN obs USING(encounter_id)",
                                   :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ? AND concept_id = ?",
                                   session_date.to_date,patient.id,EncounterType.find_by_name(type).id,ConceptName.find_by_name('TB regimen type').concept_id])

          encounter_tb_visit = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name('TB VISIT').id,session_date],
                                   :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

          prescribe_drugs = encounter_tb_visit.observations.map{|obs| obs.to_s.squish.strip.upcase }.include? 'Prescribe drugs: Yes'.upcase rescue false

          if not prescribe_drugs 
            encounter_tb_clinic_visit = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name('TB CLINIC VISIT').id,session_date],
                                   :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

            prescribe_drugs = encounter_tb_clinic_visit.observations.map{|obs| obs.to_s.squish.strip.upcase }.include? 'Prescribe drugs: Yes'.upcase rescue false
          end

          if tb_treatment_encounter.blank? and user_selected_activities.match(/Manage prescriptions/i)
            task.url = "/regimens/new?patient_id=#{patient.id}"
            return task
          elsif tb_treatment_encounter.blank? and not user_selected_activities.match(/Manage prescriptions/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if prescribe_drugs



          art_treatment_encounter = Encounter.find(:first,:order => "encounter_datetime DESC,date_created DESC",
                                   :joins => "INNER JOIN obs USING(encounter_id)",
                                   :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ? AND concept_id = ?",
                                   session_date.to_date,patient.id,EncounterType.find_by_name(type).id,ConceptName.find_by_name('ARV regimen type').concept_id])

          encounter_art_visit = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name('ART VISIT').id,session_date],
                                   :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

          prescribe_drugs = false

          prescribe_drugs = encounter_art_visit.observations.map{|obs| obs.to_s.squish.strip.upcase }.include? 'Prescribe ARVs this visit: Yes'.upcase rescue false

          if not prescribe_drugs
            encounter_pre_art_visit = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name('PART_FOLLOWUP').id,session_date],
                                   :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

            prescribe_drugs = encounter_pre_art_visit.observations.map{|obs| obs.to_s.squish.strip.upcase }.include? 'Prescribe drugs: Yes'.upcase rescue false
          end


          if art_treatment_encounter.blank? and user_selected_activities.match(/Manage prescriptions/i)
            task.url = "/regimens/new?patient_id=#{patient.id}"
            return task
          elsif art_treatment_encounter.blank? and not user_selected_activities.match(/Manage prescriptions/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if prescribe_drugs
        when 'DISPENSING'
          treatment = Encounter.find(:first,:conditions =>["patient_id = ? AND DATE(encounter_datetime) = ? AND encounter_type = ?",
                            patient.id,session_date,EncounterType.find_by_name('TREATMENT').id])

          encounter = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                 patient.id,EncounterType.find_by_name('DISPENSING').id,session_date],
                                 :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

          if encounter.blank? and user_selected_activities.match(/Manage drug dispensations/i)
            task.url = "/patients/treatment_dashboard/#{patient.id}"
            return task
          elsif encounter.blank? and not user_selected_activities.match(/Manage drug dispensations/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not treatment.blank?

          complete = DrugOrder.all_orders_complete(patient,session_date.to_date)
         
          if not complete and user_selected_activities.match(/Manage drug dispensations/i)
            task.url = "/patients/treatment_dashboard/#{patient.id}"
            return task
          elsif not complete and not user_selected_activities.match(/Manage drug dispensations/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not treatment.blank?
         
          appointment = Encounter.find(:first,:conditions =>["patient_id = ? AND 
                        encounter_type = ? AND DATE(encounter_datetime) = ?",
                        patient.id,EncounterType.find_by_name('APPOINTMENT').id,session_date],
                        :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

          if complete and user_selected_activities.match(/Manage Appointments/i)
            start_date , end_date = DrugOrder.prescription_dates(patient,session_date.to_date)
            task.encounter_type = "Set Appointment date"
            task.url = "/encounters/new/appointment?end_date=#{end_date}&id=show&patient_id=#{patient.id}&start_date=#{start_date}"
            return task
          elsif complete and not user_selected_activities.match(/Manage Appointments/i)
            task.encounter_type = "Set Appointment date"
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not treatment.blank? and appointment.blank?
      end
    end
    #task.encounter_type = 'Visit complete ...'
    task.encounter_type = 'NONE'
    task.url = "/patients/show/#{patient.id}"
    return task
  end
  
  def self.next_form(location , patient , session_date = Date.today)
    #for Oupatient departments
    task = Task.first rescue Task.new()
    if location.name.match(/Outpatient/i)
      opd_reception = Encounter.find(:first,:conditions =>["patient_id = ? AND DATE(encounter_datetime) = ? AND encounter_type = ?",
                        patient.id, session_date, EncounterType.find_by_name('OUTPATIENT RECEPTION').id])
      if opd_reception.blank?
        task.url = "/encounters/new/opd_reception?show&patient_id=#{patient.id}"
        task.encounter_type = 'OUTPATIENT RECEPTION'
      else
        task.encounter_type = 'NONE'
        task.url = "/patients/show/#{patient.id}"
      end
      return task
    end

    if User.current_user.activities.include?('Manage Lab Orders') or User.current_user.activities.include?('Manage Lab Results') or
       User.current_user.activities.include?('Manage Sputum Submissions') or User.current_user.activities.include?('Manage TB Clinic Visits') or
       User.current_user.activities.include?('Manage TB Reception Visits') or User.current_user.activities.include?('Manage TB Registration Visits') or
       User.current_user.activities.include?('Manage HIV Status Visits') 
         return tb_next_form(location , patient , session_date)
    end
    
    if User.current_user.activities.blank?
      task.encounter_type = "NO TASKS SELECTED"
      task.url = "/patients/show/#{patient.id}"
      return task
    end
    
    current_day_encounters = Encounter.find(:all,
              :conditions =>["patient_id = ? AND DATE(encounter_datetime) = ?",
              patient.id,session_date.to_date]).map{|e|e.name.upcase}
    
    if current_day_encounters.include?("TB RECEPTION")
      return tb_next_form(location , patient , session_date)
    end

    #we get the sequence of clinic questions(encounters) form the GlobalProperty table
    #property: list.of.clinical.encounters.sequentially
    #property_value: ?

    #valid privileges for ART visit ....
    #1. Manage Vitals - VITALS
    #2. Manage pre ART visits - PART_FOLLOWUP
    #3. Manage HIV staging visits - HIV STAGING
    #4. Manage HIV reception visits - HIV RECEPTION
    #5. Manage HIV first visit - ART_INITIAL
    #6. Manage drug dispensations - DISPENSING
    #7. Manage ART visits - ART VISIT
    #8. Manage TB reception visits -? 
    #9. Manage prescriptions - TREATMENT
    #10. Manage appointments - APPOINTMENT
    #11. Manage ART adherence - ART ADHERENCE

    encounters_sequentially = get_global_property_value('list.of.clinical.encounters.sequentially')

    encounters = encounters_sequentially.split(',')

    user_selected_activities = User.current_user.activities.collect{|a| a.upcase }.join(',') rescue []
    if encounters.blank? or user_selected_activities.blank?
      task.url = "/patients/show/#{patient.id}"
      return task
    end
    art_reason = patient.person.observations.recent(1).question("REASON FOR ART ELIGIBILITY").all rescue nil
    reason_for_art = art_reason.map{|c|ConceptName.find(c.value_coded_name_id).name}.join(',') rescue ''
    
    encounters.each do | type |
      encounter_available = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                     patient.id,EncounterType.find_by_name(type).id,session_date],
                                     :order =>'encounter_datetime DESC',:limit => 1)
      reception = Encounter.find(:first,:conditions =>["patient_id = ? AND DATE(encounter_datetime) = ? AND encounter_type = ?",
                        patient.id,session_date,EncounterType.find_by_name('HIV RECEPTION').id]).observations.collect{| r | r.to_s}.join(',') rescue ''
        
      task.encounter_type = type 
      case type
        when 'VITALS'
          if encounter_available.blank? and user_selected_activities.match(/Manage Vitals/i) 
            task.url = "/encounters/new/vitals?patient_id=#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage Vitals/i) 
            task.url = "/patients/show/#{patient.id}"
            return task
          end if reception.match(/PATIENT PRESENT FOR CONSULTATION:  YES/i)
        when 'ART VISIT'
          if encounter_available.blank? and user_selected_activities.match(/Manage ART visits/i)
            task.url = "/encounters/new/art_visit?show&patient_id=#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage ART visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not reason_for_art.upcase ==  'UNKNOWN'
        when 'PART_FOLLOWUP'
          if encounter_available.blank? and user_selected_activities.match(/Manage pre ART visits/i)
            task.url = "/encounters/new/pre_art_visit?show&patient_id=#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage pre ART visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if reason_for_art.upcase ==  'UNKNOWN'
        when 'HIV STAGING'
          if encounter_available.blank? and user_selected_activities.match(/Manage HIV staging visits/i) 
            extended_staging_questions = get_global_property_value('use.extended.staging.questions')
            extended_staging_questions = extended_staging_questions.property_value == 'yes' rescue false
            task.url = "/encounters/new/hiv_staging?show&patient_id=#{patient.id}" if not extended_staging_questions 
            task.url = "/encounters/new/llh_hiv_staging?show&patient_id=#{patient.id}" if extended_staging_questions
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage HIV staging visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if (reason_for_art.upcase ==  'UNKNOWN' or reason_for_art.blank?)
        when 'HIV RECEPTION'
          encounter_art_initial = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
                                         patient.id,EncounterType.find_by_name('ART_INITIAL').id],
                                         :order =>'encounter_datetime DESC',:limit => 1)
          transfer_in = encounter_art_initial.observations.collect{|r|r.to_s.strip.upcase}.include?('HAS TRANSFER LETTER: YES'.upcase)
          hiv_staging = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
                        patient.id,EncounterType.find_by_name('HIV STAGING').id],:order => "encounter_datetime DESC")
          
          if transfer_in and hiv_staging.blank? and user_selected_activities.match(/Manage HIV first visits/i)
            task.url = "/encounters/new/hiv_staging?show&patient_id=#{patient.id}" 
            task.encounter_type = 'HIV STAGING'
            return task
          elsif encounter_available.blank? and user_selected_activities.match(/Manage HIV reception visits/i)
            task.url = "/encounters/new/hiv_reception?show&patient_id=#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage HIV reception visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end
        when 'ART_INITIAL'
          encounter_art_initial = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
                                         patient.id,EncounterType.find_by_name(type).id],
                                         :order =>'encounter_datetime DESC',:limit => 1)

          if encounter_art_initial.blank? and user_selected_activities.match(/Manage HIV first visits/i)
            task.url = "/encounters/new/art_initial?show&patient_id=#{patient.id}"
            return task
          elsif encounter_art_initial.blank? and not user_selected_activities.match(/Manage HIV first visits/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end
        when 'DISPENSING'
          treatment = Encounter.find(:first,:conditions =>["patient_id = ? AND DATE(encounter_datetime) = ? AND encounter_type = ?",
                            patient.id,session_date,EncounterType.find_by_name('TREATMENT').id])

          if encounter_available.blank? and user_selected_activities.match(/Manage drug dispensations/i)
            task.url = "/patients/treatment_dashboard/#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage drug dispensations/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not treatment.blank?
        when 'TREATMENT'
          encounter_art_visit = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name('ART VISIT').id,session_date],
                                   :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

          prescribe_arvs = encounter_art_visit.observations.map{|obs| obs.to_s.strip.upcase }.include? 'Prescribe ARVs this visit:  Yes'.upcase
          not_refer_to_clinician = encounter_art_visit.observations.map{|obs| obs.to_s.strip.upcase }.include? 'Refer to ART clinician:  No'.upcase

          if prescribe_arvs and not_refer_to_clinician 
            show_treatment = true
          else
            show_treatment = false
          end

          if encounter_available.blank? and user_selected_activities.match(/Manage prescriptions/i)
            task.url = "/regimens/new?patient_id=#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage prescriptions/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if show_treatment

          if not show_treatment
            if not encounter_art_visit.blank? and user_selected_activities.match(/Manage ART visits/i)
              task.url = "/encounters/new/art_visit?show&patient_id=#{patient.id}"
              return task
            elsif not encounter_art_visit.blank? and not user_selected_activities.match(/Manage ART visits/i)
              task.url = "/patients/show/#{patient.id}"
              return task
            end if not reason_for_art.upcase ==  'UNKNOWN'
          end
        when 'ART ADHERENCE'
          if encounter_available.blank? and user_selected_activities.match(/Manage ART adherence/i)
            task.url = "/encounters/new/art_adherence?show&patient_id=#{patient.id}"
            return task
          elsif encounter_available.blank? and not user_selected_activities.match(/Manage ART adherence/i)
            task.url = "/patients/show/#{patient.id}"
            return task
          end if not drug_given_before(patient,session_date).blank?
      end
    end
    #task.encounter_type = 'Visit complete ...'
    task.encounter_type = 'NONE'
    task.url = "/patients/show/#{patient.id}"
    return task
  end

  def self.next_task(patient)
    session_date = session[:datetime].to_date rescue Date.today
    task = main_next_task(Location.current_location, patient,session_date)
    begin
      return task.url if task.present? && task.url.present?
      return "/patients/show/#{patient.id}" 
    rescue
      return "/patients/show/#{patient.id}" 
    end
  end

  # Try to find the next task for the patient at the given location
  def self.main_next_task(location, patient, session_date = Date.today)
    if GlobalProperty.use_user_selected_activities
      return next_form(location , patient , session_date)
    end
    all_tasks = Task.all(:order => 'sort_weight ASC')
    todays_encounters = patient.encounters.find_by_date(session_date)
    todays_encounter_types = todays_encounters.map{|e| e.type.name rescue ''}.uniq rescue []
    all_tasks.each do |task|
      next if todays_encounters.map{ | e | e.name }.include?(task.encounter_type)
      # Is the task for this location?
      next unless task.location.blank? || task.location == '*' || location.name.match(/#{task.location}/)

      # Have we already run this task?
      next if task.encounter_type.present? && todays_encounter_types.include?(task.encounter_type)

      # By default, we don't want to skip this task
      skip = false
 
      # Skip this task if this is a gender specific task and the gender does not match?
      # For example, if this is a female specific check and the patient is not female, we want to skip it
      skip = true if task.gender.present? && patient.person.gender != task.gender

      # Check for an observation made today with a specific value, skip this task unless that observation exists
      # For example, if this task is the art_clinician task we want to skip it unless REFER TO CLINICIAN = yes
      if task.has_obs_concept_id.present?
        if (task.has_obs_scope.blank? || task.has_obs_scope == 'TODAY')
          obs = Observation.first(:conditions => [
          'encounter_id IN (?) AND concept_id = ? AND (value_coded = ? OR value_drug = ? OR value_datetime = ? OR value_numeric = ? OR value_text = ?)',
          todays_encounters.map(&:encounter_id),
          task.has_obs_concept_id,
          task.has_obs_value_coded,
          task.has_obs_value_drug,
          task.has_obs_value_datetime,
          task.has_obs_value_numeric,
          task.has_obs_value_text])
        end
        
        # Only the most recent obs
        # For example, if there are mutliple REFER TO CLINICIAN = yes, than only take the most recent one
        if (task.has_obs_scope == 'RECENT')
          o = patient.person.observations.recent(1).first(:conditions => ['encounter_id IN (?) AND concept_id =? AND DATE(obs_datetime)=?', todays_encounters.map(&:encounter_id), task.has_obs_concept_id,session_date])
          obs = 0 if (!o.nil? && o.value_coded == task.has_obs_value_coded && o.value_drug == task.has_obs_value_drug &&
            o.value_datetime == task.has_obs_value_datetime && o.value_numeric == task.has_obs_value_numeric &&
            o.value_text == task.has_obs_value_text )
        end
          
        skip = true unless obs.present?
      end

      # Check for a particular current order type, skip this task unless the order exists
      # For example, if this task is /dispensation/new we want to skip it if there is not already a drug order
      if task.has_order_type_id.present?
        skip = true unless Order.unfinished.first(:conditions => {:order_type_id => task.has_order_type_id}).present?
      end

      # Check for a particular program at this location, skip this task if the patient is not in the required program
      # For example if this is the hiv_reception task, we want to skip it if the patient is not currently in the HIV PROGRAM
      if task.has_program_id.present? && (task.has_program_workflow_state_id.blank? || task.has_program_workflow_state_id == '*')
        patient_program = PatientProgram.current.first(:conditions => [
          'patient_program.patient_id = ? AND patient_program.location_id = ? AND patient_program.program_id = ?',
          patient.patient_id,
          Location.current_health_center.location_id,
          task.has_program_id])        
        skip = true unless patient_program.present?
      end

      # Check for a particular program state at this location, skip this task if the patient does not have the required program/state
      # For example if this is the art_followup task, we want to skip it if the patient is not currently in the HIV PROGRAM with the state FOLLOWING
      if task.has_program_id.present? && task.has_program_workflow_state_id.present?
        patient_state = PatientState.current.first(:conditions => [
          'patient_program.patient_id = ? AND patient_program.location_id = ? AND patient_program.program_id = ? AND patient_state.state = ?',
          patient.patient_id,
          Location.current_health_center.location_id,
          task.has_program_id,
          task.has_program_workflow_state_id], :include => :patient_program)        
        skip = true unless patient_state.present?
      end
      
      # Check for a particular relationship, skip this task if the patient does not have the relationship
      # For example, if there is a CHW training update, skip this task if the person is not a CHW
      if task.has_relationship_type_id.present?        
        skip = true unless patient.relationships.first(
          :conditions => ['relationship.relationship = ?', task.has_relationship_type_id])
      end
 
      # Check for a particular identifier at this location
      # For example, this patient can only get to the Pre-ART room if they already have a pre-ART number, otherwise they need to go back to registration
      if task.has_identifier_type_id.present?
        skip = true unless patient.patient_identifiers.first(
          :conditions => ['patient_identifier.identifier_type = ? AND patient_identifier.location_id = ?', task.has_identifier_type_id, Location.current_health_center.location_id])
      end
  
      if task.has_encounter_type_today.present?
        enc = nil
        if todays_encounters.collect{|e|e.name}.include?(task.has_encounter_type_today)
          enc = task.has_encounter_type_today
        end
        skip = true unless enc.present?
      end

      if task.encounter_type == 'ART ADHERENCE' and drug_given_before(patient,session_date).blank?
        skip = true
      end
      
      if task.encounter_type == 'ART VISIT' and (reason_for_art_eligibility(patient).blank? or reason_for_art_eligibility(patient).match(/unknown/i))
        skip = true
      end
      
      if task.encounter_type == 'HIV STAGING' and not (reason_for_art_eligibility(patient).blank? or reason_for_art_eligibility(patient).match(/unknown/i))
        skip = true
      end
      
      # Reverse the condition if the task wants the negative (for example, if the patient doesn't have a specific program yet, then run this task)
      skip = !skip if task.skip_if_has == 1

      # We need to skip this task for some reason
      next if skip

      if location.name.match(/HIV|ART/i) and not location.name.match(/Outpatient/i)
       task = validate_task(patient,task,location,session_date.to_date)
      end

      # Nothing failed, this is the next task, lets replace any macros
      task.url = task.url.gsub(/\{patient\}/, "#{patient.patient_id}")
      task.url = task.url.gsub(/\{person\}/, "#{patient.person.person_id rescue nil}")
      task.url = task.url.gsub(/\{location\}/, "#{location.location_id}")

      logger.debug "next_task: #{task.id} - #{task.description}"
      
      return task
    end
  end
  
  
  def self.validate_task(patient, task, location, session_date = Date.today)
    #return task unless task.has_program_id == 1
    return task if task.encounter_type == 'REGISTRATION'
    # allow EID patients at HIV clinic, but don't validate tasks
    return task if task.has_program_id == 4
    
    #check if the latest HIV program is closed - if yes, the app should redirect the user to update state screen
    if patient.encounters.find_by_encounter_type(EncounterType.find_by_name('ART_INITIAL').id)
      latest_hiv_program = [] ; patient.patient_programs.collect{ | p |next unless p.program_id == 1 ; latest_hiv_program << p } 
      if latest_hiv_program.last.closed?
        task.url = '/patients/programs_dashboard/{patient}' ; task.encounter_type = 'Program enrolment'
        return task
      end rescue nil
    end

    return task if task.url == "/patients/show/{patient}"

    art_encounters = ['ART_INITIAL','HIV RECEPTION','VITALS','HIV STAGING','ART VISIT','ART ADHERENCE','TREATMENT','DISPENSING']

    #if the following happens - that means the patient is a transfer in and the reception are trying to stage from the transfer in sheet
    if task.encounter_type == 'HIV STAGING' and location.name.match(/RECEPTION/i)
      return task 
    end

    #if the following happens - that means the patient was refered to see a clinician
    if task.description.match(/REFER/i) and location.name.match(/Clinician/i)
      return task 
    end

    if patient.encounters.find_by_encounter_type(EncounterType.find_by_name(art_encounters[0]).id).blank? and task.encounter_type != art_encounters[0]
      task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
      task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[0].gsub(' ','_')}") 
      return task
    elsif patient.encounters.find_by_encounter_type(EncounterType.find_by_name(art_encounters[0]).id).blank? and task.encounter_type == art_encounters[0]
      return task
    end
    
    hiv_reception = Encounter.find(:first,
                                   :conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name(art_encounters[1]).id,session_date],
                                   :order =>'encounter_datetime DESC')

    if hiv_reception.blank? and task.encounter_type != art_encounters[1]
      task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
      task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[1].gsub(' ','_')}") 
      return task
    elsif hiv_reception.blank? and task.encounter_type == art_encounters[1]
      return task
    end



    reception = Encounter.find(:first,:conditions =>["patient_id = ? AND DATE(encounter_datetime) = ? AND encounter_type = ?",
                        patient.id,session_date,EncounterType.find_by_name(art_encounters[1]).id]).collect{|r|r.to_s}.join(',') rescue ''
    
    if reception.match(/PATIENT PRESENT FOR CONSULTATION:  YES/i)
      vitals = Encounter.find(:first,
                              :conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                              patient.id,EncounterType.find_by_name(art_encounters[2]).id,session_date],
                              :order =>'encounter_datetime DESC')

      if vitals.blank? and task.encounter_type != art_encounters[2]
        task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
        task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[2].gsub(' ','_')}") 
        return task
      elsif vitals.blank? and task.encounter_type == art_encounters[2]
        return task
      end
    end

    hiv_staging = patient.encounters.find_by_encounter_type(EncounterType.find_by_name(art_encounters[3]).id)
    art_reason = patient_obj.person.observations.recent(1).question("REASON FOR ART ELIGIBILITY").all rescue nil
    reasons = art_reason.map{|c|ConceptName.find(c.value_coded_name_id).name}.join(',') rescue ''

    if ((reasons.blank?) and (task.encounter_type == art_encounters[3]))
      return task
    elsif hiv_staging.blank? and task.encounter_type != art_encounters[3]
      task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
      task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[3].gsub(' ','_')}") 
      return task
    elsif hiv_staging.blank? and task.encounter_type == art_encounters[3]
      return task
    end

    pre_art_visit = Encounter.find(:first,
                                   :conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient.id,EncounterType.find_by_name('PART_FOLLOWUP').id,session_date],
                                   :order =>'encounter_datetime DESC',:limit => 1)

    if pre_art_visit.blank?
      art_visit = Encounter.find(:first,
                                     :conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                     patient.id,EncounterType.find_by_name(art_encounters[4]).id,session_date],
                                     :order =>'encounter_datetime DESC',:limit => 1)

      if art_visit.blank? and task.encounter_type != art_encounters[4]
        #checks if we need to do a pre art visit
        if task.encounter_type == 'PART_FOLLOWUP' 
          return task
        elsif reasons.upcase == 'UNKNOWN' or reasons.blank?
          task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
          return task
        end
        task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
        task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[4].gsub(' ','_')}") 
        return task
      elsif art_visit.blank? and task.encounter_type == art_encounters[4]
        return task
      end
    end

    unless self.drug_given_before(patient,session_date).blank?
      art_adherance = Encounter.find(:first,
                                     :conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                     patient.id,EncounterType.find_by_name(art_encounters[5]).id,session_date],
                                     :order =>'encounter_datetime DESC',:limit => 1)
      
      if art_adherance.blank? and task.encounter_type != art_encounters[5]
        task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
        task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[5].gsub(' ','_')}") 
        return task
      elsif art_adherance.blank? and task.encounter_type == art_encounters[5]
        return task
      end
    end

    if prescribe_arv_this_visit(patient, session_date)
      art_treatment = Encounter.find(:first,
                                     :conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                     patient.id,EncounterType.find_by_name(art_encounters[6]).id,session_date],
                                     :order =>'encounter_datetime DESC',:limit => 1)
      if art_treatment.blank? and task.encounter_type != art_encounters[6]
        task.url = "/patients/summary?patient_id={patient}&skipped={encounter_type}" 
        task.url = task.url.gsub(/\{encounter_type\}/, "#{art_encounters[6].gsub(' ','_')}") 
        return task
      elsif art_treatment.blank? and task.encounter_type == art_encounters[6]
        return task
      end
    end

    task
  end

  def self.patient_national_id_label(patient)
	  patient_bean = get_patient(patient.person)
    return unless patient_bean.national_id
    sex =  patient_bean.sex.match(/F/i) ? "(F)" : "(M)"
    address = patient.person.address.strip[0..24].humanize rescue ""
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,5,15,120,false,"#{patient_bean.national_id}")
    label.draw_multi_text("#{patient_bean.name.titleize}")
    label.draw_multi_text("#{patient_bean.national_id_with_dashes} #{patient_bean.birth_date}#{sex}")
    label.draw_multi_text("#{address}")
    label.print(1)
  end

  def self.recent_sputum_submissions(patient_id)
    sputum_concept_names = ["AAFB(1st)", "AAFB(2nd)", "AAFB(3rd)", "Culture(1st)", "Culture(2nd)"]
    sputum_concept_ids = ConceptName.find(:all, :conditions => ["name IN (?)", sputum_concept_names]).map(&:concept_id)
    Observation.find(:all, :conditions => ["person_id = ? AND concept_id = ? AND (value_coded in (?) OR value_text in (?))",patient_id, ConceptName.find_by_name('Sputum submission').concept_id, sputum_concept_ids, sputum_concept_names], :order => "obs_datetime desc", :limit => 3) rescue []
  end

  def self.recent_sputum_results(patient_id)
    sputum_concept_names = ["AAFB(1st) results", "AAFB(2nd) results", "AAFB(3rd) results", "Culture(1st) Results", "Culture-2 Results"]
    sputum_concept_ids = ConceptName.find(:all, :conditions => ["name IN (?)", sputum_concept_names]).map(&:concept_id)
    obs = Observation.find(:all, :conditions => ["person_id = ? AND concept_id IN (?)", patient_id, sputum_concept_ids], :order => "obs_datetime desc", :limit => 3)
  end

  def self.sputum_orders_without_submission(patient_id)
    self.recent_sputum_orders(patient_id).collect{|order| order unless Observation.find(:all, :conditions => ["person_id = ? AND concept_id = ?", patient_id, Concept.find_by_name("Sputum submission")]).map{|o| o.accession_number}.include?(order.accession_number)}.compact #rescue []
  end

  def self.recent_sputum_orders(patient_id)
    sputum_concept_names = ["AAFB(1st)", "AAFB(2nd)", "AAFB(3rd)", "Culture(1st)", "Culture(2nd)"]
    sputum_concept_ids = ConceptName.find(:all, :conditions => ["name IN (?)", sputum_concept_names]).map(&:concept_id)
    Observation.find(:all, :conditions => ["person_id = ? AND concept_id = ? AND (value_coded in (?) OR value_text in (?))", patient_id, ConceptName.find_by_name('Tests ordered').concept_id, sputum_concept_ids, sputum_concept_names], :order => "obs_datetime desc", :limit => 3)
  end

  def self.hiv_test_date(patient_id)
    test_date = Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ?", patient_id, ConceptName.find_by_name("HIV test date").concept_id]).value_datetime rescue nil
    return test_date
  end

  def self.months_since_last_hiv_test(patient_id)
    #this can be done better
    session_date = Observation.find(:last, :conditions => ["person_id = ? AND concept_id = ?", patient_id, ConceptName.find_by_name("HIV test date").concept_id]).obs_datetime rescue Date.today

    today =  session_date
    hiv_test_date = self.hiv_test_date(patient_id)
    months = (today.year * 12 + today.month) - (hiv_test_date.year * 12 + hiv_test_date.month) rescue nil
    return months
  end

  def self.patient_hiv_status(patient)
    status = Concept.find(Observation.find(:first,
    :order => "obs_datetime DESC,date_created DESC",
    :conditions => ["value_coded IS NOT NULL AND person_id = ? AND concept_id = ?", patient.id,
    ConceptName.find_by_name("HIV STATUS").concept_id]).value_coded).fullname rescue "UNKNOWN"
    if status.upcase == 'UNKNOWN'
      return patient.patient_programs.collect{|p|p.program.name}.include?('HIV PROGRAM') ? 'Positive' : status
    end
    return status
  end
=begin
  def get_patients_identifier(patient, identifier_type, force = false)
    id = patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name(identifier_type).id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name(identifier_type).next_identifier(:patient => patient).identifier
    id
  end
=end

 def self.patient_is_child?(patient)
   return self.get_patient_attribute_value(patient, "age") <= 14 unless self.get_patient_attribute_value(patient, "age").nil?
   return false
 end

 def self.get_patient_attribute_value(patient, attribute_name)
 	
   patient_bean = get_patient(patient.person)
   if patient_bean.sex.upcase == 'MALE'
   		sex = 'M'
   elsif patient_bean.sex.upcase == 'FEMALE'
   		sex = 'F'
   end
   
   case attribute_name.upcase
     when "AGE"
       return patient_bean.age
     when "RESIDENCE"
       return patient_bean.address
     when "CURRENT_HEIGHT"
      obs = patient.person.observations.recent(1).question("HEIGHT (CM)").all
      return obs.first.value_numeric rescue 0
     when "CURRENT_WEIGHT"
      obs = patient.person.observations.recent(1).question("WEIGHT (KG)").all
      return obs.first.value_numeric rescue 0
     when "INITIAL_WEIGHT"
      obs = patient.person.observations.old(1).question("WEIGHT (KG)").all
      return obs.last.value_numeric rescue 0
     when "INITIAL_HEIGHT"
      obs = patient.person.observations.old(1).question("HEIGHT (CM)").all
      return obs.last.value_numeric rescue 0
     when "INITIAL_BMI"
      obs = patient.person.observations.old(1).question("BMI").all
      return obs.last.value_numeric rescue nil
     when "MIN_WEIGHT"
      return WeightHeight.min_weight(sex, patient_bean.age_in_months).to_f
     when "MAX_WEIGHT"
      return WeightHeight.max_weight(sex, patient_bean.age_in_months).to_f
     when "MIN_HEIGHT"
      return WeightHeight.min_height(sex, patient_bean.age_in_months).to_f
     when "MAX_HEIGHT"
      return WeightHeight.max_height(sex, patient_bean.age_in_months).to_f
   end

 end

 def self.patient_tb_status(patient)
   Concept.find(Observation.find(:first,
    :order => "obs_datetime DESC,date_created DESC",
    :conditions => ["person_id = ? AND concept_id = ? AND value_coded IS NOT NULL",
                    patient.id,
    ConceptName.find_by_name("TB STATUS").concept_id]).value_coded).fullname rescue "UNKNOWN"
 end
 
 def self.get_global_property_value(global_property)
    GlobalProperty.find(:first,
                        :conditions => {:property => "#{global_property}"}
                       ).property_value
 end

 def self.reason_for_art_eligibility(patient)
    reasons = patient.person.observations.recent(1).question("REASON FOR ART ELIGIBILITY").all rescue nil
    reasons.map{|c|ConceptName.find(c.value_coded_name_id).name}.join(',') rescue nil
 end

 def self.patient_appointment_dates(patient, start_date, end_date = nil)

    end_date = start_date if end_date.nil?

    appointment_date_concept_id = Concept.find_by_name("APPOINTMENT DATE").concept_id rescue nil

    appointments = Observation.find(:all,
      :conditions => ["DATE(obs.value_datetime) >= ? AND DATE(obs.value_datetime) <= ? AND " +
          "obs.concept_id = ? AND obs.voided = 0 AND obs.person_id = ?", start_date.to_date,
        end_date.to_date, appointment_date_concept_id, patient.id])

    appointments
  end

  def self.get_patient_identifier(patient, identifier_type)
    patient_identifier_type_id = PatientIdentifierType.find_by_name(identifier_type).patient_identifier_type_id
    patient_identifier = PatientIdentifier.find(:first, :select => "identifier",
                                                :conditions  =>["patient_id = ? and identifier_type = ?", patient.id, patient_identifier_type_id],
                                                :order => "date_created DESC" ).identifier rescue nil
    return patient_identifier
  end

  def self.patient_printing_message(new_patient , archived_patient , creating_new_filing_number_for_patient = false)
    arv_code = Location.current_arv_code
    
    new_patient_bean = get_patient(new_patient.person)
    archived_patient_bean = get_patient(archived_patient.person) rescue nil
    
    new_patient_name = new_patient_bean.name
    new_filing_number = patient_printing_filing_number_label(new_patient_bean.filing_number)
    old_archive_filing_number = patient_printing_filing_number_label(new_patient_bean.archived_filing_number)
    unless archived_patient.blank?
      old_active_filing_number = patient_printing_filing_number_label(old_filing_number(archived_patient))
      new_archive_filing_number = patient_printing_filing_number_label(archived_patient_bean.archived_filing_number)
    end

    if new_patient and archived_patient and creating_new_filing_number_for_patient
      table = <<EOF
<div id='patients_info_div'>
<table id = 'filing_info'>
<tr>
  <th class='filing_instraction'>Filing actions required</th>
  <th class='filing_instraction'>Name</th>
  <th style="text-align:left;">Old label</th>
  <th style="text-align:left;">New label</th>
</tr>

<tr>
  <td style='text-align:left;'>Active → Dormant</td>
  <td class = 'filing_instraction'>#{archived_patient_bean.name}</td>
  <td class = 'old_label'>#{old_active_filing_number}</td>
  <td class='new_label'>#{new_archive_filing_number}</td>
</tr>

<tr>
  <td style='text-align:left;'>Add → Active</td>
  <td class = 'filing_instraction'>#{new_patient_name}</td>
  <td class = 'old_label'>#{old_archive_filing_number}</td>
  <td class='new_label'>#{new_filing_number}</td>
</tr>
</table>
</div>
EOF
    elsif new_patient and creating_new_filing_number_for_patient
      table = <<EOF
<div id='patients_info_div'>
<table id = 'filing_info'>
<tr>
  <th class='filing_instraction'>Filing actions required</th>
  <th class='filing_instraction'>Name</th>
  <th>&nbsp;</th>
  <th style="text-align:left;">New label</th>
</tr>

<tr>
  <td style='text-align:left;'>Add → Active</td>
  <td class = 'filing_instraction'>#{new_patient_name}</td>
  <td class = 'filing_instraction'>&nbsp;</td>
  <td class='new_label'>#{new_filing_number}</td>
</tr>
</table>
</div>
EOF
    elsif new_patient and archived_patient and not creating_new_filing_number_for_patient
      table = <<EOF
<div id='patients_info_div'>
<table id = 'filing_info'>
<tr>
  <th class='filing_instraction'>Filing actions required</th>
  <th class='filing_instraction'>Name</th>
  <th style="text-align:left;">Old label</th>
  <th style="text-align:left;">New label</th>
</tr>

<tr>
  <td style='text-align:left;'>Active → Dormant</td>
  <td class = 'filing_instraction'>#{archived_patient_bean.name}</td>
  <td class = 'old_label'>#{old_active_filing_number}</td>
  <td class='new_label'>#{new_archive_filing_number}</td>
</tr>

<tr>
  <td style='text-align:left;'>Add → Active</td>
  <td class = 'filing_instraction'>#{new_patient_name}</td>
  <td class = 'old_label'>#{old_archive_filing_number}</td>
  <td class='new_label'>#{new_filing_number}</td>
</tr>
</table>
</div>
EOF
    elsif new_patient and not creating_new_filing_number_for_patient
      table = <<EOF
<div id='patients_info_div'>
<table id = 'filing_info'>
<tr>
  <th class='filing_instraction'>Filing actions required</th>
  <th class='filing_instraction'>Name</th>
  <th>Old label</th>
  <th style="text-align:left;">New label</th>
</tr>

<tr>
  <td style='text-align:left;'>Add → Active</td>
  <td class = 'filing_instraction'>#{new_patient_name}</td>
  <td class = 'old_label'>#{old_archive_filing_number}</td>
  <td class='new_label'>#{new_filing_number}</td>
</tr>
</table>
</div>
EOF
    end

    return table
  end

  def self.patient_printing_filing_number_label(number=nil)
    return number[5..5] + " " + number[6..7] + " " + number[8..-1] unless number.nil?
  end

  def self.patient_age_at_initiation(patient, initiation_date = nil)
    return self.age(patient.person, initiation_date) unless initiation_date.nil?
  end

  def self.art_patient?(patient)
    program_id = Program.find_by_name('HIV PROGRAM').id
    enrolled = PatientProgram.find(:first,:conditions =>["program_id = ? AND patient_id = ?",program_id,patient.id]).blank?
    return true unless enrolled
    false
  end

  def self.patient_art_start_date(patient_id)
    date = ActiveRecord::Base.connection.select_value <<EOF
SELECT patient_start_date(#{patient_id})
EOF
    return date.to_date rescue nil
  end

  def self.prescribe_arv_this_visit(patient, date = Date.today)
    encounter_type = EncounterType.find_by_name('ART VISIT')
    yes_concept = ConceptName.find_by_name('YES').concept_id
    refer_concept = ConceptName.find_by_name('PRESCRIBE ARVS THIS VISIT').concept_id
    refer_patient = Encounter.find(:first,
      :joins => 'INNER JOIN obs USING (encounter_id)',
      :conditions => ["encounter_type = ? AND concept_id = ? AND person_id = ? AND value_coded = ? AND DATE(obs_datetime) = ?",
        encounter_type.id,refer_concept,patient.id,yes_concept,date.to_date],
      :order => 'encounter_datetime DESC,date_created DESC')
    return false if refer_patient.blank?
    return true
  end

  def self.drug_given_before(patient, date = Date.today)
    encounter_type = EncounterType.find_by_name('TREATMENT')
    Encounter.find(:first,
      :joins => 'INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
               INNER JOIN drug_order ON orders.order_id = orders.order_id',
      :conditions => ["quantity IS NOT NULL AND encounter_type = ? AND
               encounter.patient_id = ? AND DATE(encounter_datetime) < ?",
        encounter_type.id,patient.id,date.to_date],
        :order => 'encounter_datetime DESC,date_created DESC').orders rescue []
  end

  def self.get_patient(person)
    patient = PatientBean.new('')
    patient.person_id = person.id
    patient.patient_id = person.patient.id
    patient.arv_number = get_patient_identifier(person.patient, 'ARV Number')
    patient.address = person.addresses.first.city_village
    patient.national_id = get_patient_identifier(person.patient, 'National id')    
	  patient.national_id_with_dashes = get_national_id_with_dashes(person.patient)
    patient.name = person.names.first.given_name + ' ' + person.names.first.family_name rescue nil
    patient.sex = sex(person)
    patient.age = age(person)
    patient.age_in_months = age_in_months(person)
    patient.dead = person.dead
    patient.birth_date = birthdate_formatted(person)
    patient.birthdate_estimated = person.birthdate_estimated
    patient.home_district = person.addresses.first.address2
    patient.traditional_authority = person.addresses.first.county_district
    patient.current_residence = person.addresses.first.city_village
    patient.mothers_surname = person.names.first.family_name2
    patient.eid_number = get_patient_identifier(person.patient, 'EID Number')
    patient.pre_art_number = get_patient_identifier(person.patient, 'Pre ART Number (Old format)')
    patient.archived_filing_number = get_patient_identifier(person.patient, 'Archived filing number')
    patient.filing_number = get_patient_identifier(person.patient, 'Filing Number')
    patient.occupation = get_attribute(person, 'Occupation')
    patient.guardian = art_guardian(patient_obj) rescue nil 
    patient
  end

  def self.name(person)
    "#{person.names.first.given_name} #{person.names.first.family_name}".titleize rescue nil
  end
  
  def self.age(person, today = Date.today)
    return nil if person.birthdate.nil?

    # This code which better accounts for leap years
    patient_age = (today.year - person.birthdate.year) + ((today.month - person.birthdate.month) + ((today.day - person.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date=person.birthdate
    estimate=person.birthdate_estimated==1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  && 
      today.month < birth_date.month && person.date_created.year == today.year) ? 1 : 0
  end

  # Convert a list +Concept+s of +Regimen+s for the given +Patient+ <tt>age</tt>
  # into select options. See also +EncountersController#arv_regimen_answers+
  def self.regimen_options(regimen_concepts, age)
    options = regimen_concepts.map{ |r|
      [r.concept_id,

        (r.concept_names.typed("SHORT").first ||
        r.concept_names.typed("FULLY_SPECIFIED").first).name]
    }
	
    suffixed_options = options.collect{ |opt|
      opt_reg = Regimen.find(:all,
                             :select => 'regimen_index',
							 :order => 'regimen_index',
                             :conditions => ['concept_id = ?', opt[0]]
                            ).uniq.first
      if age >= 15
        suffix = "A"
      else
        suffix = "P"
      end

      #[opt[0], "#{opt_reg.regimen_index}#{suffix} - #{opt[1]}"]
		if opt_reg.regimen_index > -1
      		["#{opt_reg.regimen_index}#{suffix} - #{opt[1]}", opt[0], opt_reg.regimen_index.to_i]
		else
      		["#{opt[1]}", opt[0], opt_reg.regimen_index.to_i]
		end
    }.sort_by{|opt| opt[2]}

  end

  def self.old_filing_number(patient, type = 'Filing Number')
    identifier_type = PatientIdentifierType.find_by_name(type)
    PatientIdentifier.find_by_sql(["
      SELECT * FROM patient_identifier
      WHERE patient_id = ?
      AND identifier_type = ?
      AND voided = 1
      ORDER BY date_created DESC
      LIMIT 1",patient.id,identifier_type.id]).first.identifier rescue nil
  end

  def self.patient_to_be_archived(patient)
    active_identifier_type = PatientIdentifierType.find_by_name("Filing Number")
    PatientIdentifier.find_by_sql(["
      SELECT * FROM patient_identifier
      WHERE voided = 1 AND identifier_type = ? AND void_reason = ? ORDER BY date_created DESC",
        active_identifier_type.id,"Archived - filing number given to:#{patient.id}"]).first.patient rescue nil
  end

  def self.set_patient_filing_number(patient) #changed from set_filing_number after being moved from patient model
    next_filing_number = PatientIdentifier.next_filing_number # gets the new filing number!
    # checks if the the new filing number has passed the filing number limit...
    # move dormant patient from active to dormant filing area ... if needed
    self.next_filing_number_to_be_archived(patient, next_filing_number)
  end

  def self.next_filing_number_to_be_archived(current_patient , next_filing_number)
    ActiveRecord::Base.transaction do
      global_property_value = GlobalProperty.find_by_property("filing.number.limit").property_value rescue '10000'
      active_filing_number_identifier_type = PatientIdentifierType.find_by_name("Filing Number")
      dormant_filing_number_identifier_type = PatientIdentifierType.find_by_name('Archived filing number')

      if (next_filing_number[5..-1].to_i >= global_property_value.to_i)
        encounter_type_name = ['REGISTRATION','VITALS','ART_INITIAL','ART VISIT',
          'TREATMENT','HIV RECEPTION','HIV STAGING','DISPENSING','APPOINTMENT']
        encounter_type_ids = EncounterType.find(:all,:conditions => ["name IN (?)",encounter_type_name]).map{|n|n.id}

        all_filing_numbers = PatientIdentifier.find(:all, :conditions =>["identifier_type = ?",
            PatientIdentifierType.find_by_name("Filing Number").id],:group=>"patient_id")
        patient_ids = all_filing_numbers.collect{|i|i.patient_id}
        patient_to_be_archived = Encounter.find_by_sql(["
          SELECT patient_id, MAX(encounter_datetime) AS last_encounter_id
          FROM encounter
          WHERE patient_id IN (?)
          AND encounter_type IN (?)
          GROUP BY patient_id
          ORDER BY last_encounter_id
          LIMIT 1",patient_ids,encounter_type_ids]).first.patient rescue nil
        if patient_to_be_archived.blank?
          patient_to_be_archived = PatientIdentifier.find(:last,:conditions =>["identifier_type = ?",
              PatientIdentifierType.find_by_name("Filing Number").id],
            :group=>"patient_id",:order => "identifier DESC").patient rescue nil
        end
      end

      if patient_to_be_archived
        filing_number = PatientIdentifier.new()
        filing_number.patient_id = patient_to_be_archived.id
        filing_number.identifier_type = dormant_filing_number_identifier_type.id
        filing_number.identifier = PatientIdentifier.next_filing_number("Archived filing number")
        filing_number.save

        #assigning "patient_to_be_archived" filing number to the new patient
        filing_number= PatientIdentifier.new()
        filing_number.patient_id = current_patient.id
        filing_number.identifier_type = active_filing_number_identifier_type.id
        filing_number.identifier = self.get_patient_identifier(patient_to_be_archived, 'Filing Number')
        filing_number.save

        #void current filing number
        current_filing_numbers =  PatientIdentifier.find(:all,:conditions=>["patient_id=? AND identifier_type = ?",
            patient_to_be_archived.id,PatientIdentifierType.find_by_name("Filing Number").id])
        current_filing_numbers.each do | filing_number |
          filing_number.voided = 1
          filing_number.voided_by = User.current_user.id
          filing_number.void_reason = "Archived - filing number given to:#{current_patient.id}"
          filing_number.date_voided = Time.now()
          filing_number.save
        end
      else
        filing_number = PatientIdentifier.new()
        filing_number.patient_id = current_patient.id
        filing_number.identifier_type = active_filing_number_identifier_type.id
        filing_number.identifier = next_filing_number
        filing_number.save
      end
    end

    true
  end
  
	def self.create_from_form(params)
		address_params = params["addresses"]
		names_params = params["names"]
		patient_params = params["patient"]
		params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|relation|cell_phone_number|home_phone_number|office_phone_number|agrees_to_be_visited_for_TB_therapy|agrees_phone_text_for_TB_therapy/) }
		birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }
		person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate|occupation/) }


		if person_params["gender"].to_s == "Female"
		   person_params["gender"] = 'F'
		elsif person_params["gender"].to_s == "Male"
		   person_params["gender"] = 'M'
		end

		person = Person.create(person_params)

		unless birthday_params.empty?
		  if birthday_params["birth_year"] == "Unknown"
			self.set_birthdate_by_age(person, birthday_params["age_estimate"], person.session_datetime || Date.today)
		  else
			self.set_birthdate(person, birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
		  end
		end
		person.save
	   
		person.names.create(names_params)
		person.addresses.create(address_params) unless address_params.empty? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Occupation").person_attribute_type_id,
		  :value => params["occupation"]) unless params["occupation"].blank? rescue nil
	 
		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id,
		  :value => params["cell_phone_number"]) unless params["cell_phone_number"].blank? rescue nil
	 
		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Office Phone Number").person_attribute_type_id,
		  :value => params["office_phone_number"]) unless params["office_phone_number"].blank? rescue nil
	 
		person.person_attributes.create(
		  :person_attribute_type_id => PersonAttributeType.find_by_name("Home Phone Number").person_attribute_type_id,
		  :value => params["home_phone_number"]) unless params["home_phone_number"].blank? rescue nil

	# TODO handle the birthplace attribute

		if (!patient_params.nil?)
		  patient = person.create_patient

		  patient_params["identifiers"].each{|identifier_type_name, identifier|
			next if identifier.blank?
			identifier_type = PatientIdentifierType.find_by_name(identifier_type_name) || PatientIdentifierType.find_by_name("Unknown id")
			patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
		  } if patient_params["identifiers"]

		  # This might actually be a national id, but currently we wouldn't know
		  #patient.patient_identifiers.create("identifier" => patient_params["identifier"], "identifier_type" => PatientIdentifierType.find_by_name("Unknown id")) unless params["identifier"].blank?
		end

		return person
	end

  def self.sex(person)
    value = nil
    if person.gender == "M"
      value = "Male"
    elsif person.gender == "F"
      value = "Female"
    end
    value
  end
  
  def self.person_search(params)
    people = self.search_by_identifier(params[:identifier])

    return people.first.id unless people.blank? || people.size > 1
    people = Person.find(:all, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
    "gender = ? AND \
     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \
     (person_name.family_name LIKE ? OR person_name_code.family_name_code LIKE ?)",
    params[:gender],
    params[:given_name],
    (params[:given_name] || '').soundex,
    params[:family_name],
    (params[:family_name] || '').soundex
    ]) if people.blank?

    return people
  end
  
  def self.search_by_identifier(identifier)
    PatientIdentifier.find_all_by_identifier(identifier).map{|id| id.patient.person} unless identifier.blank? rescue nil
  end
  
  def self.set_birthdate_by_age(person, age, today = Date.today)
    person.birthdate = Date.new(today.year - age.to_i, 7, 1)
    person.birthdate_estimated = 1
  end
  
  def self.set_birthdate(person, year = nil, month = nil, day = nil)   
    raise "No year passed for estimated birthdate" if year.nil?

    # Handle months by name or number (split this out to a date method)    
    month_i = (month || 0).to_i
    month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    
    if month_i == 0 || month == "Unknown"
      person.birthdate = Date.new(year.to_i,7,1)
      person.birthdate_estimated = 1
    elsif day.blank? || day == "Unknown" || day == 0
      person.birthdate = Date.new(year.to_i,month_i,15)
      person.birthdate_estimated = 1
    else
      person.birthdate = Date.new(year.to_i,month_i,day.to_i)
      person.birthdate_estimated = 0
    end
  end
  
  def self.birthdate_formatted(person)
    if person.birthdate_estimated==1
      if person.birthdate.day == 1 and person.birthdate.month == 7
        person.birthdate.strftime("??/???/%Y")
      elsif person.birthdate.day == 15 
        person.birthdate.strftime("??/%b/%Y")
      elsif person.birthdate.day == 1 and person.birthdate.month == 1 
        person.birthdate.strftime("??/???/%Y")
      end
    else
      person.birthdate.strftime("%d/%b/%Y")
    end
  end
  
  def self.age_in_months(person, today = Date.today)
    years = (today.year - person.birthdate.year)
    months = (today.month - person.birthdate.month)
    (years * 12) + months
  end
  
  def self.get_attribute(person, attribute)
    PersonAttribute.find(:first,:conditions =>["voided = 0 AND person_attribute_type_id = ? AND person_id = ?",
        PersonAttributeType.find_by_name(attribute).id, person.id]).value rescue nil
  end
  
  
  def self.next_lab_encounter(patient , encounter = nil , session_date = Date.today)
    if encounter.blank?
      type = EncounterType.find_by_name('LAB ORDERS').id
      lab_order = Encounter.find(:first,
             :order => "encounter_datetime DESC,date_created DESC",
             :conditions =>["patient_id = ? AND encounter_type = ?",patient.id,type])
      return 'NO LAB ORDERS' if lab_order.blank?
      return
    end

    case encounter.name.upcase
      when 'LAB ORDERS' 
        type = EncounterType.find_by_name('SPUTUM SUBMISSION').id
        sputum_sub = Encounter.find(:first,:joins => "INNER JOIN obs USING(encounter_id)",
               :conditions =>["obs.accession_number IN (?) AND patient_id = ? AND encounter_type = ?",
               encounter.observations.map{|r|r.accession_number}.compact,encounter.patient_id,type])

        return type if sputum_sub.blank?
        return sputum_sub 
      when 'SPUTUM SUBMISSION'
        type = EncounterType.find_by_name('LAB RESULTS').id
        lab_results = Encounter.find(:first,:joins => "INNER JOIN obs USING(encounter_id)",
               :conditions =>["obs.accession_number IN (?) AND patient_id = ? AND encounter_type = ?",
               encounter.observations.map{|r|r.accession_number}.compact,encounter.patient_id,type])

        type = EncounterType.find_by_name('LAB ORDERS').id
        lab_order = Encounter.find(:first,:joins => "INNER JOIN obs USING(encounter_id)",
               :conditions =>["obs.accession_number IN (?) AND patient_id = ? AND encounter_type = ?",
               encounter.observations.map{|r|r.accession_number}.compact,encounter.patient_id,type])

        return lab_order if lab_results.blank? and not lab_order.blank?
        return if lab_results.blank?
        return lab_results 
      when 'LAB RESULTS'
        type = EncounterType.find_by_name('SPUTUM SUBMISSION').id
        sputum_sub = Encounter.find(:first,:joins => "INNER JOIN obs USING(encounter_id)",
               :conditions =>["obs.accession_number IN (?) AND patient_id = ? AND encounter_type = ?",
               encounter.observations.map{|r|r.accession_number}.compact,encounter.patient_id,type])

        return if sputum_sub.blank?
        return sputum_sub 
    end
  end
  
  def self.checks_if_vitals_are_need(patient , session_date, task , user_selected_activities)
    first_vitals = Encounter.find(:first,:order => "encounter_datetime DESC",
                            :conditions =>["patient_id = ? AND encounter_type = ?",
                            patient.id,EncounterType.find_by_name('VITALS').id])


    if first_vitals.blank?
      encounter = Encounter.find(:first,:order => "encounter_datetime DESC",
                  :conditions =>["patient_id = ? AND encounter_type = ?",
                  patient.id,EncounterType.find_by_name('LAB ORDERS').id])
      
      sup_result = self.next_lab_encounter(patient , encounter, session_date)

      reception = Encounter.find(:first,:order => "encounter_datetime DESC",
                                 :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                                 session_date.to_date,patient.id,EncounterType.find_by_name('TB RECEPTION').id])

      if reception.blank? and not sup_result.blank?
        if user_selected_activities.match(/Manage TB Reception Visits/i)
          task.encounter_type = 'TB RECEPTION'
          task.url = "/encounters/new/tb_reception?show&patient_id=#{patient.id}"
          return task
        elsif not user_selected_activities.match(/Manage TB Reception Visits/i)
          task.encounter_type = 'TB RECEPTION'
          task.url = "/patients/show/#{patient.id}"
          return task
        end
      end if not (sup_result == 'NO LAB ORDERS')
    end

    if first_vitals.blank? and user_selected_activities.match(/Manage Vitals/i) 
      task.encounter_type = 'VITALS'
      task.url = "/encounters/new/vitals?patient_id=#{patient.id}"
      return task
    elsif first_vitals.blank? and not user_selected_activities.match(/Manage Vitals/i) 
      task.encounter_type = 'VITALS'
      task.url = "/patients/show/#{patient.id}"
      return task
    end

    return if self.patient_tb_status(patient).match(/treatment/i) and not self.patient_hiv_status(patient).match(/Positive/i)

    vitals = Encounter.find(:first,:order => "encounter_datetime DESC",
                            :conditions =>["DATE(encounter_datetime) = ? AND patient_id = ? AND encounter_type = ?",
                            session_date.to_date,patient.id,EncounterType.find_by_name('VITALS').id])

    if vitals.blank? and user_selected_activities.match(/Manage Vitals/i) 
      task.encounter_type = 'VITALS'
      task.url = "/encounters/new/vitals?patient_id=#{patient.id}"
      return task
    elsif vitals.blank? and not user_selected_activities.match(/Manage Vitals/i) 
      task.encounter_type = 'VITALS'
      task.url = "/patients/show/#{patient.id}"
      return task
    end 
  end

  def self.need_art_enrollment(task,patient,location,session_date,user_selected_activities,reason_for_art)
    return unless self.patient_hiv_status(patient).match(/Positive/i)

    enrolled_in_hiv_program = Concept.find(Observation.find(:first,
      :order => "obs_datetime DESC,date_created DESC", 
      :conditions => ["person_id = ? AND concept_id = ?",patient.id,
      ConceptName.find_by_name("Patient enrolled in IMB HIV program").concept_id]).value_coded).concept_names.map{|c|c.name}[0].upcase rescue nil

    return unless enrolled_in_hiv_program == 'YES'

    #return if not reason_for_art.upcase == 'UNKNOWN' and not reason_for_art.blank?

    art_initial = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
                             patient.id,EncounterType.find_by_name('ART_INITIAL').id],
                             :order =>'encounter_datetime DESC,date_created DESC',:limit => 1)

    if art_initial.blank? and user_selected_activities.match(/Manage HIV first visits/i)
      task.encounter_type = 'ART_INITIAL'
      task.url = "/encounters/new/art_initial?show&patient_id=#{patient.id}"
      return task
    elsif art_initial.blank? and not user_selected_activities.match(/Manage HIV first visits/i)
      task.encounter_type = 'ART_INITIAL'
      task.url = "/patients/show/#{patient.id}"
      return task
    end

    hiv_staging = Encounter.find(:first,:order => "encounter_datetime DESC",
                                 :conditions =>["patient_id = ? AND encounter_type = ?",
                                 patient.id,EncounterType.find_by_name('HIV STAGING').id])

    if hiv_staging.blank? and user_selected_activities.match(/Manage HIV staging visits/i)
      extended_staging_questions = get_global_property_value('use.extended.staging.questions')
      extended_staging_questions = extended_staging_questions.property_value == 'yes' rescue false
      task.encounter_type = 'HIV STAGING'
      task.url = "/encounters/new/hiv_staging?show&patient_id=#{patient.id}" if not extended_staging_questions
      task.url = "/encounters/new/llh_hiv_staging?show&patient_id=#{patient.id}" if extended_staging_questions
      return task
    elsif hiv_staging.blank? and not user_selected_activities.match(/Manage HIV staging visits/i)
      task.encounter_type = 'HIV STAGING'
      task.url = "/patients/show/#{patient.id}"
      return task
    end

    pre_art_visit = Encounter.find(:first,:order => "encounter_datetime DESC",
                                    :conditions =>["patient_id = ? AND encounter_type = ?",
                                    patient.id,EncounterType.find_by_name('PART_FOLLOWUP').id])

    if pre_art_visit.blank? and user_selected_activities.match(/Manage pre ART visits/i)
      task.encounter_type = 'Pre ART visit'
      task.url = "/encounters/new/pre_art_visit?show&patient_id=#{patient.id}"
      return task
    elsif pre_art_visit.blank? and not user_selected_activities.match(/Manage pre ART visits/i)
      task.encounter_type = 'Pre ART visit'
      task.url = "/patients/show/#{patient.id}"
      return task
    end if reason_for_art.upcase ==  'UNKNOWN' or reason_for_art.blank?


    art_visit = Encounter.find(:first,:order => "encounter_datetime DESC",
                               :conditions =>["patient_id = ? AND encounter_type = ?",
                               patient.id,EncounterType.find_by_name('ART VISIT').id])

    if art_visit.blank? and user_selected_activities.match(/Manage ART visits/i)
      task.encounter_type = 'ART VISIT'
      task.url = "/encounters/new/art_visit?show&patient_id=#{patient.id}"
      return task
    elsif art_visit.blank? and not user_selected_activities.match(/Manage ART visits/i)
      task.encounter_type = 'ART VISIT'
      task.url = "/patients/show/#{patient.id}"
      return task
    end

    treatment_encounter = Encounter.find(:first,:order => "encounter_datetime DESC",
                              :joins =>"INNER JOIN obs USING(encounter_id)",
                              :conditions =>["patient_id = ? AND encounter_type = ? AND concept_id = ?",
                              patient.id,EncounterType.find_by_name('TREATMENT').id,ConceptName.find_by_name('ARV regimen type').concept_id])

    prescribe_drugs = art_visit.observations.map{|obs| obs.to_s.squish.strip.upcase }.include? 'Prescribe arvs this visit: Yes'.upcase rescue false

    if not prescribe_drugs 
      prescribe_drugs = pre_art_visit.observations.map{|obs| obs.to_s.squish.strip.upcase }.include? 'Prescribe drugs: Yes'.upcase rescue false
    end

    if treatment_encounter.blank? and user_selected_activities.match(/Manage prescriptions/i)
      task.encounter_type = 'TREATMENT'
      task.url = "/regimens/new?patient_id=#{patient.id}"
      return task
    elsif treatment_encounter.blank? and not user_selected_activities.match(/Manage prescriptions/i)
      task.encounter_type = 'TREATMENT'
      task.url = "/patients/show/#{patient.id}"
      return task
    end if prescribe_drugs
  end

  def self.get_national_id(patient, force = true)
    id = patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => patient).identifier
    id
  end

  def self.get_remote_national_id(patient)
    id = patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless id.blank?
    PatientIdentifierType.find_by_name("National id").next_identifier(:patient => patient).identifier
  end

  def self.get_national_id_with_dashes(patient, force = true)
    id = self.get_national_id(patient, force)
    id[0..4] + "-" + id[5..8] + "-" + id[9..-1] rescue id
  end

end
