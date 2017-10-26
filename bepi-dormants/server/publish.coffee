debugThis = false

flatten = ( branchObj) ->
   allValues = []
   if _.isEmpty branchObj then return allValues
   else
      branches = _.keys branchObj
      _.each branches, (branch) ->
         producers = branchObj["#{branch}"]["branch"].producer or []
         suppliers = branchObj["#{branch}"]["branch"].suppliers or []
         allValues= allValues.concat branches unless _.isEmpty branches
         allValues= allValues.concat producers unless _.isEmpty producers
         allValues = allValues.concat suppliers unless _.isEmpty suppliers
      return _.uniq _.compact allValues

# Provide a list of dormants that are linked
Meteor.publish 'dormants', (q={}, page=1) ->
   unless this.userId
      # Do not throw error if not logged in yet, 
      # but return undefined. The subscription will not be 'ready'.
      return
   user = Meteor.users.findOne this.userId
   if Roles.userIsInRole user,['assessor','consultant','consultantContact', 'assessorContact','chemicalauditor','chemicalauditorContact', 'testlab', 'testlabContact']
      return []
   else
      limit = 50 * page
      _.assign q, {ActiveDeactive:0}
      if Roles.userIsInRole user, 'bepi'
         console.log "Dormant selection: " if debugThis
         console.log JSON.stringify(q) if debugThis
         return Dormants.find q , {limit:limit} , {SocialAuditNames:0,CertifLinks:0,CertifDates:0} 
      #it is a company user
      userCompany = user.company()
      unless userCompany?.details?.DBID then return []
      else
         dormant = Dormants.findOne DBID:userCompany.details.DBID
         unless dormant?.supplychainLinks then return []
         else
            #it is a dormant user we need to construct the supply chain
            links = []
            producers = dormant.supplychainLinks?.producer or []
            suppliers = dormant.supplychainLinks?.supplier or []
            branch = dormant.supplychainLinks?.branch or []
            #branches = flatten branch
            links = links.concat producers,suppliers, branch
            if _.isEmpty links then return []
            else 
               links = _.uniq _.compact _.without links , dormant.DBID
               if q.DBID
                  #if the requested dormant not in the supply chain list then we sent empty result
                  unless  _.includes links,q.DBID  then return []
                  else
                     #this is a specail case if teh search on DBID and it is included in Supply Chain we sent only that company
                     q= {DBID:q.DBID, ActiveDeactive:0 } 
                     console.log "Dormant selection: " if debugThis 
                     console.log JSON.stringify(q) if debugThis
                     return Dormants.find q, {limit:limit} , {SocialAuditNames:0,CertifLinks:0,CertifDates:0} 
               else
                  #rest of the serach 
                  _.assign q, {DBID:{$in:links}, ActiveDeactive:0} 
                  console.log "Dormant selection: " if debugThis 
                  console.log JSON.stringify(q) if debugThis
                  return Dormants.find q, {limit:limit} , {SocialAuditNames:0,CertifLinks:0,CertifDates:0}  


#TODO: sorted by first with EntityTye then with Company Name
