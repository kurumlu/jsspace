
debugThis = false

replyAddress = 'BEPI_Platform@fta-intl.org'

SendCompanyMail = (companyId, mailType, from, invitedBy, userId=null) ->
   #if there is a userId filed it is a resending of an invitation mail
   #but this time it should be invited by current user
   check companyId, String
   check mailType, String
   console.log companyId if debugThis
   console.log mailType if debugThis
   console.log invitedBy if debugThis
   company = Companies.findOne {_id:companyId}
   companyType = CompanyTypes.findOne {type:company.type}
   company.domain = process.env.BEPI_URL
   lang = company.details?.language or Translation.defaultLanguage

   SSR.compileTemplate 'email', Translate invitedBy+"_"+mailType+"_"+company.type+"_body", lang, {}, true
   if userId
      user = Meteor.users.findOne userId
      type = "re#{mailType}"
      company.invitedBy.name = user.profile.name
      company.invitedBy.email = user.emails[0].address

   to = []
   _.each companyType.emails[mailType].to, (receiver) ->
      if receiver is 'self'
         to.push company.details.contact.email
      else if receiver is 'invitedBy'
         to.push company.invitedBy?.email
      else if receiver is 'user'
         if userId and user
            to.push user.emails[0].address
   mail =
      to: to
      from: from
      subject: Translate invitedBy+"_"+mailType+"_"+company.type+"_subject", lang
      html: SSR.render 'email', company
   Email.send mail

SendCompanyLinkMail = (invitedCompany, invitedByCompany, companyRelation) ->
   lang = invitedCompany.details?.language or Translation.defaultLanguage
   SSR.compileTemplate 'email', Translate invitedByCompany.type+"_links_"+invitedCompany.type+"_body", lang, {}, true
   bepi =
      name:"BEPI Team"
      email:"BEPI_Platform@fta-intl.org"
   context=
      invited:invitedCompany
      invitedBy:invitedByCompany
      bepi:bepi
      domain:process.env.BEPI_URL
      relation: -> if companyRelation then return "?relation=#{companyRelation}" else return 
   mail =
      to: [invitedCompany.details.contact.email]
      from: "BEPI #{replyAddress}"
      subject: Translate invitedByCompany.type+"_links_"+invitedCompany.type+"_subject", lang
      html: SSR.render 'email', context
   Email.send mail

SendCompanyLinkRequestCancelledMail = (invitedByCompany, invitedCompany) ->
   lang = invitedByCompany.details?.language or Translation.defaultLanguage
   SSR.compileTemplate 'email', Translate "link_request_cancelled_body", lang, {}, true
   bepi =
      name:"BEPI Team"
      email:"BEPI_Platform@fta-intl.org"
   context=
      invited:invitedCompany
      invitedBy:invitedByCompany
      bepi:bepi
      domain:process.env.BEPI_URL
   mail =
      to: [invitedByCompany.details.contact.email]
      from: "BEPI #{replyAddress}"
      subject: Translate "link_request_cancelled_subject", lang
      html: SSR.render 'email', context
   Email.send mail

contactEmailExist = (updateDoc, dormantDBID) ->
   result = true
   if dormantDBID and updateDoc.contact?.email
      #dormant activation
      company = Companies.findOne {"details.contact.email":updateDoc.contact.email}
      unless company
         user = Meteor.users.findOne {"emails.address":updateDoc.contact.email}
         if user then result = false
      else
         if company.details?.DBID isnt dormantDBID then result = false
   return result

