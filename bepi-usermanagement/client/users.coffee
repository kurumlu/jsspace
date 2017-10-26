debugThis = debug.context('users')
###
AGGREED WITH FTA:
Show more and show all buttons apply all type of companies or contractors search at ones.
It will be same limit for all of them
###
UsersSub =
   subs: []
   subscribe: (roles)-> UsersSub.subs.push Meteor.subscribe 'users', roles, subCb('users',debugThis)

initLimit=10
limit = new ReactiveVar(initLimit)
contractorSiteIds = new ReactiveVar(undefined)

show = (nbr)-> _.gt nbr , 10 

showing = (nbr)->
   count = limit.get()
   #max nbr
   if count is 0 then return nbr
   else if count > nbr then count = nbr
   else return count

Router.route '/users/:roles?',
   name: 'usermanagement'
   layout: 'usermanagement'
   onBeforeAction: ->
      Tracker.nonreactive => UsersSub.subscribe @params.roles
      Translation.addContext  'general','user_management','companies','sites'
      Session.set  'userSearch', {}
      limit.set(initLimit)
      contractorSiteIds.set undefined
      if isUserBepi()
         query = $or:[ {assessorIndividual:{$exists:1}}, {assessorContact:{$exists:1}},{consultantIndividual:{$exists:1}},{consultantContact:{$exists:1}},{testlabIndividual:{$exists:1}},{testlabContact:{$exists:1}},{chemicalauditorIndividual:{$exists:1}}, {chemicalauditorContact:{$exists:1}} ]
         Meteor.call 'searchSites',query,(err,res)=>
            Alert.new err, 'danger' if err
            contractorSiteIds.set res if res
      this.next()
   waitOn: -> UsersSub.subs
   data: ->
      if this.ready() and Meteor.user()
         search = Session.get 'userSearch'
         delete search.userType
         q = _.extend search
         data = {}
         roles = @params.roles
         user= Meteor.user()
         if isUserBepi()
            #bepi may have several view for users:  bepi,companies, contractors
            if !roles or roles is 'bepi'
               _.extend q,
                  roles:'bepi'
               nbr = Meteor.users.find(q).count()
               data =
                  users: Meteor.users.find q,{limit:limit.get()} 
                  isBepi:true
                  show:show(nbr)
                  showing:showing(nbr)
                  totalNbr:nbr
            else if roles is 'companies' 
               _.each companies , (company) ->
                  _.extend q,
                     roles:{$in:["#{company}","#{company}Admin"]}
                  _.extend data ,
                     "#{company}Users": Meteor.users.find q, {limit:limit.get()}
                     isCompany:true
            else if roles is 'contractors'
               sites=[]
               Meteor.autorun =>
                  ids = contractorSiteIds.get()
                  if ids and ids.length > 0
                     Meteor.subscribe 'sites',{_id:{$in:ids}},subCb('sites',debugThis,{ids:ids})
               _.each contractors , (contractor)->
                  _.extend q , 
                     roles:{$in:["#{contractor}","#{contractor}Contact"]}
                  _.extend data , 
                     "#{contractor}Users": Meteor.users.find q,{limit:limit.get()} 
                     isContractor:true
         else if isUserAdmin()
            #users management view of a company Admin
            types= companytypes() 
            _.each types , (company) ->
               _.extend data ,
                     "#{company}Users": Meteor.users.find q,{limit:limit.get()} 
            data.isCompany=true
         else if isUserContact()
            #users management view of a contractor Contact 
            #contractor users has assigned Sites column. To be able to fill this column we need to getthe Sites list
            Meteor.autorun =>
               Meteor.subscribe 'sites',{},subCb('sites',debugThis)
            _.extend q , 
               $or:[{_id:user._id},{"profile.contractorContactId":user._id}]
               _.extend data , 
                   "#{contactType()}Users": Meteor.users.find q,{limit:limit.get()} 
            data.isContractor=true
         else
            Router.go "home"  
         return data
   onStop: -> Session.set 'userSearch', {}

Template.usermanagement.onRendered -> Session.set 'userSearch', {}

contractors = ['consultant','assessor','chemicalauditor','testlab']
companies = ['participant','supplier','producer','branch']
users = ["bepi","companies","contractors" ]
companyNames = {}

isUserAdmin = -> if Roles.userIsInRole Meteor.userId(), ['participantAdmin','branchAdmin','supplierAdmin','producerAdmin'] then return true else return false
isUserContact = -> if Roles.userIsInRole Meteor.userId(), ['consultantContact','assessorContact','chemicalauditorContact','testlabContact'] then return true else return false
isUserBepi =  -> if Roles.userIsInRole Meteor.userId(), ['bepi'] then return true else return false
isCompanyUser = -> if Roles.userIsInRole Meteor.userId(), ['participantAdmin','participant','branchAdmin','branch','supplierAdmin','supplier','producerAdmin','producer'] then return true else return false
isContractorsUser = -> if Roles.userIsInRole Meteor.userId(), ['consultantContact','consultant','assessorContact','assessor','chemicalauditorContact','chemicalauditor','testlabContact','testlab'] then return true else return false

companytypes = () ->
   roles= Meteor.user().roles
   updatedroles=[]
   _.each roles, (role) ->
      index=role.search("Admin")
      unless index is -1
         updatedroles.push role.substring(0,index)
      else
         updatedroles.push role
   return _.uniq updatedroles

contactType = ()->
   result="unknown"
   roles= Meteor.user().roles
   _.each roles , (role) ->
      index=role.search("Contact")
      unless index is -1
         result= role.substring(0,index)
   return result

