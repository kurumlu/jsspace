debugThis = debug.context 'users'

checkAccess = (t) ->
   unless t.userId and Roles.userIsInRole t.userId, ['bepi', 'producerAdmin','participantAdmin','branchAdmin','supplierAdmin','consultantContact', 'assessorContact', 'chemicalAuditorContact', 'testLabContact']
      throwError "unauthorized",'You_have_to_be_logged_in_as_bepi_user_to_add_edit_contractors'

checkEmail = (email, currentId) ->
   findEmail = Meteor.users.find {emails:{$elemMatch:{address:email}}}
   findEmailCount = findEmail.count()
   # check if email exists
   if findEmailCount is 0
      return true
   else 
      #check if this email is your email
      if currentId?
         findEmailById = Meteor.users.find {_id: currentId, emails:{$elemMatch:{address:email}}}
         if findEmailById.count() is 1
            return true
      throwError "danger","existing_email",'This_email_address_belongs_to_an_existing_user','Please_try_edit_option_if_you_would_like_to_change'
      return false

contractors = ['consultant','consultantContact','assessor','assessorContact','chemicalauditor','chemicalauditorContact','testlab','testlabContact' ]
companies = ['participant','participantAdmin','branch','branchAdmin','supplier','supplierAdmin','producer','producerAdmin']
assignmentSubjects =
   consultant:"improvement phase report"
   assessor:"assessment"
   chemicalauditor: "SCCM audit report"
   testlab:"SCCM test report"

reports =
   consultant:"ipr"
   assessor:"af"
   chemicalauditor:"sccm_audit"
   testlab:"sccm_testing"

throwError = (sort,title, err1,err2=null) ->
   user = Meteor.user()
   language="en"
   if user then language = user.profile?.language or "en"
   error1 = Translation.translations.findOne err1
   if err2 then error2 = Translation.translations.findOne err2
   if error1 and language
      if error2
         error=error1["#{language}"].concat error2["#{language}"]
      else
         error = error1["#{language}"]
   throw new Meteor.Error title, error, sort


onlyAdmin = (roles) -> if roles.length is 1 and _.includes roles[0], "Admin"  then return true

isCompanyUser = (roles) ->
   array=[]
   array = _.intersection roles, companies
   if _.isEmpty array then return false
   return true


removeUser = (user) ->
   Meteor.users.update {_id:user._id} , {$unset:{profile:1,roles:1}}
   profile = 
      name:user.profile.name
      invitedBy: user.profile.invitedBy
   set =
      profile:profile
      roles:["inactive"]
   Meteor.users.update  {_id:user._id} , {$set:set}
   unset =
      emails:""
      services:""
   Meteor.users.update  {_id:user._id} , {$unset:unset}

companyType = (user) ->
   role = user.roles[0]
   index = role.search("Admin")
   unless index is -1
      return role.substring(0,index)
   else
      return role


contractors =
   "af":"assessor"
   "ipr":"consultant"

