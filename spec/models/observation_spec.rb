require File.dirname(__FILE__) + '/../spec_helper'

describe Observation do
  fixtures :obs, :concept_name, :concept

  sample({
    :obs_id => 1,
    :person_id => 1,
    :concept_id => 1,
    :encounter_id => 1,
    :order_id => 1,
    :obs_datetime => Time.now,
    :location_id => 1,
    :obs_group_id => 1,
    :accession_number => '',
    :value_group_id => 1,
    :value_boolean => false,
    :value_coded => 1,
    :value_drug => 1,
    :value_datetime => Time.now,
    :value_modifier => '',
    :value_text => 'MELTING',
    :date_started => Time.now,
    :date_stopped => Time.now,
    :comments => '',
    :creator => 1,
    :date_created => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    observation = create_sample(Observation)
    observation.should be_valid
  end
  
  it "should have a psuedo-property for patient_id" do
    observation = create_sample(Observation)
    observation.patient_id = 10
    observation.person_id.should == 10
  end
  
  it "should allow you to assign the concept by name" do
    observation = create_sample(Observation)
    observation.concept_name = concept_name(:alcohol_counseling).name
    observation.concept_id.should == concept_name(:alcohol_counseling).concept_id
  end
  
  it "should allow you to assign the value coded or text" do
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_coded => nil, :value_text => nil)
    observation.value_coded_or_text = concept_name(:alcohol_counseling).name
    observation.value_coded.should == concept_name(:alcohol_counseling).concept_id
    observation.value_text.should be_nil

    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_coded => nil, :value_text => nil)
    observation.value_coded_or_text = "GIANT ROBOT TORSO MODE"
    observation.value_text.should == "GIANT ROBOT TORSO MODE"
    observation.value_coded.should be_nil
  end
  
  it "should cache the most common observations for each question" do 
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_text => 'LAME', :value_coded => nil, :value_datetime => nil)
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_text => 'COOL', :value_coded => nil, :value_datetime => nil)
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_text => 'COOL', :value_coded => nil, :value_datetime => nil)
    Observation.update_most_common_observations(concept(:outpatient_diagnosis).id)
    Observation.class_eval("@@most_common_observations[#{concept(:outpatient_diagnosis).id}]").should == ["COOL", "LAME"]
  end
  
  it "should find the most common observation and sort by the answer" do
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_text => 'LAME', :value_coded => nil, :value_datetime => nil)
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_text => 'COOL', :value_coded => nil, :value_datetime => nil)
    observation = create_sample(Observation, :concept_id => concept(:outpatient_diagnosis).id, :value_text => 'COOL', :value_coded => nil, :value_datetime => nil)
    Observation.update_most_common_observations(concept(:outpatient_diagnosis).id)
    Observation.find_most_common(concept(:outpatient_diagnosis).id, nil).should == ["COOL", "LAME"]
    Observation.find_most_common(concept(:outpatient_diagnosis).id, "LAME").should == ["LAME"]
  end
  
  it "should be displayable as a string" do
    observation = create_sample(Observation, {:concept_id => concept(:outpatient_diagnosis).id, :value_coded => concept(:alcohol_counseling).id, :value_numeric => 1, :value_datetime => nil})
    observation.to_s.should == "OUTPATIENT DIAGNOSIS: ALCOHOL COUNSELINGMELTING1.0"    
  end
    
  it "should be able to display the answer as a string" do
    observation = create_sample(Observation, {:concept_id => concept(:outpatient_diagnosis).id, :value_coded => concept(:alcohol_counseling).id, :value_numeric => 1, :value_datetime => nil})
    observation.answer_string.should == "ALCOHOL COUNSELINGMELTING1.0"    
  end
end