Meteor.methods
   inviteCompany: (details, type , invitedBy, companyRelation)->
      check details, Object
      check type, String
      check invitedBy , String
      console.log (JSON.stringify(details)) if debugThis
      console.log type if debugThis
      user = Meteor.user()
      language = user.profile?.language or "en"
      unless Roles.userIsInRole user, CompanyTypes.findOne({type:type}).canInvite
         error = Translation.translations.findOne 'You_do_not_have_correct_rights_to_invite'
         throw new Meteor.Error "unauthorized", {msg:error["#{language}"],company:company}
      # duplicate checking:
      company = Companies.findOne {"details.contact.email":details.contact.email}, {fields:{'details.contact':1,'details.address':1,'details.companyName':1,_id:1,type:1}}
      if company
         throw new Meteor.Error "not-allowed",'Indicated_company_exists_as_a_company'
      existingUser = Meteor.users.findOne {"emails.address":details.contact.email}
      if existingUser
         company = Companies.findOne {_id:existingUser.profile.company}, {fields:{'details.contact':1,'details.address':1,'details.companyName':1,_id:1,type:1}}
         throw new Meteor.Error "not-allowed",'A_user_with_the_same_email_address_already_exists'
      # no duplicates found, generating invite:
      downstream = false
      if companyRelation is 'downstream'
         downstream = true
      delete details.companyRelation
      delete details.contact.emailConfirm
      #if type is 'producer' and invitedBy is 'branch'then  _.extend details, {brach}
      doc =
         type: type
         details: details
         invitedBy:
            date: new Date()
            userId: Meteor.userId()
            name: user.profile.name
            email: user.emails[0].address
         status: "open"
      # link the current user's company:
      user = Meteor.users.findOne this.userId
      if user 
         userCompany = Companies.findOne user.profile.company
         if userCompany and !downstream    
            doc.link =
               "#{userCompany.type}": [userCompany._id]
      console.log "user company: " + (JSON.stringify(userCompany)) if debugThis
      console.log "doc: " + (JSON.stringify(doc)) if debugThis
      # insert and send invite:
      companyId = Companies.insert doc

      #if a branch inviting a producer . Check if the producer should be linked to its particpants/branches
      #if BEPI inviting a producer and like to link to a branch , this should be handled by updateCompanyLinks 
      if userCompany and type is "producer" and invitedBy is "branch" 
         branchLinking = new AutomaticBranchLinking()
         branchLinking.automaticLinking(userCompany._id,companyId,"link")

      if downstream
         company = Companies.findOne {"details.companyName":details.companyName}
         Companies.update userCompany._id,
            $push:
               "link.#{type}": company._id
      SendCompanyMail companyId, 'invites', "#{user.profile.name} - BEPI <#{replyAddress}>", invitedBy
      return companyId
   resendCompanyInvite: (companyId) ->
      check companyId, String
      company = Companies.findOne {_id:companyId}
      user = Meteor.users.findOne this.userId
      from =  "BEPI <#{replyAddress}>"
      if Roles.userIsInRole Meteor.user(), ['bepi','producer','producerAdmin','supplier','supplierAdmin','participant','participantAdmin','branch','branchAdmin']
         invitedByRole = user.roles[0]
         if _.includes invitedByRole , "Admin" then invitedByRole = invitedByRole.split("Admin")[0]
         SendCompanyMail company._id, 'invites', from, invitedByRole, this.userId
      else
         throw new Meteor.Error 'User_not_found' 
      return company._id
   updateCompanyProfile: (id, type, updateDoc, dormantActivation=null) ->
      check id, String
      check type, String
      check updateDoc, Object
      if updateDoc.contact?.emailConfirm then delete updateDoc.contact.emailConfirm
      company = Companies.findOne({_id:id})
      if company.status is 'open' and not Meteor.userId()
         # Accepting invitation
         if Meteor.users.findOne({'emails.address':company.details.contact.email.toLowerCase()})
            throw new Meteor.Error 'A_user_with_the_same_email_address_already_exists'
         else
            options =
               email: company.details.contact.email.toLowerCase()
               profile:
                  name: company.details.contact.name
               roles: [company.type,"#{company.type}Admin"]
            options.profile.company = company._id
            options.profile.companyName = company.details.companyName
            Accounts.sendEnrollmentEmail Accounts.createUser options
         Companies.update {_id:company._id}, {$set: {status: 'active'}}
      else
         unless this.userId
            throw new Meteor.Error 'You_need_to_be_logged_in' 
         user = Meteor.users.findOne this.userId
         #only during a dormant activation , Participants or suppliers can  edit the producers  profile
         unless dormantActivation
            unless Roles.userIsInRole this.userId, CompanyTypes.findOne({type:type}).canEdit 
               throw new Meteor.Error 'You_are_not_authorized_to_perform_this_action'

      modifier = prefix updateDoc, 'details'

      #check if the contact email already exist in database as a user or as a company contact
      nonexist = contactEmailExist updateDoc , dormantActivation
      if nonexist then Companies.update {_id:id},{$set: modifier}
      else
         #same contact person exist in BEPI so we have to fall back
         Companies.remove {"details.DBID":dormantActivation}
         Dormants.update {DBID:dormantActivation}, {$set:{BepiStatus:"deactive"}}
         Dormants.update {DBID:dormantActivation}, {$unset:{BepiCompanyId:1,activatedBy:1}}
         throw new Meteor.Error 'A_user_with_the_same_email_address_already_exists'

      #if the companyName is changed then you need to update the user collection as well
      obj= _.pick modifier , "details.companyName"
      unless _.isEmpty obj
         newName = obj["details.companyName"]
         Meteor.users.update {"profile.company":company._id}, {$set:{"profile.companyName":newName}}

      if dormantActivation
         invitedBy = Meteor.user()
         invitedByCompany = Companies.findOne invitedBy.profile.company
         roles = _.intersection user.roles, ['bepi','producer','supplier','participant','producerAdmin','supplierAdmin','participantAdmin','branch','branchAdmin']
         invitedBy = _.split roles[0], 'Admin'
         SendCompanyMail id, 'invites', "BEPI <#{replyAddress}>", invitedBy[0]
         #change status in Dormant collections
         dormant = Dormants.update {DBID:company.details.DBID}, {$set:{BepiStatus:"active"}}
         console.log "invitation mail for the new company #{dormant.EntityName} is sent to  contact person #{company.details.contact.name}(#{company.details.contact.email})."
         #if a branch invites a producer then this should be automaticall concceted to its participant
         if invitedByCompany?.type is "branch" and  company.type is "producer"
            branchLinking = new AutomaticBranchLinking()
            branchLinking.automaticLinking(invitedByCompany._id,company._id,"link")
      return true
   rejectInvitation: (message,companyId)->
      check companyId, String
      check message, String
      rejected =
         rejectedAt:new Date()
         rejectMessage:message
      Companies.update companyId,
         $set:
            status: 'rejected'
            "metaData.rejected":rejected
      # TODO: email?
   sendLinkInvitationMail: (invited, invitedById, companyRelation) ->
      check invited, Object
      check invitedById, String
      unless Meteor.user().isCompanyUser()
          throw new Meteor.Error 'you_dont_have_rights_to_link'
      invitedCompany = Companies.findOne {"details.contact.email":invited.contact.email}
      if invitedCompany
         invitedByCompany = Companies.findOne invitedById
         if invitedByCompany
            SendCompanyLinkMail invitedCompany, invitedByCompany, companyRelation
            console.log "Company #{invitedByCompany.details.companyName}  has sent a company link request to #{invitedCompany.type} #{invitedCompany.details.companyName}."
            return true
         else
            throw new Meteor.Error "not-found","No company found for id #{invitedById}"
      else
         throw new Meteor.Error "not-found","No company found for email #{invited.contact.email}"
   linkRequestCancelled: (invitedByCompany, invitedCompany) ->
      check invitedByCompany, Object
      check invitedCompany, Object
      SendCompanyLinkRequestCancelledMail invitedByCompany, invitedCompany
      console.log "#{invitedCompany.type} #{invitedCompany.details.companyName} cancelled  link request from #{invitedByCompany.type} #{invitedByCompany.details.companyName}" 
   closeCompany: (companyId) ->
      # #TODO:  delete the link data of the company
      # #what to do with the users of the company
      # #what to do with sites, and form sections
      check companyId, String
      company = Companies.findOne companyId
      if company
         user = Meteor.user()
         #only BEPI can close the company
         if user.isBepi()
            closed =
               closedAt:new Date()
               closedBy:Meteor.userId()
            #if it is an active company remove its contact from user database
            if company.status is "active"
               Meteor.users.update {"emails.address":company.details.contact.email}, {$set:{"roles":["inactive"], "emails.0":[{"address":"removed@removed.com",verified:false}]}}
            #log closing info, remove contact email
            Companies.update {_id:companyId} ,{$set:{status:'closed', "metaData.closed":closed, "details.contact.email":"removed@removed.com"}}
         else if user.isCompanyUser()
               userCompany = user.company()
               delink =
                  linkedAt:new Date()
                  linkedBy:Meteor.userId()
                  linkAction:"delink"
               #cancel downstream link
               if company.link?["#{userCompany.type}"]
                  Companies.update {_id:company._id}, {$pull:{"link.#{userCompany.type}":userCompany._id}, $addToSet:{"metaData.links.#{userCompany._id}":delink}}
               #cancel upstream link
               if userCompany.link?["#{company.type}"]
                  Companies.update {_id:userCompany._id}, {$pull:{"link.#{company.type}":company._id}, $addToSet:{"metaData.links.#{company._id}":delink}}
         else
            throw new Meteor.Error 'not_allowed' 
      else
         throw new Meteor.Error 'company_not_found' 
      return true

   setInvisibleToProducersFlag: (companyId, value=true)->
      unless Roles.userIsInRole this.userId, ['bepi']
         throw new Meteor.Error 'unauthorized'
      check companyId, String
      check value, Boolean
      company = Companies.findOne companyId
      if company
         Companies.update {_id:companyId}, {$set:{"details.invisibleToProducers":value}}
         console.log "Visible to Producer flag is set to #{value} for the company #{companyId}"
      else
         throw new Meteor.Error "company not found"






