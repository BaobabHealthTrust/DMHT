DMHT is a Diabetes Mellitus and Hypertension patient management application written in Ruby on Rails
and is intended as a web front end for OpenMRS. 

OpenMRS® is a community-developed, open-source, enterprise electronic medical 
record system framework. We've come together to specifically respond to those 
actively building and managing health systems in the developing world, where 
AIDS, tuberculosis, and malaria afflict the lives of millions. Our mission is 
to foster self-sustaining health information technology implementations in 
these environments through peer mentorship, proactive collaboration, and a code 
base that equals or surpasses proprietary equivalents. You are welcome to come 
participate in the community, whether by implementing our software, or 
contributing your efforts to our mission!

DMHT was built by Baobab Health Trust.It is licensed under the Mozilla Public License.

Getting Started:

1. Clone the application
2. Use your terminal to get into the applications root directory
3. Make sure you have bundler installed
4. Run bundle install to install all application dependencies
5. Edit application.yml.example and database.yml.example to configure application
   and database settings
6. Run script/initial_database_setup.sh [environment=development] [site=MPC]
7. Run passenger start if you are using passenger as your server or
   script/server to run your default server.