Template.userTypeSelection.helpers
   userType: -> users

Template.userTypeSelection.events
   'change #userTypeSelection': (e,t)-> Router.go '/users/'+ e.target.value

Template.bepiUsers.events
   'click #show_more': (e,t)-> limit.set(limit.get() + 10)
   'click #show_all': (e,t)-> limit.set(0)

getTotalNbr =  (role, isContractor=false)->
   if this.isContractor 
      roles = {"roles":{$in:["#{role}","#{role}Contact"]}}
   else
      roles = {"roles":{$in:["#{role}","#{role}Admin"]}}
   q = Session.get 'userSearch'
   delete q.userType
   _.extend q, roles
   return Meteor.users.find(q).count() 

Template.tableWrapper.helpers
   totalNbr: -> getTotalNbr this.role,this.isContractor
   showing: ->
      nbr = getTotalNbr this.role,this.isContractor 
      return showing(nbr)

Template.tableWrapper.events
   'click #show_more': (e,t)-> limit.set(limit.get() + 10)
   'click #show_all': (e,t)-> limit.set(0)


changeSearch = (key, eventId,userType) ->
   search = Session.get 'userSearch'
   #if search goes for different type of user then we reset the search values
   unless userType is search.userType  
      search={}
      search.userType = userType
   value = ($("#{eventId}").val()).trim()
   if value is "" then delete search["#{key}"]
   else 
      search["#{key}"]  =
         '$regex':value
         $options:"i"
   Session.set 'userSearch', search

Template.bepiUsers.events
   'click .addBepiUser': (e) -> Router.go "user", {}, {query:"role=bepi"}
   'keyup #bepi_searchBy_Name':(e,t) -> changeSearch "profile.name", "#bepi_searchBy_Name","bepi"
   'keyup #bepi_searchBy_Email':(e,t) -> changeSearch "emails.address" ,"#bepi_searchBy_Email","bepi"

Template.tableWrapper.events
   'click .addUser': (e, t) -> Router.go "user", {}, {query:"role=#{@.role}"}

Template.userSearchTable.events
   'keyup #company_searchBy_Name':(e,t) -> changeSearch "profile.name","#company_searchBy_Name","company" 
   'keyup #contractor_searchBy_Name':(e,t) -> changeSearch "profile.name","#contractor_searchBy_Name","contractor" 

   'keyup #contractor_searchBy_Email':(e,t) -> changeSearch "emails.address","#contractor_searchBy_Email","contractor"
   'keyup #company_searchBy_Email':(e,t) -> changeSearch "emails.address","#company_searchBy_Email","company"

   'keyup #contractor_searchBy_CompanyName':(e,t) -> changeSearch "profile.companyName","#contractor_searchBy_CompanyName","contractor"
   'keyup #company_searchBy_CompanyName':(e,t) ->changeSearch "profile.companyName","#company_searchBy_CompanyName","company"

individualRoles = (roles) ->
   newRoles=[]
   _.each roles, (role)->
      index= role.search "Contact"
      unless index is -1  then newRoles.push role.substring(0, index) else newRoles.push role
   return _.compact _.uniq newRoles

surveys =
   assessor:"af"
   consultant:"ipr"
   chemicalauditor:"sccm_audit"
   testlab:"sccm_testing"   

Template.companyUsers.helpers
   participantUsersOfParticipant:->
      if this.participantUsers
         allUsers = this.participantUsers.fetch()
         participants=[]
         _.each allUsers, (user) ->
            if  Roles.userIsInRole user._id, ['participant','participantAdmin'] then participants.push user
         return _.uniq _.compact participants
   branchUsersOfParticipant:->
      if this.participantUsers
         allUsers = this.participantUsers.fetch()
         participants=[]
         _.each allUsers, (user) ->
            if  Roles.userIsInRole user._id, ['branch','branchAdmin'] then participants.push user
         return _.uniq _.compact participants

Template.userrows.helpers
   isContractor:->    
      #for bepi user -> check with url
      roles = Router.current().params?.roles
      if roles is 'contractors' then return true
      #contractor user -> check with user role
      if isContractorsUser()  then return true else return false
   contractorSites:->
      sites = []
      if @role and @data._id
         sites = Sites.find {"#{@role}Individual.id":@data._id}
      return sites
   queryString:-> "contractor="+Template.instance().data.data._id
   hasContact:->
      data = Template.instance().data.data
      if data.profile?.contractorContactId then return true
      return false

Template.linkGlyphicon.helpers
   isContractorContact:-> 
      if @.role
         contact = @.role.concat "Contact"
         if _.includes @.data.roles, contact then return true
      return false
   contractorType:-> @.role


Template.contractorUsers.helpers
   warning: ->
      warning=false
      params = Router.current().params
      if isUserBepi()  
         if  params?.roles is  "contractors" then warning = true
      return warning

findRouting = (userId)->
   if Roles.userIsInRole userId , companies then return "companies"
   else if Roles.userIsInRole userId , contractors then return "contractors"
   else return "bepi"

Template.addGlyphicons.events
   'click .removeUser': (e,t) ->
      Meteor.call 'deleteUser' , t.data.data._id ,(e,r) ->
         if e
            if e.details then  Alert.new  e.reason, 'warning' else Alert.new e, 'danger'
         else
            Alert.new  Translation.translate("User_status_is_set_to_inactive"), 'success'
      if isUserBepi() then  Router.go "usermanagement" , {roles:findRouting currentDoc}




      
