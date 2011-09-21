class PatientsController < ApplicationController
  before_filter :find_patient, :except => [:void]
  
  def show
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
    @encounters = @patient.encounters.find_by_date(session_date)
    @prescriptions = @patient.orders.unfinished.prescriptions.all
    @programs = @patient.patient_programs.all
    @alerts = @patient.alerts(session_date)
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|    
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end

    @patient_treatements = treatment_orders(@patient.id)
    # render :template => 'dashboards/overview', :layout => 'dashboard'

    @date = (session[:datetime].to_date rescue Date.today).strftime("%Y-%m-%d")

     @location = Location.find(session[:location_id]).name rescue ""
     if @location.downcase == "outpatient" || params[:source]== 'opd'
        render :template => 'dashboards/opdtreatment_dashboard', :layout => false
     else
        render :template => 'patients/index', :layout => false
     end
  end

  def opdcard
    @patient = Patient.find(params[:id])
    render :layout => 'menu' 
  end

  def opdshow
    session_date = session[:datetime].to_date rescue Date.today
    encounter_types = EncounterType.find(:all,:conditions =>["name IN (?)",
        ['REGISTRATION','OUTPATIENT DIAGNOSIS','REFER PATIENT OUT?','OUTPATIENT RECEPTION','DISPENSING']]).map{|e|e.id}
    @encounters = Encounter.find(:all,:select => "encounter_id , name encounter_type_name, count(*) c",
      :joins => "INNER JOIN encounter_type ON encounter_type_id = encounter_type",
      :conditions =>["patient_id = ? AND encounter_type IN (?) AND DATE(encounter_datetime) = ?",
        params[:id],encounter_types,session_date],
      :group => 'encounter_type').collect do |rec| 
        if User.current_user.user_roles.map{|r|r.role}.join(',').match(/Registration|Clerk/i)
          next unless rec.observations[0].to_s.match(/Workstation location:   Outpatient/i)
        end
        [ rec.encounter_id , rec.encounter_type_name , rec.c ] 
      end
    
    render :template => 'dashboards/opdoverview_tab', :layout => false
  end

  def opdtreatment
    render :template => 'dashboards/opdtreatment_dashboard', :layout => false
  end

  def opdtreatment_tab
    @activities = [
      ["Visit card","/patients/opdcard/#{params[:id]}"],
      ["National ID (Print)","/patients/dashboard_print_national_id?id=#{params[:id]}&redirect=patients/opdtreatment"],
      ["Referrals", "/encounters/referral/#{params[:id]}"],
      ["Give drugs", "/encounters/opddrug_dispensing/#{params[:id]}"],
      ["Vitals", "/report/data_cleaning"],
      ["Outpatient diagnosis","/encounters/new?id=show&patient_id=#{params[:id]}&encounter_type=outpatient_diagnosis"]
    ]
    render :template => 'dashboards/opdtreatment_tab', :layout => false
  end

  def treatment
    #@prescriptions = @patient.orders.current.prescriptions.all
    type = EncounterType.find_by_name('TREATMENT')
    session_date = session[:datetime].to_date rescue Date.today
    @prescriptions = Order.find(:all,
      :joins => "INNER JOIN encounter e USING (encounter_id)",
      :conditions => ["encounter_type = ? AND e.patient_id = ? AND DATE(encounter_datetime) = ?",
        type.id,@patient.id,session_date])

    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @prescriptions = restriction.filter_orders(@prescriptions)
    end

    # render :template => 'dashboards/treatment', :layout => 'dashboard'
    render :template => 'dashboards/dispension_tab', :layout => false
  end

  def history_treatment
    #@prescriptions = @patient.orders.current.prescriptions.all
    type = EncounterType.find_by_name('TREATMENT')
    session_date = session[:datetime].to_date rescue Date.today
    @prescriptions = Order.find(:all,
      :joins => "INNER JOIN encounter e USING (encounter_id)",
      :conditions => ["encounter_type = ? AND e.patient_id = ?",type.id,@patient.id])

    @historical = @patient.orders.historical.prescriptions.all
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @historical = restriction.filter_orders(@historical)
    end
    # render :template => 'dashboards/treatment', :layout => 'dashboard'
    render :template => 'dashboards/treatment_tab', :layout => false
  end

  def guardians
    if @patient.blank?
    	redirect_to :'clinic'
    	return
    else
		  @relationships = @patient.relationships rescue []
		  @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
		  @restricted.each do |restriction|
		    @relationships = restriction.filter_relationships(@relationships)
		  end
    	render :template => 'dashboards/relationships_tab', :layout => false
  	end
  end

  def relationships
    if @patient.blank?
    	redirect_to :'clinic'
    	return
    else
      next_form = next_task(@patient)
      redirect_to next_form and return if next_form.match(/Reception/i)
		  @relationships = @patient.relationships rescue []
		  @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
		  @restricted.each do |restriction|
		    @relationships = restriction.filter_relationships(@relationships)
		  end
    	render :template => 'dashboards/relationships', :layout => 'dashboard' 
  	end
  end

  def problems
    render :template => 'dashboards/problems', :layout => 'dashboard' 
  end

  def personal
    @links = []
    patient = Patient.find(params[:id])

    if GlobalProperty.use_user_selected_activities
      @links << ["Change User Activities","/user/activities/#{User.current_user.id}?patient_id=#{patient.id}"]
    end

    @links << ["Edit Demographics (Print)","/patients/demographics?patient_id=#{patient.id}"]
    @links << ["National ID (Print)","/patients/dashboard_print_national_id/#{patient.id}"]
    @links << ["Visit Summary (Print)","/patients/dashboard_print_visit/#{patient.id}"]

    render :template => 'dashboards/personal_tab', :layout => false
  end

  def history
    render :template => 'dashboards/history', :layout => 'dashboard' 
  end

  def programs
    @programs = @patient.patient_programs.all
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @programs = restriction.filter_programs(@programs)
    end
    flash.now[:error] = params[:error] unless params[:error].blank?

    unless flash[:error].nil?
      redirect_to "/patients/programs_dashboard/#{@patient.id}?error=#{params[:error]}" and return
    else
      render :template => 'dashboards/programs_tab', :layout => false
    end
  end

  def graph
    @currentWeight = params[:currentWeight]
    render :template => "graphs/#{params[:data]}", :layout => false 
  end

  def void 
    @encounter = Encounter.find(params[:encounter_id])
    @encounter.void
    show and return
  end
  
  def print_registration
    print_and_redirect("/patients/national_id_label/?patient_id=#{@patient.id}", next_task(@patient))  
  end
  
  def dashboard_print_national_id
    unless params[:redirect].blank?
      redirect = "/#{params[:redirect]}/#{params[:id]}"
    else
      redirect = "/patients/show/#{params[:id]}"
    end
    print_and_redirect("/patients/national_id_label?patient_id=#{params[:id]}", redirect)  
  end
  
  def dashboard_print_visit
    print_and_redirect("/patients/visit_label/?patient_id=#{params[:id]}", "/patients/show/#{params[:id]}")
  end
  
  def print_visit
    print_and_redirect("/patients/visit_label/?patient_id=#{@patient.id}", next_task(@patient))  
  end
  
  def print_mastercard_record
    print_and_redirect("/patients/mastercard_record_label/?patient_id=#{@patient.id}&date=#{params[:date]}", "/patients/visit?date=#{params[:date]}&patient_id=#{params[:patient_id]}")  
  end
  
  def print_demographics
    print_and_redirect("/patients/patient_demographics_label/#{@patient.id}", "/patients/show/#{params[:id]}")
  end
 
  def print_filing_number
    print_and_redirect("/patients/filing_number_label/#{params[:id]}", "/patients/show/#{params[:id]}")  
  end
   
  def patient_demographics_label
    print_string = Patient.find(params[:id]).demographics_label 
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:id]}#{rand(10000)}.lbl", :disposition => "inline")
  end
  
  def national_id_label
    print_string = @patient.national_id_label rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a national id label for that patient")
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def print_lab_orders
    print_and_redirect("/patients/lab_orders_label/?patient_id=#{@patient.id}", next_task(@patient))
  end

  def lab_orders_label
    patient = Patient.find(@patient.id)
    label_commands = patient.lab_orders_label
    send_data(label_commands.to_s,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def filing_number_label
    patient = Patient.find(params[:id])
    label_commands = patient.filing_number_label
    send_data(label_commands,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end
 
  def filing_number_and_national_id
    patient = Patient.find(params[:patient_id])
    label_commands = patient.national_id_label + patient.filing_number_label

    send_data(label_commands,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end
 
  def visit_label
    print_string = @patient.visit_label rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a visit label for that patient")
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def mastercard_record_label
    print_string = @patient.visit_label(params[:date].to_date) 
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def mastercard_menu
    render :layout => "menu"
    @patient_id = params[:patient_id]
  end

  def mastercard
    @type = params[:type]
    
    #the parameter are used to re-construct the url when the mastercard is called from a Data cleaning report
    @quarter = params[:quarter]
    @arv_start_number = params[:arv_start_number]
    @arv_end_number = params[:arv_end_number]
    @show_mastercard_counter = false
    
    if params[:patient_id].blank?

      @patient_id = session[:mastercard_ids][session[:mastercard_counter]]
       
    elsif session[:mastercard_ids].length.to_i != 0
      @patient_id = params[:patient_id]
    else
      @patient_id = params[:patient_id]
    end

    unless params.include?("source")
      @source = params[:source] rescue nil
    else
      @source = nil
    end

    render :layout => false
    
  end

  def mastercard_old
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    void_encounter if (params[:void] && params[:void] == 'true')
    @person = @patient.person
    @encounters = @patient.encounters.find_all_by_encounter_type(EncounterType.find_by_name('DIABETES TEST').id)
    @observations = @encounters.map(&:observations).flatten
    @obs_datetimes = @observations.map { |each|each.obs_datetime.strftime("%d-%b-%Y")}.uniq
    @address = @person.addresses.last

    diabetes_test_id = EncounterType.find_by_name('Diabetes Test').id

    #TODO: move this code to Patient model
    # Creatinine
    creatinine_id = Concept.find_by_name('CREATININE').id
    @creatinine_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, creatinine_id],
      :order => 'obs_datetime DESC')

    # Urine Protein
    urine_protein_id = Concept.find_by_name('URINE PROTEIN').id
    @urine_protein_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, urine_protein_id],
      :order => 'obs_datetime DESC')

    # Foot Check
    @foot_check_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['RIGHT FOOT/LEG',
            'LEFT FOOT/LEG', 'LEFT HAND/ARM', 'RIGHT HAND/ARM']).map(&:concept_id)],
      :order => 'obs_datetime DESC').uniq

    if @foot_check_encounters.nil?
      @foot_check_encounters = []
    end

    @foot_check_obs = {}

    @foot_check_encounters.each{|e|
      value = @patient.person.observations.find(:all,
        :joins => :encounter,
        :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
          diabetes_test_id, e.encounter_id],
        :order => 'obs_datetime DESC')

      unless value.nil?
        @foot_check_obs[e.encounter_id] = value
      end
    }

    # Visual Acuity RIGHT EYE FUNDOSCOPY
    @visual_acuity_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['LEFT EYE VISUAL ACUITY',
            'RIGHT EYE VISUAL ACUITY']).map(&:concept_id)],
      :order => 'obs_datetime DESC').uniq

    if @visual_acuity_encounters.nil?
      @visual_acuity_encounters = []
    end

    @visual_acuity_obs = {}

    @visual_acuity_encounters.each{|e|
      @visual_acuity_obs[e.encounter_id] = @patient.person.observations.find(:all,
        :joins => :encounter,
        :conditions => ['encounter_type = ? AND encounter.encounter_id = ?',
          diabetes_test_id, e.encounter_id],
        :order => 'obs_datetime DESC')
    }


    # Fundoscopy
    @fundoscopy_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['LEFT EYE FUNDOSCOPY',
            'RIGHT EYE FUNDOSCOPY']).map(&:concept_id)],
      :order => 'obs_datetime DESC').uniq

    if @fundoscopy_encounters.nil?
      @fundoscopy_encounters = []
    end

    @fundoscopy_obs = {}

    @fundoscopy_encounters.each{|e|
      @fundoscopy_obs[e.encounter_id] = @patient.person.observations.find(:all,
        :joins => :encounter,
        :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
          diabetes_test_id, e.encounter_id],
        :order => 'obs_datetime DESC')
    }

    # Urea
    urea_id = Concept.find_by_name('UREA').id
    @urea_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, urea_id],
      :order => 'obs_datetime DESC')


    # Macrovascular
    macrovascular_id = Concept.find_by_name('MACROVASCULAR').id
    @macrovascular_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, macrovascular_id],
      :order => 'obs_datetime DESC')

    unless params.include?("source")
      @source = params[:source] rescue nil
    else
      @source = nil
    end

    render :layout => 'menu'
  end

  def mastercard_printable
    #the parameter are used to re-construct the url when the mastercard is called from a Data cleaning report
    @quarter = params[:quarter]
    @arv_start_number = params[:arv_start_number]
    @arv_end_number = params[:arv_end_number]
    @show_mastercard_counter = false

    if params[:patient_id].blank?

      @show_mastercard_counter = true

      if !params[:current].blank?
        session[:mastercard_counter] = params[:current].to_i - 1
      end
      @prev_button_class = "yellow"
      @next_button_class = "yellow"
      if params[:current].to_i ==  1
        @prev_button_class = "gray"
      elsif params[:current].to_i ==  session[:mastercard_ids].length
        @next_button_class = "gray"
      else

      end
      @patient_id = session[:mastercard_ids][session[:mastercard_counter]]
      @data_demo = Mastercard.demographics(Patient.find(@patient_id))
      @visits = Mastercard.visits(Patient.find(@patient_id))

      # elsif session[:mastercard_ids].length.to_i != 0
      #  @patient_id = params[:patient_id]
      #  @data_demo = Mastercard.demographics(Patient.find(@patient_id))
      #  @visits = Mastercard.visits(Patient.find(@patient_id))
    else
      @patient_id = params[:patient_id]
      @data_demo = Mastercard.demographics(Patient.find(@patient_id))
      @visits = Mastercard.visits(Patient.find(@patient_id))
    end
    render :layout => false
  end

  def visit
    @patient_id = params[:patient_id] 
    @date = params[:date].to_date
    @patient = Patient.find(@patient_id)
    @visits = Mastercard.visits(@patient,@date)
    render :layout => "menu"
  end

  def next_available_arv_number
    next_available_arv_number = PatientIdentifier.next_available_arv_number
    render :text => next_available_arv_number.gsub(PatientIdentifier.site_prefix,'').strip rescue nil
  end
  
  def assigned_arv_number
    assigned_arv_number = PatientIdentifier.find(:all,:conditions => ["voided = 0 AND identifier_type = ?",
        PatientIdentifierType.find_by_name("ARV Number").id]).collect{|i|
      i.identifier.gsub(PatientIdentifier.site_prefix,'').strip.to_i
    } rescue nil
    render :text => assigned_arv_number.sort.to_json rescue nil 
  end

  def mastercard_modify
    if request.method == :get
      @patient_id = params[:id]
      @patient = Patient.find(params[:id])
      @edit_page = Patient.edit_mastercard_attribute(params[:field].to_s)

      if @edit_page == "guardian"
        @guardian = {}
        @patient.person.relationships.map{|r| @guardian[Person.find(r.person_b).name] = Person.find(r.person_b).id.to_s;'' }
        if  @guardian == {}
          redirect_to :controller => "relationships" , :action => "search",:patient_id => @patient_id
        end
      end
    else
      @patient_id = params[:patient_id]
      Patient.save_mastercard_attribute(params)
      if params[:source].to_s == "opd"
        redirect_to "/patients/opdcard/#{@patient_id}" and return

      else
        redirect_to :action => "mastercard",:patient_id => @patient_id and return
      end
    end
  end

  def summary
    @encounter_type = params[:skipped]
    @patient_id = params[:patient_id]
    render :layout => "menu"
  end

  def set_filing_number
    patient = Patient.find(params[:id])
    patient.set_filing_number

    archived_patient = patient.patient_to_be_archived
    message = Patient.printing_message(patient,archived_patient,true)
    unless message.blank?
      print_and_redirect("/patients/filing_number_label/#{patient.id}" , "/patients/show/#{patient.id}",message,true,patient.id)
    else
      print_and_redirect("/patients/filing_number_label/#{patient.id}", "/patients/show/#{patient.id}")
    end
  end

  def set_new_filing_number
    patient = Patient.find(params[:id])
    patient.set_new_filing_number

    archived_patient = patient.patient_to_be_archived
    message = Patient.printing_message(patient,archived_patient)
    unless message.blank?
      print_and_redirect("/patients/filing_number_label/#{patient.id}" , "/people/confirm?found_person_id=#{patient.id}",message,true,patient.id)
    else
      print_and_redirect("/patients/filing_number_label/#{patient.id}", "/people/confirm?found_person_id=#{patient.id}")
    end
  end

  def export_to_csv
    ( Patient.find(:all,:limit => 10) || [] ).each do | patient |
      csv_string = FasterCSV.generate do |csv|
        # header row
        csv << ["ARV number", "National ID"]
        csv << [patient.arv_number, patient.national_id]
        csv << ["Name", "Age","Sex","Init Wt(Kg)","Init Ht(cm)","BMI","Transfer-in"]
        transfer_in = patient.person.observations.recent(1).question("HAS TRANSFER LETTER").all rescue nil
        transfer_in.blank? == true ? transfer_in = 'NO' : transfer_in = 'YES'
        csv << [patient.name,patient.person.age, patient.person.sex,patient.initial_weight,patient.initial_height,patient.initial_bmi,transfer_in]
        csv << ["Location", "Land-mark","Occupation","Init Wt(Kg)","Init Ht(cm)","BMI","Transfer-in"]

