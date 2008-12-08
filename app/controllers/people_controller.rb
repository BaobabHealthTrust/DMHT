class PeopleController < ApplicationController
  def index
    @people = Person.find(:all)
    render :layout => "menu"
  end

  def new
  end
  
  def identifiers
  end

  def search
    @people = PatientIdentifier.find_all_by_identifier(params[:identifier]).map{|id| id.patient.person} unless params[:identifier].blank?
    redirect_to :controller => :encounters, :action => :new, :patient_id => @people.first.id and return unless @people.blank? || @people.size > 1
    @people = Person.find(:all, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
    "gender = ? AND \
     person.voided = 0 AND \
     (patient.voided = 0 OR patient.voided IS NULL) AND \
<<<<<<< HEAD:app/controllers/people_controller.rb
     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \
=======
     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \ 
>>>>>>> 724a467f4134ee4b8b7c185610e620c1a0a324ff:app/controllers/people_controller.rb
     (person_name.family_name LIKE ? OR person_name_code.family_name_code LIKE ?) AND \
<<<<<<< HEAD:app/controllers/people_controller.rb
     (person_name.family_name2 LIKE ? OR person_name_code.family_name2_code LIKE ? OR person_name.family_name2 IS NULL )", 
=======
     (person_name.family_name2 LIKE ? OR person_name_code.family_name2_code LIKE ? OR person_name.family_name2 IS NULL )",
>>>>>>> 724a467f4134ee4b8b7c185610e620c1a0a324ff:app/controllers/people_controller.rb
    params[:gender], 
    params[:given_name], 
    (params[:given_name] || '').soundex,
     params[:family_name2], 
    (params[:family_name2] || '').soundex,
    params[:family_name], 
    (params[:family_name] || '').soundex,
    params[:family_name2], 
    (params[:family_name2] || '').soundex,
    ]) if @people.blank?
  end

  # This method is just to allow the select box to submit, we could probably do this better
  def select
    redirect_to :controller => :encounters, :action => :new, :patient_id => params[:person] and return unless params[:person].blank? || params[:person] == '0'
    redirect_to :action => :new, :gender => params[:gender], :given_name => params[:given_name], :family_name => params[:family_name], 
    :family_name2 => params[:family_name2], :address2 => params[:address2], :identifier => params[:identifier]
  end  

  def create
    person = Person.create(params[:person])

    if params[:birth_year] == "Unknown"
      person.set_birthdate_by_age(params[:age_estimate])
    else
      person.set_birthdate(params[:birth_year], params[:birth_month], params[:birth_day])
    end
    person.save
    person.names.create(params[:person_name])
    person.addresses.create(params[:person_address])

# TODO handle the birthplace attribute

    if params[:create_patient] == "true"
      patient = person.create_patient
      # This might actually be a national id, but currently we wouldn't know        
      patient.patient_identifiers.create(:identifier => params[:identifier], :identifier_type => PatientIdentifierType.find_by_name("Unknown id")) unless params[:identifier].blank?
      patient.national_id_label
      print_and_redirect("/patients/print_national_id/?patient_id=#{patient.id}", next_task(patient))  
    else
      redirect_to :action => "index"
    end
  end

end
