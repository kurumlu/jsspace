debugThis = debug.context "companies"

deprecate = ->

if debugThis
   deprecate = (tag)->
      console.log "Deprecated: #{tag}"
      console.trace?()
###
# Note that this class is further extended on the server side!
###
class @Company
   constructor: (doc)-> _.extend @, doc
   producerLinkError: -> return true if @is('producer') and (@link?.supplier?.length or false) < 1 and (@link?.participant?.length or false) < 1 and (@link?.producer?.length or false) < 1 and (@link?.branch?.length or false) < 1
   st: (status)-> @status is status
   subTypes: -> @companyType().subTypes
   # deprecated?
   canEdit: (user=Meteor.user())-> user.canEdit(@)
   canClose: (user=Meteor.user())->
      return false unless user
      return true if @status is 'open'
      return user.is(@companyType().canClose)
   companyType: -> CompanyTypes.findOne @type
   # generalised permissions per type
   hasPermission: (type,direction,action)-> @companyType().hasPermission(type,direction,action)
   # Is this company upstream from the supplied company?
   isUpstreamFrom: (company) ->
      company = Companies.findOne(company) if _.isString(company)
      _.includes @link?[company.type], company._id
   is: (type)-> @type is type
   isParticipant: -> @is 'participant'
   isSupplier: -> @is 'supplier'
   isProducer: -> @is 'producer'
   isBranch: -> @is 'branch'
   statusInfo: ->
      if @status is 'error'
         'invitation_error'
      else
         @status
   equals: (company)-> company?._id is @_id
   # deprecated:
   upstreams: (upstreams)-> _.extend @link ,
      upstream:
         upstreams
   linkableIds: ->
      # Which companies can be linked, copied from this company's supplychain?
      # Note that the company itself also becomes linkable.
      res = [@_id] # own company is always linkable
      _.each @link, (ids,type)-> res = res.concat ids
      return res
   downstreamCompanies: -> linkableIds()

@Companies = new Mongo.Collection 'companies',
   transform: (doc) -> new Company doc

# Returns a list of ids for matching companies, sorted by name:
# TODO: this is a primary candidate to cache!
Companies.findIds = (q)->
   console.log "Querying ids with query #{EJSON.stringify(q)}" if debugThis
   _.map(Companies.find(q,{sort:{'details.companyName':1},fields:{_id:1}}).fetch(),'_id')
