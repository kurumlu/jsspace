debugThis = debug.context 'companies'

defaultLimit = 10
search = new ReactiveVar {}
searching = new ReactiveVar false
companyLists = []

###
# Used for all listings of companies (companies, supplychain, links)
# Type "producer", list (direction) "upstream/downstream/linkable", status: "active/invite".
# companyId is optional, can be undefined (e.g. "My producers")
###
class CompanyList
   constructor: (arg)->
      {@list,@companyId,@type,@status,@template} = arg
      @title = arg.title or "#{@list}_#{@type}_#{@status}" # default title
      @ids = new ReactiveVar undefined
      @limit = new ReactiveVar defaultLimit
      # figure out the title of the section
      # @translation = {invites:'Pending_type_invites',upstream:'Showing_type',downstream:'Downstream_producers'}[@list]
      Meteor.autorun => @runQuery()
      Meteor.autorun =>
         i = @limitedIds()
         if i
            @subscription = Meteor.subscribe 'companies', i, @type, @list, subCb(@title,debugThis,{ids:i})
   runQuery: ->
      Meteor.call @list, @companyId, @type, @status, search.get(), (err,res)=>
         Alert.new err, 'danger' if err
         searching.set(false)
         @ids.set(res) if res
   show: -> _.isArray(@ids.get())
   limitedIds: -> # limits the ids to the amount we're going to show, return undefined if no id array
      i = @ids.get()
      return unless i
      limit = @limit.get()
      i = _.take(i,limit) if limit > 0
      return i
   hasResults: -> @show() and @ids.get().length > 0
   plural: -> plurals[@type]
   company: -> Companies.findOne @companyId # used for linking / delinking
   isLinkable: -> @list is 'linkable'
   data: ->
      i = @ids.get()
      if i
         rowTemplate = "#{@template}_row"
         idx = @limitedIds()
         companies = Companies.find {_id:{$in: idx}},
            sort: {'details.companyName':1}
            transform: (doc)->
               company = new Company(doc)
               company.rowTemplate = rowTemplate # determines the row template used in the results table
               company.context = # used by linking / delinking to determine direction
                  list: @list
                  status: @status
               return company
         data =
            companies: => companies # list of companies
            show: true # if the route is not ready yet, it return false for this value
            hasResults: i.length > 0 # used to show "no results"
            showPager: -> i.length >  @limit.get() # only show the "Show more, etc" if there are more companies than the limit
            showing: => # how many results are we showing? ("Showing ... of ...")
               limit = @limit.get()
               return if limit > 0 then _.min([limit,i.length]) else i.length
            total: i.length # How many resuts were found?
            isInvite: @status is 'invite' # used in the button section
            limit: @limit # used by the pagination to change the number of shown results
            headerTemplate: "#{@template}_header" # used to pick the right header for the table

###
# Base route used by all company listings.
###

route = (config)->
   {path,name,template,panelTitle,title,lists} = config
   Router.route path,
      name: name
      template: template
      onBeforeAction: ->
         search.set {}
         searching.set false
         Translation.addContext 'companies', 'countries', 'general', 'address'
         this.next()
      waitOn: ->
         subs = [CompanyTypes.subscription,Translation.subscription]
         if @params._id
            subs.push Meteor.subscribe 'company', @params._id, subCb('selected company',debugThis,@params)
         return subs
      data: ->
         # wait untill the  router is setup
         user = Meteor.user()
         if this.ready() and user
            type = @params.t
            _id = @params._id
            company = Companies.findOne _id if _id
            companyLists = lists(_id,company,type)
            data =
               title: title(company,type)
               type: type
               company: company
               search: search
               searching: searching
               isSearching: -> searching.get()
               lists: companyLists
            return data
         else
            return {show:->false}

plurals =
   participant: 'participants'
   branch: 'branches'
   supplier: 'suppliers'
   producer: 'producers'

companyTitle = (company)-> "#{company.details.companyName} (#{Translation.translate(company.type)})"

###
# Linked companies of either the supplied company
# or the user's company if not specified.
# AKA Supply Chain Mapping
# AKA "My ..."
###
route
   path: '/companies/:t/:_id?'
   # t can be: participant, supplier, producer
   name: 'companies'
   template: 'companies'
   title: (company,type)->
      if company
         return "Showing #{plurals[type]} for #{companyTitle(company)}"
      else
         return Translation.translate "my_#{plurals[type]}"
   lists: (_id,company,type)->
      companyType = CompanyTypes.findOne type
      activeTemplate = 'companies_active'
      inviteTemplate = 'companies_invite'
      lists = []
      lists.push new CompanyList
         list: 'upstream'
         companyId: _id
         type: type
         status: 'active'
         template: activeTemplate
      if company and (company.type is companyType._id) and companyType.isBidirectional()
         lists.push new CompanyList
            list:'downstream'
            companyId: _id
            type: type
            status:'active'
            template: activeTemplate
      lists.push new CompanyList
         list: 'upstream'
         companyId:_id
         type: type
         status: 'invite'
         template: inviteTemplate
      return lists

# Implementation of #766 and #769:
linkTitle = (company,type,direction)->
   if company.isProducer() and type is 'producer'
      return "#{direction}_#{plurals[type]}"
   else
      return "#{plurals[type]}"

###
# (Visible) companies downstream of the supplied company (_id).
###

