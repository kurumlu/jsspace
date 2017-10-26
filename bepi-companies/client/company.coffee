debugThis = debug.context 'companies'
_ = lodash

###
# Helper function(s) on the client side:
###
_.extend Company.prototype,
   # is this company downstream from the (current) user?
   isDownstream: (user=Meteor.user())->
      return false if user.isBepi()
      return user.company().isUpstreamFrom(@)
   isDownstreamOrOwn: (user=Meteor.user())-> user.isOwnCompany(@) or @isDownstream()
   # WARNING: on the server side, we can only check the type,
   # not if there is a specific link (as we don't publish those).
   # Strict means that we ignore if the type is the same.
   isStrictUpstreamFrom: (company)->
      return false if @type is company.type
      return @companyType().isUpstreamFrom(company.companyType())
   isStrictUpstream: (user=Meteor.user())->
      return true if user.isBepi()
      return @isStrictUpstreamFrom(user.company())
   isStrictUpstreamOrOwn: (user=Meteor.user())-> user.isOwnCompany(@) or @isStrictUpstream()



Router.route '/company/:type/:_id?',
   name: 'company'
   template: 'company'
   onBeforeAction: ->
      Translation.addContext 'countries','companies','company_profile', 'address',  'languages', 'general'
      this.next()
   waitOn: ->
      subs = [CompanyTypes.subscription]
      if @params._id
         subs.push Meteor.subscribe 'company', @params._id, subCb('companies',debugThis)
      return subs
   data: ->
      if this.ready()
         return new CompanyView @params
###
# _id: company we are looking at
# action: 'view', 'edit' or 'insert'
###

class CompanyView
   constructor: (params)->
      {@_id,@type,query} = params
      if @_id
         @company = Companies.findOne @_id
      else
         @company = new Company({type:@type})
      @companyType = @company.companyType()
      @type = @company.type
      @user = Meteor.user()
      @omitFields = []
      if query.edit
         @action = 'edit'
         @omit 'relation'
         if @user?.isBepi() and @company.status is 'open'
            @schema = @companyType.fullSchema()
         else
            @schema = @companyType.simpleSchema()
            @omit 'contact'
      else if query.new
         @action = 'new'
         @schema = @companyType.fullSchema()
         @omit 'relation'
         # unless @user?.company()?.isProducer()
         #    @omit 'relation'
         @showLanguage = true if @company.isProducer()
      else if query.invitation
         @action = 'invitation'
         @schema = @companyType.invitationSchema()
         @showLanguage = true if @company.isProducer()
      else
         @action = 'view'
         @schema = @companyType.fullSchema()
         unless @user?.company()?.isProducer()
            @omit 'relation'
   omit: (section)->
      switch section
         when 'relation'
            @omitFields.push 'companyRelation'
            @hideRelation = true
         when 'contact'
            @omitFields = @omitFields.concat ["contactName","contactEmail","contactEmailConfirm"]
            @hideContact = true
   displayType: -> if @action is 'view' then 'readonly' else 'normal'
   template: -> if @user then 'companyView' else 'companyInvite'

