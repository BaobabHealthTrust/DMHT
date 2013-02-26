class PeopleController < GenericPeopleController
	def confirm
		session_date = session[:datetime] || Date.today
		if request.post?
			redirect_to search_complete_url(params[:found_person_id], params[:relation]) and return
		end
		@found_person_id = params[:found_person_id] 
		@relation = params[:relation]
		@person = Person.find(@found_person_id) rescue nil
		@task = main_next_task(Location.current_location, @person.patient, session_date.to_date)
		@arv_number = PatientService.get_patient_identifier(@person, 'ARV Number')
		@patient_bean = PatientService.get_patient(@person)
		render :layout => 'menu'
	end

  def create
    success = false
    Person.session_datetime = session[:datetime].to_date rescue Date.today
    identifier = params[:identifier] rescue nil
    if identifier.blank?
      identifier = params[:person][:patient][:identifiers]['National id']
    end rescue nil

    if create_from_dde_server
      unless identifier.blank?
        params[:person].merge!({"identifiers" => {"National id" => identifier}})
        success = true
        person = PatientService.create_from_form(params[:person])
        if identifier.length != 6
           patient = DDEService::Patient.new(person.patient)
           national_id_replaced = patient.check_old_national_id(identifier)
        end
      else
        person = PatientService.create_patient_from_dde(params)
        success = true
      end

    #for now BART2 will use BART1 for patient/person creation until we upgrade BART1 to 2
    #if GlobalProperty.find_by_property('create.from.remote') and property_value == 'yes'
    #then we create person from remote machine
    elsif create_from_remote
      person_from_remote = PatientService.create_remote_person(params)
      params[:person].merge!({"identifiers" => {"National id" => identifier}}) unless identifier.blank?
      person = PatientService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        #person.patient.remote_national_id
        PatientService.get_remote_national_id(person.patient)
      end
    else
      success = true
      params[:person].merge!({"identifiers" => {"National id" => identifier}}) unless identifier.blank?
      person = PatientService.create_from_form(params[:person])
    end

    if params[:person][:patient] && success
      PatientService.patient_national_id_label(person.patient)
      unless (params[:relation].blank?)
        redirect_to search_complete_url(person.id, params[:relation]) and return
      else

       tb_session = false
       if current_user.activities.include?('Manage Lab Orders') or current_user.activities.include?('Manage Lab Results') or
        current_user.activities.include?('Manage Sputum Submissions') or current_user.activities.include?('Manage TB Clinic Visits') or
         current_user.activities.include?('Manage TB Reception Visits') or current_user.activities.include?('Manage TB Registration Visits') or
          current_user.activities.include?('Manage HIV Status Visits')
         tb_session = true
       end

        #raise use_filing_number.to_yaml
        if use_filing_number and not tb_session
          PatientService.set_patient_filing_number(person.patient)
          archived_patient = PatientService.patient_to_be_archived(person.patient)
          message = PatientService.patient_printing_message(person.patient,archived_patient,creating_new_patient = true)
          unless message.blank?
            print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}" , next_task(person.patient),message,true,person.id)
          else
            print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}", next_task(person.patient))
          end
        else
          print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
        end
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end

  def search
    found_person = nil
    if params[:identifier]
      local_results = PatientService.search_by_identifier(params[:identifier])
      if local_results.length > 1
        redirect_to :action => 'duplicates' ,:search_params => params
        return
      elsif local_results.length == 1
        if create_from_dde_server
          dde_server = GlobalProperty.find_by_property("dde_server_ip").property_value rescue ""
          dde_server_username = GlobalProperty.find_by_property("dde_server_username").property_value rescue ""
          dde_server_password = GlobalProperty.find_by_property("dde_server_password").property_value rescue ""
          uri = "http://#{dde_server_username}:#{dde_server_password}@#{dde_server}/people/find.json"
          uri += "?value=#{params[:identifier]}"
          output = RestClient.get(uri)
          p = JSON.parse(output)
          if p.count > 1
            redirect_to :action => 'duplicates' ,:search_params => params
            return
          end
        end
        found_person = local_results.first
      else
        # TODO - figure out how to write a test for this
        # This is sloppy - creating something as the result of a GET
        if create_from_remote
          found_person_name = PersonName.find(found_person.person_id)
					found_person_data = PatientService.find_remote_person_by_identifier(params[:identifier]) rescue nil
          birth_day = found_person_data['person']['birth_year'].to_s + "-" + found_person_data['person']['birth_month'].to_s + "-" + found_person_data['person']['birth_day'].to_s
          unless found_person_data.blank?
            if found_person_data['person']['names']['given_name'].upcase == found_person_name.attributes['given_name'].upcase and
              found_person_data['person']['names']['family_name'].upcase == found_person_name.attributes['family_name'].upcase and
              birth_day.to_date == found_person.attributes['birthdate']
              if found_person_data['person']['patient']['identifiers']['National id'].length == 6 and  params[:identifier].length > 6
                patient = DDEService::Patient.new(found_person.patient)
                current_national_id = patient.get_full_identifier("National id")
                patient.set_identifier("Old Identification Number", current_national_id.identifier)
                patient.set_identifier("National id", found_person_data['person']['patient']['identifiers']['National id'])
                current_national_id.void("National ID version change")
                print_and_redirect("/patients/national_id_label?patient_id=#{found_person.id}", next_task(found_person.patient)) and return
              end
            end
          end
				end
      end
      if found_person
        if params[:identifier].length != 6 and create_from_dde_server
          patient = DDEService::Patient.new(found_person.patient)
          national_id_replaced = patient.check_old_national_id(params[:identifier])
          if national_id_replaced.to_s != "true" and national_id_replaced.to_s !="false"
            redirect_to :action => 'remote_duplicates' ,:search_params => params
            return
          end
        end

        if params[:relation]
          redirect_to search_complete_url(found_person.id, params[:relation]) and return
        elsif national_id_replaced.to_s == "true"
          print_and_redirect("/patients/national_id_label?patient_id=#{found_person.id}", next_task(found_person.patient)) and return
          redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
        else
          redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
        end
      end
    end

    @relation = params[:relation]
    @people = PatientService.person_search(params)
    @search_results = {}
    @patients = []

    (PatientService.search_from_remote(params) || []).each do |data|
      national_id = data["person"]["data"]["patient"]["identifiers"]["National id"] rescue nil
      national_id = data["person"]["value"] if national_id.blank? rescue nil
      national_id = data["npid"]["value"] if national_id.blank? rescue nil
      national_id = data["person"]["data"]["patient"]["identifiers"]["old_identification_number"] if national_id.blank? rescue nil

      next if national_id.blank?
      results = PersonSearch.new(national_id)
      results.national_id = national_id
      results.current_residence =data["person"]["data"]["addresses"]["city_village"]
      results.person_id = 0
      results.home_district = data["person"]["data"]["addresses"]["state_province"]
      results.traditional_authority =  data["person"]["data"]["addresses"]["county_district"]
      results.name = data["person"]["data"]["names"]["given_name"] + " " + data["person"]["data"]["names"]["family_name"]
      gender = data["person"]["data"]["gender"]
      results.occupation = data["person"]["data"]["occupation"]
      results.sex = (gender == 'M' ? 'Male' : 'Female')
      results.birthdate_estimated = (data["person"]["data"]["birthdate_estimated"]).to_i
      results.birth_date = birthdate_formatted((data["person"]["data"]["birthdate"]).to_date , results.birthdate_estimated)
      results.birthdate = (data["person"]["data"]["birthdate"]).to_date
      results.age = cul_age(results.birthdate.to_date , results.birthdate_estimated)
      @search_results[results.national_id] = results
    end if create_from_dde_server

    (@people || []).each do | person |
      patient = PatientService.get_patient(person) rescue nil
      next if patient.blank?
      results = PersonSearch.new(patient.national_id || patient.patient_id)
      results.national_id = patient.national_id
      results.birth_date = patient.birth_date
      results.current_residence = patient.current_residence
      results.guardian = patient.guardian
      results.person_id = patient.person_id
      results.home_district = patient.home_district
      results.traditional_authority = patient.traditional_authority
      results.mothers_surname = patient.mothers_surname
      results.dead = patient.dead
      results.arv_number = patient.arv_number
      results.eid_number = patient.eid_number
      results.pre_art_number = patient.pre_art_number
      results.name = patient.name
      results.sex = patient.sex
      results.age = patient.age
      @search_results.delete_if{|x,y| x == results.national_id }
      @patients << results
    end

		(@search_results || {}).each do | npid , data |
			@patients << data
		end
	end

end
 