route
   path: 'supplychain/:_id',
   name: 'supplychain'
   template: 'supplychain'
   title: (company,type)-> companyTitle(company)
   lists: (_id,company)->
      type = CompanyTypes.findOne(company.type)
      template = 'supplychain'
      lists = []
      _.each type.downstream, (t)->
         lists.push new CompanyList
            list: 'downstream'
            companyId: _id
            type: t
            status: 'active'
            template: template
            title:linkTitle company, t,'downstream'
      _.each type.upstream, (t)->
         lists.push new CompanyList
            list: 'upstream'
            companyId: _id
            type: t
            status: 'active'
            template: template
            title:linkTitle company, t ,'upstream'
      return lists

Template.supplychain.helpers
   'detail': ->
      #+autoForm id="companyProfile" schema=schema type=displayType doc=company.details omitFields=omitFields buttonContent=false
      formConfig =
         company: @company
         schema: @company.companyType().fullSchema()
         displayType: 'readonly'
         omitFields: ['contact.emailConfirm','companyRelation']
         hideRelation:true
         showLanguage:false
      return formConfig


route
   path: 'links/:_id',
   name: 'links'
   template: 'links'
   title: (company,type)-> 
      console.log "#{Translation.translate('Supply_Chain_Links')} - #{companyTitle(company)}"
      return "#{Translation.translate('Supply_Chain_Links')} - #{companyTitle(company)}"
   lists: (_id,company)->
      type = CompanyTypes.findOne(company.type)
      linked = 'links_linked'
      linkable = 'links_linkable'
      lists = []
      _.each type.downstream, (t)->
         lists.push new CompanyList
            list: 'downstream'
            companyId: _id
            type: t
            status: 'all'
            template: linked
            title: linkTitle company, t, 'downstream'
         lists.push new CompanyList
            list: 'linkable'
            companyId: _id
            type: t
            status: 'downstream' # yes, this seems weird, but for 'linkable', this is treated as the status
            template: linkable
      _.each type.upstream, (t)->
         lists.push new CompanyList
            list: 'upstream'
            companyId: _id
            type: t
            status: 'all'
            template: linked
            title: linkTitle company, t, 'upstream'
         lists.push new CompanyList
            list: 'linkable'
            companyId: _id
            type: t
            status: 'upstream'
            template: linkable
      return lists

rerun = (res)->
   _.each (companyLists), (list)->
      if (list.type is res.type) and _.includes([list.list,list.status],res.direction)
         console.log "Rerunning #{list.list} #{list.status} #{list.type}" if debugThis
         list.runQuery()
   $('html,body').animate({scrollTop: $("##{res.type}").offset().top}) # keep the current list in view

Template.companyList.events
   'click #inviteCompany': -> Router.go "company", {type: Router.current().params.t}, {query:"new=true"}

Template.links_list.events
   'click .link': (e,t)->
      link =
         source: @._id
         target: t.data.companyId
         direction: t.data.status
      Meteor.call 'link',link,(err,res)=>
         Alert.new err,'danger' if err
         rerun res # reload lists that have the same type and direction
   'click .delink': (e,t)->
      link =
         source: @._id
         target: t.data.companyId
         targetType: t.data.company().type
         direction: t.data.list
      if Meteor.user().isOwnCompany(link.source)
         _.each companyLists, (list)-> list.subscription.stop() # these will start failing otherwise
      Meteor.call 'delink',link,(err,res)=>
         Alert.new err,'danger' if err
         if Meteor.user().isOwnCompany(link.source)
            Router.go 'companies', {t:link.targetType} # See #761
         else
            rerun res

Template.companies_pager.events
   'click #show_more': (e,t)-> @limit.set(_.min([@total,@limit.get() + 10]))
   'click #show_all': (e,t)-> @limit.set(0)

Template.companyList.onRendered -> $('.messageButton').popover()

Template.companyButtons.events
   'click .closeCompany': ->
      if @status is 'open'  or @status is 'active'
         message =  Translation.translate 'delete_invitation_confirmation'
         if Dialog.confirm message
            Meteor.call 'closeCompany', this._id , (e,r)=>
               if e
                  msg = Translation.translate e.error
                  Alert.new msg, 'danger'
               if r
                  msg = Translation.translate 'company_closed_successfully'
                  Alert.new msg, 'success'

Template.companyLinkButtons.events
   'click .inviteOtherProducers': ->
      user = Meteor.user()
      request =
         senderName: user.profile.name
         senderEmail: user.emails[0].address
         producerName: @.details.contact.name
         companyName:@.details.companyName
      #send email to producer of participants
      producerContact = Meteor.users.findOne {"emails.address":"#{@.details.contact.email}"}
      producer =
         name:"#{@.details.contact.name}"
         email:"#{@.details.contact.email}"
      Meteor.call 'sendMail' , 'inviteOtherProducers' , 'BEPI activity', request, producer ,(err,result) ->
         if err
            Alert.new err, 'danger'
      #send mail to participant
      Meteor.call 'sendMail' , 'inviteOtherProducers' , 'BEPI activity', request, user ,(err,result) ->
         if err
            Alert.new err, 'danger'
         else if result
            message = Translation.translate 'email_to_company_requesting_invite_other_producer', [{noTranslation:"__companyName",with:"#{request.companyName}"}] 
            Alert.new message, 'success'
      return

Template.companyButtons.helpers
   showLinks: ->
      type = Router.current().params?.t
      types =  _.join this, ''
      return Translation.translate 'Show_typesOf_type' , [{replace:"__types",with:"#{types}s"}, {replace:"__type",with:"#{type}"}] or '' 

ownCompany = (companyId)->
   #own company can not be linked so don't list it
   params = Router.current().params
   if params._id is companyId then return true else return false

Template.links_linked_row.helpers
   ownCompany: ->  ownCompany this._id

Template.links_linkable_row.helpers
   ownCompany:-> ownCompany this._id

