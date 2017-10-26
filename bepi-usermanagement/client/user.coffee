debugThis = debug.context 'users'

defaultLimit = 25
search = new ReactiveVar {}
searching = new ReactiveVar()
ids = new ReactiveVar()


Router.route 'user/:_id?',
   template: 'user'
   name: 'user'
   onBeforeAction: ->
      Translation.addContext  'general','user_management' 
      Meteor.autorun =>
         # automatically subscribe to the user's company
         user = Meteor.users.findOne @params._id
         if user?.hasCompany()
            Meteor.subscribe 'company', user.profile.company
      user = Meteor.user()
      Meteor.autorun =>
         # auto-search ids for companies
         q = search.get()
         role = @params.query.role
         _.extend q, {type:role} if role
         unless user?.isContractor()
            Meteor.call 'quickSearch', q, (err,res)=>
               Alert.new err,'danger' if err
               ids.set(res) if res
      Meteor.autorun =>
         #user = Meteor.user()
         if user?.isBepi()
            # auto-subscribe (limited) 
            companyIds = ids.get()
            if _.isArray(companyIds) and companyIds.length > 0
               Meteor.subscribe 'companies',companyIds, subCb('found companies',debugThis)
      this.next()
   waitOn: ->
      if @params._id
         return Meteor.subscribe 'user', @params._id, subCb('user detail',debugThis)
   data: ->
   	if this.ready() and Meteor.user()
         data = {}
         id = this.params._id
         user = Meteor.users.findOne id
         editRole = this.params.query?.role
         view = this.params.query?.view
         if id and user
            #edit or view
            type = user.roleGroup()
            data =
               email:user.emails[0]?.address
               companyName:user.profile?.companyName
               name:user.profile?.name
               roles:user.roles
               company:user.profile?.company
               city:user.profile?.city
               country:user.profile?.country
               view:this.params.query?.view
               userId:user._id
               schema:"Add#{type}User"
            title = "edit"
            if view then title = "view"
            title2 = "#{user.roles[0]}"
            data.title = title
            data.title2= title2
         else
            #Add
            type = BepiRoles.roleGroup editRole
            data.title = "Add new #{editRole} "
            data.schema= "Add#{type}User"
         _.extend data,
            search: search
            searching: searching
            findCompanies: ->
               qids = ["none"] # dummy valus
               if user.hasCompany()
                  qids.push user.profile.company
               if ids.get()
                  qids = qids.concat ids.get
               q = {_id:{$in:qids}}
               return Companies.find(q).fetch()
         return data

Template.user.helpers
   userType: (role)->  true
   role:-> Router.current().params.query.user

Template.user.events
   "submit #usersForm": (e) ->
      e.preventDefault()

isAdminRemoved = (currentDoc,insertDoc) ->
   user = Meteor.users.findOne currentDoc.userId
   if user.isAdmin()
      intersection= _.intersection insertDoc.roles, BepiRoles.admin
      if intersection.length is 0
         return true
   return false

findRouting = (currentDoc)->
   user = Meteor.users.findOne currentDoc.userId
   if user.isCompanyUser() then return "companies"
   else if user.isContractor() then return "contractors"
   else return "bepi"

editUser = (userId, insertDoc) ->
   Meteor.call "editUser", userId, insertDoc, (e,r) ->
      if e
         Alert.new e.reason, "danger"
      else
         Alert.new  Translation.translate("User_succesfully_edited"), "success"

AutoForm.hooks
   usersForm:
      onSubmit: (insertDoc, updateDoc, currentDoc) ->
         if currentDoc?.userId
            if isAdminRemoved  currentDoc, insertDoc
               msg = Translation.translate "Are_you_sure_you_want_to_delete_this_Admin_Role"
               msg= msg.concat Translation.translate 'The_User_Management_will_no_longer _be_available'
               if Dialog.confirm msg
                  editUser currentDoc.userId, insertDoc
            else
               editUser currentDoc.userId, insertDoc
         else
            Meteor.call "addUser", insertDoc, (e,r) ->
               if e
                  Alert.new e.reason, "danger"
               else
                  Alert.new Translation.translate ("User_succesfully_added"), "success"
         this.done()
         if Roles.userIsInRole this.userId, 'bepi'
            Router.go "usermanagement" , {roles:findRouting currentDoc}
         else
           Router.go "usermanagement"
         return false