Meteor.methods
   addUser: (doc) ->
      check doc, Object
      checkAccess this
      checkEmail doc.email
      doc.invitedBy =
         userId: this.userId
         name: Meteor.user().profile.name
         email: Meteor.user().emails[0].address
      #warning = Meteor.users.findOne  {"profile.name":doc.name}
      unless  doc.roles
         doc.roles = ['bepi']
      else if isCompanyUser  doc.roles  
         if doc.company
            company = Companies.findOne {_id:doc.company}
            _.extend doc , 
            companyName:company.details.companyName
            #if user given only as Admin then add regular role to it
            if onlyAdmin doc.roles then doc.roles.push  doc.roles[0].split("Admin")[0]
      Accounts.createUser
         email: doc.email
         profile: _.pick doc, 'name','companyName','city', 'country', 'invitedBy', 'contractorContactId', 'company'
         roles: doc.roles
      user = Meteor.users.findOne {"emails.address":doc.email}
      Accounts.sendEnrollmentEmail user._id
   editUser: (userId, doc) ->
      check userId, String
      check doc, Object
      checkAccess this
      email = doc.email
      checkEmail email, userId
      delete doc.email
      roles = doc.roles
      unless roles
         roles = ['bepi']
      else if isCompanyUser roles
         #if user given only as Admin then add regular role to it
         if onlyAdmin doc.roles  then throwError "warning",'only-admin-not-allowed', 'only_admin_role_is_not_allowed'
         #if onlyAdmin doc.roles  then  throw new Meteor.Error "warning", "not_found"

      delete  doc.roles
      set = prefix doc, 'profile'
		#hier ook email veranderen anders kan de user zijn passwoord niet meer zelf veranderen
      set['services.password.reset.email'] = email 
      set['roles'] = roles
      set['emails.0.address'] = email
      #previous info is needed to check whether the user is company contact or not  
      nonUpdatedUser = Meteor.users.findOne userId
      #Admin of a company user can be only deleted if there is other Admins within the company
      if Roles.userIsInRole nonUpdatedUser._id , ['producerAdmin','supplierAdmin','participantAdmin','branchAdmin']
         #check if the Admin role is removed
         intersection=[]
         intersection= _.intersection roles, ['producerAdmin','supplierAdmin','participantAdmin','branchAdmin']
         if _.isEmpty intersection 
            #Admin role is removed - check if there is another companyAdmin
            admins=Meteor.users.find({"profile.company":nonUpdatedUser.profile.company, _id:{$ne:nonUpdatedUser._id}, roles:{$in:['producerAdmin','supplierAdmin','participantAdmin','branchAdmin']}}).fetch()
            if admins.length is 0 
               throwError "warning", "only_admin", 'This_person_is_the_only_admin','Please_add_new_admin_user_before_removing'
      Meteor.users.update userId, {$set: set}
      #if a contractor assigned one of the Sites , his info saved Site database. This should be chnaged as well.
      user = Meteor.users.findOne userId
      _.each user.roles , (role) ->
         if _.includes contractors , role
            sites = Sites.find 
               $or:[{"#{role}Individual.id":user._id},{"#{role}Contact.id":user._id}]
            if sites
               sites=sites.fetch()
               _.each sites , (site)->
                  contractor = 
                        name:user.profile.name
                        city:user.profile.city
                        country:user.profile.country
                        email:user.emails[0].address
                        id:user._id
                  if site["#{role}Individual"]?.id is user._id
                     Sites.update site._id , 
                        $set:{"#{role}Individual":contractor}
                  if site["#{role}Contact"]?.id is user._id
                     Sites.update site._id , 
                        $set: {"#{role}Contact":contractor}
         #if user happens to be company contact person , Companies collection should be updated
         if Roles.userIsInRole nonUpdatedUser._id , ['producer','producerAdmin','supplier','supplierAdmin','participant','participantAdmin','branch','branchAdmin']
            company = Companies.findOne {"details.contact.email":nonUpdatedUser.emails[0].address}
            if company
               set=
                  name:user.profile.name
                  email:user.emails[0].address
               Companies.update {_id:company._id} ,
                  $set:
                     "details.contact":set
   deleteUser: (id) ->
      check id, String
      checkAccess this
      user = Meteor.users.findOne id
      # check if user the company Contact person then delete it only if there is another Admin person within the company
      if user
         if isCompanyUser user.roles 
            if user.profile?.company
               #check if the user is the only person for the company
               only = Meteor.users.findOne {"profile.company":user.profile.company, _id:{$ne:user._id}}
               unless only
                     throwError "warning",'no_other_user', 'This_company_does_not_have_any_other_user','Please_add_another_company_admin_user_before'
               #check if the user  is the only Admin is for the company
               admins=Meteor.users.find({"profile.company":user.profile.company, _id:{$ne:user._id}, roles:{$in:['producerAdmin','supplierAdmin','participantAdmin','branchAdmin']}}).fetch()
               if admins.length is 0 
                  throwError "warning",'only_admin', 'This_person_is_the_only_admin','Please_add_new_admin_user_before_removing'
               #check if user company Contact person - incase find another contact person
               companyContact = Companies.findOne {"details.contact.email":user.emails[0].address}
               if companyContact
                  #check if there is another admin within the company
                  companytype= companyType user
                  query = 
                     $and:[{"profile.company":companyContact._id},{"_id":{$ne:user._id}},{"roles":"#{companytype}Admin"}]
                  anotherAdmin = Meteor.users.findOne
                     $and:[{"profile.company":companyContact._id},{"_id":{$ne:user._id}},{"roles":"#{companytype}Admin"}]
                  if anotherAdmin
                     Companies.update _id:companyContact._id, 
                        $set:
                           "details.contact.name":anotherAdmin.profile.name
                           "details.contact.email":anotherAdmin.emails[0].address
                     removeUser user
                  else
                     throwError "warning", 'only_admin', 'This_person_is_the_only_admin','Please_add_new_admin_user_before_removing'
               else
                  removeUser user
         else
            removeUser user
      else
         throwError "danger","unknown-user", 'User_not_found'


   addCompanyNameToCompanyUsers:->
      _.each ['producer','participant','supplier'] , (role) ->
         users = Meteor.users.find({roles:role}).fetch()
         _.each users , (user) ->
            unless user.profile?.companyName
               company = Companies.findOne {_id:user.profile.company}
               if company
                  _.assign user.profile ,
                     companyName:company.details.companyName
                  Meteor.users.update user._id , user
   reassignContractor: (siteId, assignedContractorId,newcontractorId) ->
      check siteId, String
      check assignedContractorId, String
      check newcontractorId, String
      site = Sites.findOne siteId
      newContractor=Meteor.users.findOne newcontractorId
      found=false
      if newContractor?.profile?.contractorContactId
         _.each ['consultant','assessor','chemicalauditor','testlab' ], (type) ->
            if site["#{type}Individual"]?.id is assignedContractorId 
               if site["#{type}Contact"]?.id is newContractor.profile.contractorContactId
                  set =
                     $set: 
                        "#{type}Individual":
                           'name':newContractor.profile.name
                           'city':newContractor.profile.city
                           'country':newContractor.profile.country
                           'email':newContractor.emails[0].address
                           'id':newContractor._id
                  Sites.update siteId , set
                  found=true
   					#send email to inform 
                  assignment =
                     siteName: site.siteName
                     siteAddress: "#{site.siteAddress.street}, #{site.siteAddress.city}, #{site.siteAddress.country}"
                     date: new Date()
                     "#{type}Company": newContractor.profile.companyName
                     "#{type}Individual": newContractor.profile.name
                     "#{type}Email": newContractor.emails[0].address
                  template = reports["#{type}"] 
                  if template then template2= template.concat "Assignment"  
                  contractorIndividual = _.pick newContractor.profile, 'name', 'city', 'country'
                  subject="BEPI "+assignmentSubjects["#{type}"]+ " has been assigned"
                  Email.sendToAll template2, subject, assignment, site
                  Email.sendMail template2, subject, assignment, contractorIndividual
         unless found
            throwError "danger" , 'unknown_user', 'Site_contractors_data_does_not_match_with_the_request','No_changes_have_been_done'
      else
         throwError "warning",'unknown_contractor', 'Please_choose_a_new_contractor_to_assign'

   removeContractorDataOfApprovedSurveysfromSite:->
      sites=Sites.find().fetch()
      _.each sites, (site)->
         _.each ['ipr','af'] , (survey)->
            if site.status?["#{survey}"] is 'approved'
               contractor=contractors[survey]
               Sites.update {_id:site._id} ,{$unset:{"#{contractor}Individual":"", "#{contractor}Contact":""}}



	