=begin
        # data rows
        @users.each do |user|
          csv << [user.id, user.username, user.salt]
        end
=end
      end
      # send it to the browsah
      send_data csv_string.gsub(' ','_'),
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment:wq
              ; filename=patient-#{patient.id}.csv"
    end
  end

  def print_mastercard
    if @patient
      t1 = Thread.new{
        Kernel.system "htmldoc --webpage --landscape --linkstyle plain --left 1cm --right 1cm --top 1cm --bottom 1cm -f /tmp/output-" +
          session[:user_id].to_s + ".pdf http://" + request.env["HTTP_HOST"] + "\"/patients/mastercard_printable?patient_id=" +
          @patient.id.to_s + "\"\n"
      }

      t2 = Thread.new{
        sleep(5)
        Kernel.system "lpr /tmp/output-" + session[:user_id].to_s + ".pdf\n"
      }

      t3 = Thread.new{
        sleep(10)
        Kernel.system "rm /tmp/output-" + session[:user_id].to_s + ".pdf\n"
      }

    end

    redirect_to "/patients/mastercard?patient_id=#{@patient.id}" and return
  end
  
  def demographics
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @person = @patient.person
    @address = @person.addresses.last
    render :layout => 'menu'
  end
   
  def index
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
    @encounters = @patient.encounters.find_by_date(session_date)
    @prescriptions = @patient.orders.unfinished.prescriptions.all
    @programs = @patient.patient_programs.all
    @alerts = @patient.alerts(session_date)
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end

    @date = (session[:datetime].to_date rescue Date.today).strftime("%Y-%m-%d")

    render :template => 'patients/index', :layout => false
  end

  def overview
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
    @encounters = @patient.encounters.find_by_date(session_date)
    @prescriptions = @patient.orders.unfinished.prescriptions.all
    @programs = @patient.patient_programs.all
    @alerts = @patient.alerts(session_date)
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end

    render :template => 'dashboards/overview_tab', :layout => false
  end

  def visit_history
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
    @encounters = @patient.encounters.find_by_date(session_date)
    @prescriptions = @patient.orders.unfinished.prescriptions.all
    @programs = @patient.patient_programs.all
    @alerts = @patient.alerts(session_date)
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end

    render :template => 'dashboards/visit_history_tab', :layout => false
  end

  def past_visits_summary
    @previous_visits  = Encounter.get_previous_encounters(params[:patient_id])

    @encounter_dates = @previous_visits.map{|encounter| encounter.encounter_datetime.to_date}.uniq.reverse.first(6) rescue []

    @past_encounter_dates = []
      @encounter_dates.each do |encounter|
        @past_encounter_dates << encounter if encounter < (Date.today).to_date || encounter < (session[:datetime].to_date rescue Date.today.to_date)
      end

    render :template => 'dashboards/past_visits_summary_tab', :layout => false
  end

  def treatment_dashboard
    @amount_needed = 0
    @amounts_required = 0

    type = EncounterType.find_by_name('TREATMENT')
    session_date = session[:datetime].to_date rescue Date.today
    Order.find(:all,
      :joins => "INNER JOIN encounter e USING (encounter_id)",
      :conditions => ["encounter_type = ? AND e.patient_id = ? AND DATE(encounter_datetime) = ?",
        type.id,@patient.id,session_date]).each{|order|
      
      @amount_needed = @amount_needed + (order.drug_order.amount_needed.to_i rescue 0)

      @amounts_required = @amounts_required + (order.drug_order.total_required rescue 0)

    }

    @dispensed_order_id = params[:dispensed_order_id]
    render :template => 'dashboards/treatment_dashboard', :layout => false
  end

  def guardians_dashboard
    render :template => 'dashboards/relationships_dashboard', :layout => false
  end

  def programs_dashboard
    render :template => 'dashboards/programs_dashboard', :layout => false
  end

  def general_mastercard
    @type = nil
    
    case params[:type]
    when "1"
      @type = "yellow"
    when "2"
      @type = "green"
    when "3"
      @type = "pink"
    when "4"
      @type = "blue"
    end

    @mastercard = Mastercard.demographics(@patient)
    @visits = Mastercard.visits(@patient)   # (@patient, (session[:datetime].to_date rescue Date.today))

    render :layout => false
  end

  def patient_details
    render :layout => false
  end

  def status_details
    render :layout => false
  end

  def mastercard_details
    render :layout => false
  end

  def mastercard_header
    render :layout => false
  end

  def number_of_booked_patients
    date = params[:date].to_date
    encounter_type = EncounterType.find_by_name('APPOINTMENT')
    concept_id = ConceptName.find_by_name('APPOINTMENT DATE').concept_id
    count = Observation.count(:all,
            :joins => "INNER JOIN encounter e USING(encounter_id)",:group => "value_datetime",
            :conditions =>["concept_id = ? AND encounter_type = ? AND value_datetime >= ? AND value_datetime <= ?",
            concept_id,encounter_type.id,date.strftime('%Y-%m-%d 00:00:00'),date.strftime('%Y-%m-%d 23:59:59')])
    count = count.values unless count.blank?
    count = '0' if count.blank?
    render :text => count
  end

  def recent_lab_orders_print
    patient = Patient.find(params[:id])
    lab_orders_label = params[:lab_tests].split(":")

    label_commands = patient.recent_lab_orders_label(lab_orders_label)
    send_data(label_commands.to_s,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def print_recent_lab_orders_label
    #patient = Patient.find(params[:id])
    lab_orders_label = params[:lab_tests].join(":")

    #raise lab_orders_label.to_s
    #label_commands = patient.recent_lab_orders_label(lab_orders_label)
    #send_data(label_commands.to_s,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")

    print_and_redirect("/patients/recent_lab_orders_print/#{params[:id]}?lab_tests=#{lab_orders_label}" , "/patients/show/#{params[:id]}")
  end

  def recent_lab_orders
    patient = Patient.find(params[:patient_id])
    @lab_order_labels = patient.get_recent_lab_orders_label
    @patient_id = params[:patient_id]
  end

  def generate_booking
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil

    @type = EncounterType.find_by_name("APPOINTMENT").id rescue nil
    if(@type)
      @enc = Encounter.find(:all, :conditions =>
          ["voided = 0 AND encounter_type = ?", @type])

      @counts = {}

      @enc.each{|e|
        obs = e.observations
        if !obs.blank?
          obs_date = obs.first.value_datetime
          yr = obs_date.to_date.strftime("%Y")
          mt = obs_date.to_date.strftime("%m").to_i-1
          dy = obs_date.to_date.strftime("%d").to_i

          if(!@counts[(yr.to_s + "-" + mt.to_s + "-" + dy.to_s)])
            @counts[(yr.to_s + "-" + mt.to_s + "-" + dy.to_s)] = {}
            @counts[(yr.to_s + "-" + mt.to_s + "-" + dy.to_s)]["count"] = 0
          end

          @counts[(yr.to_s + "-" + mt.to_s + "-" + dy.to_s)][e.patient_id] = true
          @counts[(yr.to_s + "-" + mt.to_s + "-" + dy.to_s)]["count"] += 1
        end
      }
      #raise @counts['2011-08-06'].to_yaml
    end
  end

  def mastercard
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    void_encounter if (params[:void] && params[:void] == 'true')
    @person = @patient.person
    @encounters = @patient.encounters.find_all_by_encounter_type(EncounterType.find_by_name('DIABETES TEST').id)
    @observations = @encounters.map(&:observations).flatten
    @obs_datetimes = @observations.map { |each|each.obs_datetime.strftime("%d-%b-%Y")}.uniq
    @address = @person.addresses.last

    diabetes_test_id = EncounterType.find_by_name('Diabetes Test').id

    #TODO: move this code to Patient model
    # Creatinine
    creatinine_id = Concept.find_by_name('CREATININE').id
    @creatinine_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, creatinine_id],
      :order => 'obs_datetime DESC')

    # Urine Protein
    urine_protein_id = Concept.find_by_name('URINE PROTEIN').id
    @urine_protein_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, urine_protein_id],
      :order => 'obs_datetime DESC')

    # Foot Check
    @foot_check_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['RIGHT FOOT/LEG',
            'LEFT FOOT/LEG', 'LEFT HAND/ARM', 'RIGHT HAND/ARM']).map(&:concept_id)],
      :order => 'obs_datetime DESC').uniq

    if @foot_check_encounters.nil?
      @foot_check_encounters = []
    end

    @foot_check_obs = {}

    @foot_check_encounters.each{|e|
      value = @patient.person.observations.find(:all,
        :joins => :encounter,
        :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
          diabetes_test_id, e.encounter_id],
        :order => 'obs_datetime DESC')

      unless value.nil?
        @foot_check_obs[e.encounter_id] = value
      end
    }

    # Visual Acuity RIGHT EYE FUNDOSCOPY
    @visual_acuity_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['LEFT EYE VISUAL ACUITY',
            'RIGHT EYE VISUAL ACUITY']).map(&:concept_id)],
      :order => 'obs_datetime DESC').uniq

    if @visual_acuity_encounters.nil?
      @visual_acuity_encounters = []
    end

    @visual_acuity_obs = {}

    @visual_acuity_encounters.each{|e|
      @visual_acuity_obs[e.encounter_id] = @patient.person.observations.find(:all,
        :joins => :encounter,
        :conditions => ['encounter_type = ? AND encounter.encounter_id = ?',
          diabetes_test_id, e.encounter_id],
        :order => 'obs_datetime DESC')
    }


    # Fundoscopy
    @fundoscopy_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['LEFT EYE FUNDOSCOPY',
            'RIGHT EYE FUNDOSCOPY']).map(&:concept_id)],
      :order => 'obs_datetime DESC').uniq

    if @fundoscopy_encounters.nil?
      @fundoscopy_encounters = []
    end

    @fundoscopy_obs = {}

    @fundoscopy_encounters.each{|e|
      @fundoscopy_obs[e.encounter_id] = @patient.person.observations.find(:all,
        :joins => :encounter,
        :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
          diabetes_test_id, e.encounter_id],
        :order => 'obs_datetime DESC')
    }

    # Urea
    urea_id = Concept.find_by_name('UREA').id
    @urea_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, urea_id],
      :order => 'obs_datetime DESC')


    # Macrovascular
    macrovascular_id = Concept.find_by_name('MACROVASCULAR').id
    @macrovascular_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, macrovascular_id],
      :order => 'obs_datetime DESC')
    render :layout => 'menu'
  end

  def treatment_orders(patient_id)

    treatment_encouter_id   = EncounterType.find_by_name("TREATMENT").id
    drug_order_id           = OrderType.find_by_name("DRUG ORDER").id
    diabetes_id             = Concept.find_by_name("DIABETES MEDICATION").id
    hypertensition_id       = Concept.find_by_name("HYPERTENSION").id

    Order.find_by_sql("SELECT distinct orders.order_id, orders.concept_id,concept_name.name AS drug_name,obs.value_coded AS diagnosis_id,
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
                        INNER JOIN concept_name_tag_map on concept_name_tag_map.concept_name_id = concept_name.concept_name_id
                        WHERE encounter_type = #{treatment_encouter_id} AND encounter.patient_id = #{patient_id}
                          AND encounter.voided = 0 AND orders.voided = 0
                          AND orders.order_type_id = #{drug_order_id} AND obs.value_coded IN (#{diabetes_id}, #{hypertensition_id})
                          AND concept_name_tag_id = 4
                        GROUP BY order_id, obs.value_coded
                        ORDER BY drug_name, start_date DESC")
  end

  def important_medical_history
      recent_screen_complications
  end

  def simple_graph
      recent_screen_complications
  end

  def hiv
      recent_screen_complications
  end
  def recent_screen_complications
    session_date = session[:datetime].to_date rescue Date.today
    #find the user priviledges
    @super_user = false
    @nurse = false
    @clinician  = false
    @doctor     = false
    @registration_clerk  = false

    @user = User.find(session[:user_id])
    @user_privilege = @user.user_roles.collect{|x|x.role}

    if @user_privilege.first.downcase.include?("superuser")
      @super_user = true
    elsif @user_privilege.first.downcase.include?("clinician")
      @clinician  = true
    elsif @user_privilege.first.downcase.include?("nurse")
      @nurse  = true
    elsif @user_privilege.first.downcase.include?("doctor")
      @doctor     = true
    elsif @user_privilege.first.downcase.include?("registration clerk")
      @registration_clerk  = true
    end

    @patient      = Patient.find(params[:id] || session[:patient_id]) rescue nil
    void_encounter if (params[:void] && params[:void] == 'true')
    #@encounters   = @patient.encounters.current.active.find(:all)
    @encounters   = @patient.encounters.find(:all, :conditions => ['DATE(encounter_datetime) = ?',session_date.to_date])
    excluded_encounters = ["Registration", "Diabetes history","Complications", #"Diabetes test",
      "General health", "Diabetes treatments", "Diabetes admissions","Hospital admissions",
      "Hypertension management", "Past diabetes medical history"]
    @encounter_names = @patient.encounters.active.map{|encounter| encounter.name}.uniq.delete_if{ |encounter| excluded_encounters.include? encounter.humanize } rescue []
    ignored_concept_id = Concept.find_by_name("NO").id;

    @observations = Observation.find(:all, :order => 'obs_datetime DESC',
      :limit => 50, :conditions => ["person_id= ? AND obs_datetime < ? AND value_coded != ?",
        @patient.patient_id, Time.now.to_date, ignored_concept_id])

    @observations.delete_if { |obs| obs.value_text.downcase == "no" rescue nil }

    # delete encounters that are not required for display on patient's summary
    @lab_results_ids = [Concept.find_by_name("Urea").id, Concept.find_by_name("Urine Protein").id, Concept.find_by_name("Creatinine").id]
    @encounters.map{ |encounter| (encounter.name == "DIABETES TEST" && encounter.observations.delete_if{|obs| !(@lab_results_ids.include? obs.concept.id)})}
    @encounters.delete_if{|encounter|(encounter.observations == [])}

    @obs_datetimes = @observations.map { |each|each.obs_datetime.strftime("%d-%b-%Y")}.uniq

    @vitals = Encounter.find(:all, :order => 'encounter_datetime DESC',
      :limit => 50, :conditions => ["patient_id= ? AND encounter_datetime < ? ",
        @patient.patient_id, Time.now.to_date])

    @patient_treatements = treatment_orders(@patient.id)

    diabetes_id       = Concept.find_by_name("DIABETES MEDICATION").id

    @patient_diabetes_treatements     = []
    @patient_hypertension_treatements = []

    @patient_diabetes_treatements = aggregate_treatement_orders(@patient.id)

    selected_medical_history = ['DIABETES DIAGNOSIS DATE','SERIOUS CARDIAC PROBLEM','STROKE','HYPERTENSION','TUBERCULOSIS']
    @medical_history_ids = selected_medical_history.map { |medical_history| Concept.find_by_name(medical_history).id }
    @significant_medical_history = []
    @observations.each { |obs| @significant_medical_history << obs if @medical_history_ids.include? obs.concept_id}

    @arv_number = @patient.arv_number rescue nil
    @status     = @patient.hiv_status
    #@status =Concept.find(Observation.find(:first,  :conditions => ["voided = 0 AND person_id= ? AND concept_id = ?",@patient.person.id, Concept.find_by_name('HIV STATUS').id], :order => 'obs_datetime DESC').value_coded).name.name rescue 'UNKNOWN'
    @hiv_test_date    = @patient.hiv_test_date rescue "UNKNOWN"
    @hiv_test_date = "Unkown" if @hiv_test_date.blank?
    @remote_art_info  = Patient.remote_art_info(@patient.national_id) rescue nil

    @recents = recent_screen_complications(@patient.id)

    # set the patient's medication period
    @patient_medication_period = patient_diabetes_medication_duration(@patient.id)

    render :layout => false
  end

  def aggregate_treatement_orders(patient_id)

    hypertensition_medication_id  = Concept.find_by_name("HYPERTENSION MEDICATION").id
    treatment_encouter_id         = EncounterType.find_by_name("TREATMENT").id
    drug_order_id                 = OrderType.find_by_name("DRUG ORDER").id
    diabetes_id                   = Concept.find_by_name("DIABETES MEDICATION").id
    hypertensition_id             = Concept.find_by_name("HYPERTENSION").id
    #need to add the concept_name_tag for the line below
    preffered_id                  = ConceptNameTag.find_by_tag("PREFERRED").id rescue 0

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

    Order.find_by_sql(medication_query);
  end

   def recent_screen_complications(patient_id)

    @patient = Patient.find(patient_id || session[:patient_id]) rescue nil

    @person = @patient.person
    @encounters = @patient.encounters.find_all_by_encounter_type(EncounterType.find_by_name('DIABETES TEST').id)
    @observations = @encounters.map(&:observations).flatten
    @obs_datetimes = @observations.map { |each|each.obs_datetime.strftime("%d-%b-%Y")}.uniq
    @address = @person.addresses.last

    diabetes_test_id = EncounterType.find_by_name('Diabetes Test').id

    creatinine_id = Concept.find_by_name('CREATININE').id
    @creatinine_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, creatinine_id],
      :order => 'obs_datetime DESC').first rescue ""

    # Urine Protein
    urine_protein_id = Concept.find_by_name('URINE PROTEIN').id
    @urine_protein_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, urine_protein_id],
      :order => 'obs_datetime DESC').first rescue ""

    # Foot Check
    foot_check_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['RIGHT FOOT/LEG',
            'LEFT FOOT/LEG']).map(&:concept_id)])
    @foot_check_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
        diabetes_test_id, foot_check_encounters.map(&:id)],
      :order => 'obs_datetime DESC').first rescue ""

    # Visual Acuity RIGHT EYE FUNDOSCOPY
    visual_acuity_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['LEFT EYE VISUAL ACUITY',
            'RIGHT EYE VISUAL ACUITY']).map(&:concept_id)])
    @visual_acuity_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
        diabetes_test_id, visual_acuity_encounters.map(&:id)],
      :order => 'obs_datetime DESC').first rescue ""

    # Fundoscopy
    fundoscopy_encounters = @patient.encounters.find(:all,
      :joins => :observations,
      :conditions => ['concept_id IN (?)',
        ConceptName.find_all_by_name(['LEFT EYE FUNDOSCOPY',
            'RIGHT EYE FUNDOSCOPY']).map(&:concept_id)])
    @fundoscopy_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND encounter.encounter_id IN (?)',
        diabetes_test_id, fundoscopy_encounters.map(&:id)],
      :order => 'obs_datetime DESC').first rescue ""

    # Urea
    urea_id = Concept.find_by_name('UREA').id
    @urea_obs = @patient.person.observations.find(:all,
      :joins => :encounter,
      :conditions => ['encounter_type = ? AND concept_id = ?',
        diabetes_test_id, urea_id],
      :order => 'obs_datetime DESC').first rescue ""

    recent_screen_complications = {"creatinine" => @creatinine_obs,
      "urine_protein" => @urine_protein_obs,
      "foot_check" => @foot_check_obs,
      "visual_acuity" => @visual_acuity_obs,
      "fundoscopy" => @fundoscopy_obs,
      "urea" => @urea_obs
    }

  end

  def patient_diabetes_medication_duration(patient_id)

    @patient = Patient.find(patient_id || session[:patient_id]) rescue nil

    @person = @patient.person
    @encounters = @patient.encounters.find_all_by_encounter_type(EncounterType.find_by_name('TREATMENT').id)
    @observations = @encounters.map(&:observations).flatten
    @obs_datetimes = @observations.map { |each|each.obs_datetime.strftime("%d-%b-%Y")}.uniq

    @mindate = @obs_datetimes.first

    @maxdate = @obs_datetimes.last

    return_string = ""

    if(@maxdate && @mindate)
      date_diff = (@maxdate.to_date - @mindate.to_date).to_i

      if(date_diff > 365)
        return_string = ((@maxdate.to_date - @mindate.to_date).to_i/365).to_s + " years"
      else
        if(date_diff > 30)
          return_string = ((@maxdate.to_date - @mindate.to_date).to_i/30).to_s + " months"
        else
          return_string = ((@maxdate.to_date - @mindate.to_date).to_i/30).to_s + " months"
        end
      end

    else
      return_string = " an unknown period"
    end

    patient_diabetes_medication_duration = return_string

    patient_diabetes_medication_duration
  end
  
  private
  
  
end
