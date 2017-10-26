debugThis = false

###
# Probably deprecated.
###


class @CompanySelector
   constructor: (@user,@params)->
      # company can be either the current company (by id)
      # or the users' company
      if @params._id
         @company = Companies.findOne this.params._id
         check @company, Company
         console.log "Selected company w id: #{EJSON.stringify(@company)}" if debugThis
      else
         if @user.isBepi()
            console.log 'bepi user found' if debugThis
         if @user.isCompanyUser()
            @company = Companies.findOne @user.profile.company
            if @company
               console.log "Selected user company: #{EJSON.stringify(@company)}" if debugThis
            else
               console.log "Company not found? #{@user.profile.company}" if debugThis
            # check @company, Company
   # only select downstream if the chosen company is a producer
   showDownstream: -> @company and @company.type is 'producer' and @company.link?.producer?
   # search by (optional) name, plus type
   basic: ->
      type: @params.t
   basicUpstream: ->
      selector = @basic()
      # never select the users' own company:
      if @user.hasCompany()
         selector._id =
            $ne: @user.profile.company
      # if a company is set (see constructor),
      # only upstream companies for this company are selected
      if @company
         selector["link.#{@company.type}"] = @company._id
      return selector
   upstream: -> _.extend @basicUpstream(), {status:'active'}
   basicDownstream: -> {_id:{$in: @company.link?.producer}} if @showDownstream()
   downstream: -> _.extend(@basicDownstream(),{status:'active'}) if @showDownstream()
   invites: ->
      status = {status:{$in:['open','rejected','error'] }}
      if @showDownstream()
         return _.extend status,
            $or:
               [
                  @basicUpstream()
                  @basicDownstream()
               ]
      else
         return _.extend status, @basicUpstream()
