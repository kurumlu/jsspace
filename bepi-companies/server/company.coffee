###
# Helper methods for supply chain related functionality.
# Don't modify this unless you are sure what your are doing!
# Note: these specific will only work properly on the server side
# because users can't always see all companies.
###

_.extend Company.prototype,
   # Is this company downstream from the supplied company?
   isDownstreamFrom: (company) ->
      company = Companies.findOne(company) if _.isString(company)
      _.includes company.link?[@type], @_id
   # permission for specific companies
   canInvite: (company)-> @canDo(company,'invite')
   canDetail: (company)-> @canDo(company,'detail')
   canLink: (company)->
      # since these companies are normally not linked yet
      # we just check type permission
      return @hasPermission(company.type,'downstream','link')
   canDelink: (company)-> @canDo(company,'delink')
   canDo: (company,action)->
      check company, Match.OneOf String,Company
      company = Companies.findOne(company) if _.isString(company)
      direction = undefined
      if @isUpstreamFrom(company)
         direction = 'downstream'
      if @isDownstreamFrom(company)
         direction = 'upstream'
      if direction
         return @hasPermission(company.type,direction,action)
      else
         return false
   'linked.downstream': (type,q={})->
         ids = @link?[type]
         return [] if _.isEmpty(ids)
         # eliminate closed companies:
         return Companies.findIds _.extend q, {_id:{$in:ids},type:type,status:{$ne:'closed'}}
   'linked.upstream': (type)-> Companies.findIds {"link.#{@type}":@_id,type:type,status:{$ne:'closed'}}
   # all companies linked to this company, both up and downstream!
   linked: (type)-> _.union(@["linked.upstream"](type),@["linked.downstream"](type))
   # all companies that can be queried from this company
   # permissions may prohibit a direction
   visible: (type)->
      upstream = []
      downstream = []
      if @hasPermission(type,'upstream','query')
         upstream = @["linked.upstream"](type)
      if @hasPermission(type,'downstream','query')
         q = {"details.invisibleToProducers":{$ne:true}} if @isProducer()
         downstream = @["linked.downstream"](type,q)
      ids = _.union(upstream,downstream) # this also makes sure the lists are unique
      ids.push @_id if @type is type # add the company if it's the same type
      return ids

