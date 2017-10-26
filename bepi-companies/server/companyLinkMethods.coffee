debugThis = true

replyAddress = 'BEPI_Platform@fta-intl.org'

Meteor.methods
   matchCompany: (invitedById,invitedId,companyRelation="upstream") ->
      ###
      # This adds the current users company to the links of the supplied company (id), 
      # establishing an 'upstream' relationship. If upstream is set to false, the 
      # supplied company id is added to the (downstream) links of the users company.
      ###
      check invitedById, String
      check invitedId, String
      invitedCompany = Companies.findOne invitedId
      invitedByCompany = Companies.findOne invitedById
      if invitedCompany and invitedByCompany
         if companyRelation is "upstream" 
            source = invitedByCompany
            target = invitedCompany
         else
            source = invitedCompany
            target = invitedByCompany
         console.log "source: " + EJSON.stringify(source) if debugThis
         console.log "target: " + EJSON.stringify(target) if debugThis
         #unless _.includes target.link[source.type], source._id
         Companies.update target._id,
            $addToSet:
               "link.#{source.type}": source._id
         #link info log
         info =
            linkedAt:new Date()
            linkedBy:this.userId
            linkAction:"link" 
         Companies.update {_id:target._id}, {$addToSet:{"metaData.links.#{source._id}":info}}
         SendLinkAcceptanceMail  invitedByCompany, invitedCompany
      else
         throw new Meteor.Error "not-found"

SendLinkAcceptanceMail = (invitedByCompany, invitedCompany) ->
   lang = invitedByCompany.details?.language or Translation.defaultLanguage
   SSR.compileTemplate 'email', Translate "link_request_accepted_body", lang, {}, true
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
      subject: Translate "link_request_accepted_subject", lang
      html: SSR.render 'email', context
   Email.send mail

companySort =
   sort:
      'details.companyName': 1

