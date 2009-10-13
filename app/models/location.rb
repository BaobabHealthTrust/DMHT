class Location < ActiveRecord::Base
  set_table_name "location"
  set_primary_key "location_id"
  has_many :obs, :foreign_key => :location_id
  has_many :patient_identifiers, :foreign_key => :location_id
  has_many :encounters, :foreign_key => :location_id
  belongs_to :parent, :foreign_key => :parent_location_id, :class_name => "Location"
  has_many :children, :foreign_key => :parent_location_id, :class_name => "Location"
  belongs_to :user, :foreign_key => :user_id

  include Openmrs

  cattr_accessor :current_location

  def site_id
    self.description.match(/\(ID=(\d+)\)/)[1] 
  rescue 
    raise "The id for this location has not been set (#{Location.current_location.name}, #{Location.current_location.id})"   
  end

  def Location.get_list
    return @@location_list
  end
  
  def Location.initialize_location_list
    locations = <<EOF
Amidu
Area 10
Area 11
Area 12
Area 14
Area 15
Area 18 A
Area 18 B
Area 2
Area 22
Area 22B
Area 22 (SOS)
Area 23
Area 24
Area 25 A
Area 25 B
Area 25 C
Area 3
Area 30
Area 33
Area 35
Area 36
Area 43
Area 44
Area 47
Area 49
Area 9
Balaka
Biwi (A8)
Blantyre
Boghoyo
Bvumbwe
Bwaila
CCDC
Central
Chadza
Chakhaza
Chakhumbira
Chamba
Champiti
Changata
Chapananga
Chapinduka
Chauma
Chigaru
Chikho
Chikowi
Chikulamayembe
Chikumbu
Chikwawa
Chikweo
Chilikumwendo
Chilinde 1 (A21)
Chilinde 2 (A21)
Chilooko
Chilowamatambe
Chimaliro
Chimoka
Chimombo
Chimutu
Chimwala
Chindi
Chingwirizano
Chinsapo 1 (A46)
Chinsapo 2 (A46)
Chipasula
Chiradzulu
Chiseka
Chisemphere
Chisikwa
Chitedze
Chitekwele
Chitera
Chitipa
Chitukula
Chiuzira
Chiwalo
Chiwere
Chowe
Chulu
Dambe
Dedza
Dowa
Dzoole
Falls
Fukamalaza
Fukamapiri
Ganya
Gomani
Gulliver (A49)
Jalasi
Jaravikuwa
Jenala
Juma
Kabudula
Kabunduli
Kachenga
Kachere
Kachindamoto
Kachulu
Kadewere
Kaduya
Kafuzira
Kalembo
Kaliyeka 1
Kaliyeka 2
Kalolo
Kalonga
Kaluluma
Kalumba
Kalumbu
Kalumo
Kambalame
Kambwiri
Kameme
Kamenyagwaza
Kampingo Sibande
Kamuzu Barracks
Kanduku
Kanengo
Kanyenda
Kaomba
Kaondo
Kapelula
Kapeni
Kaphiri
Kaphuka
Kapichi
Kapoloma
Kaponda
Karonga
Kasakula
Kasisi
Kasumbu
Kasungu
Katema
Katuli
Katumbi
Katunga
Kauma
Kawale 1 (A4)
Kawale 2 (A4)
Kawamba
Kawinga
Kayembe
Khombedza
Khongoni
Khosolo Jere
Khwetemule
Kilupula
Kuluunda
Kumtumanji
Kuntaja
Kunthembwe
Kwataine
Kyungu
Laston Njema
Likoma
Likoswe
Likuni
Lilongwe
Lilongwe City
Lingadzi
Liwonde
Lukwa
Lumbadzi
Lundu
Mabuka
Mabulabo
Machinga
Machinjiri
Maganga
Makanjira
Makata
Makhuwira
Makoko
Makwangwala
Malanda
Malangalanga Admarc
Malemia
Malenga
Malengachanzi
Malenga Mzoma
Malili
Mangochi
Mankhambira
Maoni
Masasa
Maseya
Masula
Masumbankhunda
Maula Prison
Mavwere
Mazengera
Mbawela
Mbelwa 4
Mbenje
Mbiza
Mchesi (A8)
Mchezi
Mchinji
Mduwa
Mgabu
Mgona
Mkanda
Mkhumba
Mkondowe
Mkumbila
Mkumbira
Mkumpha
Mlauli
Mlilima
Mlolo
Mlomba
Mlonyeni
Mlumbe
Mmbwananyambi
Mnyanja
Mozambique
Mpama
Mpando
Mpherembe
Mphonde
Mphuka
Mponda
Mponela
Mposa
Mpunga
Msakambewa
Msamala
Msiska
Msosa
Mtandire
Mthiramanja
Mtsiliza
Mtwalo
Mulanje
Mwadzama
Mwahenga
Mwakaboko
Mwalweni
Mwambo
Mwamlowe
Mwankunikira
Mwansambo
Mwanza
Mwarangombe
Mwase
Mwaulambya
Mwenemisuku
Mwenewenya
Mwenyekondo
Mzikubola
Mzimba
Mzuzu-zuku
Namabvi
Nankumba
Nazombe
Nchilamwera
Ndamera
Ndindi
Ngabu
Ngokwe
Ngozi
Ngwenya
Njewa
Njolomole
Njombwa
Nkalo
Nkaya
Nkhata-Bay
Nkhota-kota
Nkhumba
Nkoola
Nkukula
Northern
Nsabwe
Nsanama
Nsanje
Ntchema
Ntcheu
Ntchisi
Ntema
Nthache
Nthalire
Nthondo
Nthunduwala
Nyachikadza
Nyaluwanga
Nyambi
Pemba
Phalombe
Phambala
Phwetekere
Piasani
Police Mobile Force
Rumphi
Salima
Same
Santhe
Santi
Sawali
Shire (A49)
Simphasi
Simulemba
Sitola
Somba
SOS Village
Southern
State House
Symon
Tambala
Tengani
Thomasi
Thukuta
Thyolo
Timbiri
Tsabango
Tsikulamowa
Unknown
Wasambo
Wimbe
Zambia
Zilakoma
Zimbabwe
Zolokere
Zomba
Zulu
EOF
    return locations.split("\n")
  end

  @@location_list = initialize_location_list()

end

### Original SQL Definition for location #### 
#   `location_id` int(11) NOT NULL auto_increment,
#   `name` varchar(255) NOT NULL default '',
#   `description` varchar(255) default NULL,
#   `address1` varchar(50) default NULL,
#   `address2` varchar(50) default NULL,
#   `city_village` varchar(50) default NULL,
#   `state_province` varchar(50) default NULL,
#   `postal_code` varchar(50) default NULL,
#   `country` varchar(50) default NULL,
#   `latitude` varchar(50) default NULL,
#   `longitude` varchar(50) default NULL,
#   `parent_location_id` int(11) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`location_id`),
#   KEY `user_who_created_location` (`creator`),
#   CONSTRAINT `user_who_created_location` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)





