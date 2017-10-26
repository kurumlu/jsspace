_ = lodash

###
# This "guard" provides helper functions to make sure only the companies
# accessible to a user are in play.
#
# Users, except for producers, can see the details 
# (names, addresses, supply chain, etc) of companies 
# they have an upstream link to. 
# Producers can only see the names of upstream companies they are linked to. 
# All users can only see the names of downstream companies they are connected to.
###

limitedVisibility =
   fields:
      _id: 1
      'details.companyName': 1
      status: 1
      type: 1

regularVisibility =
   fields:
      _id: 1
      details: 1
      status: 1
      type: 1
      link: 1

class @CompanyGuard
   constructor: (@userId,@method)->
      unless @userId
         throw new Meteor.Error "unauthorized", "Not authorized, user needs to be logged in.", @method
      @user = Meteor.users.findOne @userId
   isUserCompany: (_id)-> @user.profile.company is _id
   hasPermission: (type, direction, action)->
      unless @user.hasPermission(type,direction,action)
         throw new Meteor.Error "unauthorized", "User #{@userId} does not have permission to #{action} #{direction} #{type}", @method
   canInvite: (company)-> @canDo(company,'invite')
   canDetail: (company)-> @user.canDetail(company)
   canLink: (upstream,downstream)->
      unless upstream.canLink(downstream)
         throw new Meteor.Error "unlinkable", "Can't link upstream #{upstream.type} to downstream #{downstream.type}", @method
      if upstream.isUpstreamFrom(downstream)
         throw new Meteor.Error "already_linked", "#{upstream.type} (#{upstream._id}) already has a link to #{downstream.type} (#{downstream._id}", @method
   # TODO: check user access to upstream and downstream companies?
   canDelink: (company)-> @canDo(company,'delink')
   canDo: (company,action)->
      unless @user.canDo(company,action)
         throw new Meteor.Error "unauthorized", "User #{@userId} does not have permission to #{action} this company (#{company._id})", @method
   screen: (ids,type)->
      return ids if @user.isBepi()
      return _.intersection ids, @user.visible(type)
   # which fields can a user see?
   fields: (type,direction)->
      unless @user.isBepi()
         check direction, Match.OneOf 'upstream','downstream','linkable'
      if direction is 'linkable'
         return limitedVisibility
      else if @user.hasPermission(type,direction,'detail')
         return regularVisibility
      else
         return limitedVisibility
   # Still used?! 
   init: -> @getIds()
   getCompany: ->
      unless @company
         @company = Companies.findOne(@user.profile.company) if @user.hasCompany()
      return @company
   getIds: -> # upstream ids!
      unless @ids
         if @getCompany()
            # get a list of upstream companies connected to this company
            @ids = Companies.findIds {"link.#{@company.type}":@company._id}
            @ids = ["none"] if _.isEmpty(@ids)
      return @ids
   # @return true if this company can be viewed
   # A user can "view" a company if it is either:
   # - their own company
   # - a downstrean company (limited visibility in all cases)
   # - an upstream company (limited visibility if producer)
   canView: (companyId)->
      if @user.isBepi()
         return true
      else if @user.isContractor()
         #TODO: check if the contractor access to company
         return true
      else
         return true if @user.isOwnCompany(companyId)
         testCompany = Companies.findOne companyId
         return true if _.includes(@getCompany().link?[testCompany.type],testCompany._id) # downstream link
         return _.includes(@getIds(),companyId)
   # modify (Company) query so that only viewable companies are included
   limitQuery: (q)->
      # limits the query to the companies viewable to the user
      unless @user.isBepi()
         _.extend q,
            _id:
               $in: @getIds()
            status:
               $ne: 'closed'
   # Restrict the supplied list to only the viewable company ids
   upstreamOnly: (i)->
      if @user.isBepi()
         return i
      else
         _.intersection @getIds(),i