AutoForm.hooks
   companyProfile:
      onSubmit: (insertDoc, updateDoc, currentDoc) ->
         this.event.preventDefault()
         id = Router.current().params._id
         type = Router.current().params.type
         delete insertDoc.contactEmailConfirm
         companyRelation = Router.current().params.query.relation
         dormantActivation = Router.current().params?.query?.dormantActivation
         if insertDoc.contact
            insertDoc.contact.email = insertDoc.contact.email.toLowerCase()
         if insertDoc.DBID then insertDoc.DBID = _.toUpper insertDoc.DBID
         if id
            Meteor.call 'updateCompanyProfile', id, type, insertDoc,dormantActivation, (e,r) ->
               if r
                  alertMsg = Translation.translate 'Successfully_edited_company', [{replace:"__type",with:"#{type}"}]
                  Alert.new alertMsg, "success"
                  if Meteor.user()
                     if dormantActivation then Router.go "companies", {t:type }, {query:'dormantActivation=true'}
                     else if Meteor.user().isBepi() then Router.go "companies", {t:type }
                     else 
                        Router.go "home"
               if e
                  alertMsg1 = Translation.translate e.error
                  alertMsg2 = ""
                  if dormantActivation then alertMsg2 = Translation.translate 'please_try_again_with_another_email'
                  Alert.new "#{alertMsg1}. #{alertMsg2}", "danger"
                  if dormantActivation then  Router.go "dormants"

         else
            invitedBy = []
            invitedBy = _.intersection Meteor.user().roles , ['bepi','producer','supplier','participant','branch','producerAdmin','supplierAdmin','participantAdmin','branchAdmin']
            #if a new branch is invited  a  flag ownProducersVisibleToParticipant will be set to true. This can later change and can become optinal
            if type is 'branch' then _.extend insertDoc, {ownProducersVisibleToParticipant:true}
            #When a producer invited by a branch . we will check this flag and decide  automatically linking to its participant or not
            Meteor.call 'inviteCompany', insertDoc, type, invitedBy[0] ,companyRelation, (e,r) ->
               if r
                  
                  alertMsg = Translation.translate 'Successfully_invited_type_company', [{replace:"__type",with:"#{type}"}]
                  Alert.new alertMsg, "success"
                  alert Translation.translate 'Invitation_email_is_being_sent'
                  #reloading page solves the problem of invitation downstream producers #310 
                  #document.location.reload(true)
                  if Meteor.user()
                     unless type is 'participant' then Router.go "links", {_id:r}
                     else Router.go "companies", {t:type}
               else
                  if e.error is "not-allowed"
                     #bepi can not link companies
                     if Meteor.user().isBepi()
                        message = Translation.translate r.reason, [{replace:"__type",with:"#{type}"}]
                        Router.go 'companies', {t:type}
                        Alert.new message, "danger"
                     else
                        message = Translation.translate 'like_to_link_type_company', [{replace:"__type",with:"#{type}"}]
                        if confirm message
                           user= Meteor.user()
                           Meteor.call 'sendLinkInvitationMail' , insertDoc, user.profile.company, companyRelation, (e,r)->
                              if r
                                 message = Translation.translate 'company_link_request_sent_type_name', [{replace:"__type",with:"#{type}"}, {noTranslation:"__companyName",with:"#{insertDoc.companyName}"}]
                                 Alert.new message, "success"
                              if e
                                 message = Translation.translate 'problem_while_sending_request'
                                 console.log e
                                 Alert.new message, "danger"
                        Router.go 'companies', {t:type}
         $('.modal-backdrop').remove()
         this.done()
         return false
      onError: (operation, result, template) ->
         console.log this
         console.log operation
         console.log result
         console.log template

Template.resendInvite.events
   'click #resendInvite': (e,t) ->
      e.preventDefault()
      type= Router.current().params?.type
      unless type then type = this.company.type
      if type
         Meteor.call 'resendCompanyInvite', this.company._id,  (e,r) ->
            if r
               alertMsg = Translation.translate 'Successfully_invited_type_company', [{replace:"__type",with:"#{type}"}]
               Alert.new alertMsg, "success"
            else
               Alert.new e.reason, "danger"
         Router.go 'companies', {t:type}

Template.companyView.helpers
   formTitle :->
      querry = Router.current().params?.query
      type=Router.current().params?.type
      if type
         if querry.new
            return Translation.translate 'New_type_profile', [{replace:"__type",with:"#{type}"}]
         else if querry.edit
            return Translation.translate 'Edit_type_profile', [{replace:"__type",with:"#{type}"}]
         else return Translation.translate 'type_profile', [{replace:"__type",with:"#{type}"}]
      else
         return ''
   dormantActivation:->
      query = Router.current().params?.query
      dormantActivation = query?.dormantActivation
      if dormantActivation then return true else return false

Template.companyProfileForm.helpers
   buttonVisible:->
      query=Router.current().params?.query
      return query.edit? or query.new?

Template.companyOpenWarning.helpers
   warning: ->
      type = Router.current().params?.type
      if type
         return Translation.translate 'This_type_company_has_not_been_activated', [{replace:"__type",with:"#{type}"}]
      return ''
      





