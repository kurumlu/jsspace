debugThis = false

# @ftp = Npm.require('ftp')
# fs = Npm.require('fs')
# uuid = Npm.require('uuid/v1')

# ftpParams = Meteor.settings.dormantsFTP

# bsciDataType =
#    BSCIData:
#       startHour:2
#       startMin:0
#    SupplyChain:
#       startHour:2
#       startMin:30   
#    BranchesData:
#       startHour:3
#       startMin:0

Meteor.startup ->
   Dormants._ensureIndex 'DBID'
   Dormants._ensureIndex 'BepiStatus'
   # if ftpParams
   #    _.each ['BSCIData','SupplyChain', 'BranchesData'], (type) ->
   #       waitTillIntervalTime type

# waitTillIntervalTime = Meteor.bindEnvironment (type)->
#    now = new Date()
#    millisTill12 = new Date(now.getFullYear(), now.getMonth(), now.getDate(), bsciDataType["#{type}"].startHour,bsciDataType["#{type}"].startMin, 0, 0) - now
#    if  millisTill12 < 0 then millisTill12 += 86400000
#    switch type
#       when 'BSCIData'
#          Meteor.setTimeout setIntervalBSCIDataUpdate, millisTill12, (e,r) ->
#             if e then console.log  e
#          console.log "interval for BSCIData wil be initiated within #{millisTill12} ms."
#       when 'SupplyChain'
#          Meteor.setTimeout setIntervalSupplyChainUpdate,  millisTill12, (e,r)->
#             if e then console.log  e
#          console.log "interval for SupplyChain wil be initiated within #{millisTill12} ms."
#       when 'BranchesData'
#          Meteor.setTimeout setIntervalBranchesDataUpdate,  millisTill12, (e,r)->
#             if e then console.log  e 
#          console.log "interval for BranchesData wil be initiated within #{millisTill12} ms."


# setIntervals = Meteor.bindEnvironment (type) ->
#    console.log "#{new Date()} - Setting interval time for #{type}"
#    Meteor.setInterval ((type)-> 
#       if type is 'BranchesData' then processBranchesData()
#       else ProcessFile type
#    ), 86400000

# setIntervalBSCIDataUpdate = -> 
#    setIntervals 'EntitiesProfiles' 
#    ProcessFile 'EntitiesProfiles'

# setIntervalSupplyChainUpdate = -> 
#    setIntervals 'SupplyChain' 
#    ProcessFile 'SupplyChain'

# setIntervalBranchesDataUpdate = -> 
#    setIntervals 'BranchesData'
#    processBranchesData()

# matchCertificates = (bsciData) ->
#    if bsciData.SocialAuditNames
#       certificates=[]
#       names = bsciData.SocialAuditNames.split('~')
#       links = bsciData.CertifLinks.split('~')
#       dates = bsciData.CertifDates.split('~')
#       index=0
#       _.each names, (name) ->
#          certificate = 
#             name:name
#             date:dates[index++]
#             link:links[index++]
#          certificates.push certificate
#       return certificates
#    return

# logToStatus = Meteor.bindEnvironment (error, message) ->
#    status = Status.findOne {}
#    if status
#       dormantError =
#          id: uuid()
#          error: error
#          message: message
#          date:new Date()
#          processed:false
#       Status.update status._id, {$addToSet:{"dormantErrors":dormantError}}

# logAnError = Meteor.bindEnvironment (error, message) ->
#    logToStatus error, message
#    console.error message if message
#    console.error error

# processEntitiesData = Meteor.bindEnvironment (filename)->
#    fs.readFile  filename, 'utf8', Meteor.bindEnvironment((err, data) ->
#       if err 
#          if err.code is "ENOENT"
#             logAnError err, "#{new Date()} - Entities file #{filename} does not exist." 
#             #console.log "#{new Date()} - Entities file #{filename} does not exist." 
#          else
#             logAnError err, "#{new Date()} - error while reading Entities file: #{filename}(error code:#{err.code})." 
#             #console.log "#{new Date()} - error while reading Entities file: #{filename}(error code:#{err.code})." 
#          return false
#       else
#          json = Papa.parse data,
#             header:true
#             skipEmptyLines:true
#          console.log "Total number of received BSCI Entities record(s): #{json.data.length}" 
#          _.each json.data ,(bsciData)->
#             #DBID should be always in capital
#             bsciData.DBID = _.toUpper bsciData.DBID 
#             bsciData.DBID = _.split( bsciData.DBID ,'S')[0] 
#             dormant = Dormants.findOne DBID:bsciData.DBID
#             if dormant
#                #existing dormant account
#                unless dormant.BepiStatus is 'active'
#                   #update only if the dormant is not yet activated in the BEPI platform and new record  modified later then existing record
#                   if dormant["DateTimeModified"] < bsciData["DateTimeModified"]
#                      bsciData.BepiStatus= 'deactive'
#                      bsciData.supplychain = dormant.supplychain
#                      #create links for certificates
#                      certificates = matchCertificates bsciData
#                      if certificates
#                         bsciData.Certificates = certificates
#                      bsciData.EntityType = Number(bsciData.EntityType) 
#                      #ActiveDeactive should be a boolean
#                      bsciData.ActiveDeactive = Number(bsciData.ActiveDeactive) 
#                      bsciData.DateTimeModified = Number(bsciData.DateTimeModified ) 
#                      bsciData.LinkedParticipants = Number(bsciData.LinkedParticipants)
#                      #each new record has BepiStatus deactive
#                      updateObj = {$set:bsciData}
#                      #remove _id and hashKey object to be able to update entire  object without specifiying one by one
#                      delete updateObj["$set"]["_id"]
#                      delete updateObj["$set"]["$$hashKey"]
#                      Dormants.update {_id:dormant._id}, updateObj
#                      console.log "A dormant account with DBID: #{bsciData.DBID} is updated"
#                else 
#                   console.log  "Company with  DBID number #{bsciData.DBID} is a  dormant company but it is already activated in  BEPI platform"  if debugThis              
#             else
#                #new dormant account
#                company = Companies.findOne {"details.DBID":bsciData.DBID}
#                unless company
#                   #create links for certificates
#                   certificates = matchCertificates bsciData
#                   if certificates
#                      bsciData.Certificates = certificates
#                   #EntityType should be a number
#                   bsciData.EntityType = Number(bsciData.EntityType)
#                   #ActiveDeactive should be a boolean
#                   bsciData.ActiveDeactive = Number(bsciData.ActiveDeactive)
#                   bsciData.DateTimeModified = Number(bsciData.DateTimeModified ) 
#                   bsciData.LinkedParticipants = Number(bsciData.LinkedParticipants)
#                   #each new record has BepiStatus deactive
#                   bsciData.BepiStatus= 'deactive'
#                   Dormants.insert bsciData  
#                   #only process if the company does not exist in BEPI
#                   console.log "A new dormant account with DBID: #{bsciData.DBID} was inserted" 
#                else
#                   console.log  "Company with  DBID number #{bsciData.DBID} does not exist in dormants collection but it is active as BEPI company" if debugThis              
#          return true)

# processSupplyChainData = Meteor.bindEnvironment (filename)->
#    fs.readFile  filename, 'utf8', Meteor.bindEnvironment((err, data) ->
#       if err 
#          if  err.code is "ENOENT"
#             logAnError err, "#{new Date()} - Supply Chain file #{filename} does not exist." 
#          else
#             logAnError err, "#{new Date()} - error during reading  Supply Chain file: #{filename}(error code:#{err.code})."
#          return false
#       else
#          json = JSON.parse(data)
#          _.each json, (links)->
#             participantId=_.keys links
#             newSuppliers=[]
#             directProducers=[]
#             if links["#{participantId[0]}"]
#                newSuppliers = _.keys links["#{participantId[0]}"]["1"]
#                directProducers = links["#{participantId[0]}"]["0"]
#             indirectProducers= []
#             _.each newSuppliers, (supplier)->
#                if links["#{participantId[0]}"]["1"]
#                   indirectProducers = indirectProducers.concat links["#{participantId[0]}"]["1"]["#{supplier}"] 
#             newProducers= _.uniq _.compact directProducers.concat indirectProducers
#             participant = Dormants.findOne DBID:participantId[0]
#             if participant
#                # Either the company active in BEPI or not ,  supply chain data should be updated
#                # unless participant.ActiveDeactive  or participant.BepiStatus is 'deactive'
#                #    console.log "Participant with DBID #{participant.DBID} has either not active or it is activated in BEPI. Its supply chain will not be updated"
#                # else
#                #
#                #newProducers are the direct producers + supplier's producers of the Participant
#                Dormants.update DBID:participant.DBID, {$addToSet:{"supplychainLinks.producer":{$each:newProducers}}} unless _.isEmpty newProducers
#                #newSuppliers are the suppliers of teh Participant
#                Dormants.update DBID:participant.DBID, {$addToSet:{"supplychainLinks.supplier":{$each:newSuppliers}}} unless _.isEmpty newSuppliers

#                console.log "Supply chain links of participant with DBID #{participant.DBID} is updated." if debugThis
#                #update links of suppliers too
#                unless  _.isEmpty newSuppliers
#                   _.each newSuppliers, (supplierId)->
#                      suppliersProducers = links["#{participantId[0]}"]["1"]["#{supplierId}"]  or []
#                      unless  _.isEmpty suppliersProducers 
#                         if _.isArray suppliersProducers
#                            supplier = Dormants.findOne DBID:supplierId
#                            unless supplier then console.log  "Supplier  with DBID #{supplierId} is not  found" 
#                            else
#                               Dormants.update DBID:supplierId, {$addToSet:{"supplychainLinks.producer":{$each:suppliersProducers}}} unless _.isEmpty suppliersProducers
#                               console.log "Supplier #{supplierId}'s producers link is updated." if debugThis
#                         else
#                           console.log  "Supplier  with DBID #{supplierId} has no valid producers list. "
#                           console.log  suppliersProducers                        
#             else
#                console.log "Participant with DBID #{participantId[0]} does not exist. Its supply chain will not be updated." 
#          return true)

# processBranchesData =  ->
#    participants = Dormants.find({EntityType:1 }).fetch()
#    _.each participants, (participant) ->
#       if participant.ParentID isnt ""
#          dormant = Dormants.findOne {DBID:participant.ParentID }
#          if dormant
#             branches=[]
#             if dormant.supplychainLinks?.branch then branches= dormant.supplychainLinks.branch
#             branches.push participant.DBID
#             branches=  _.uniq _.compact branches
#             Dormants.update {DBID:dormant.DBID} ,{$set:{"supplychainLinks.branch":branches}}
#             console.log "Supply chain links of a participant with DBID #{dormant.DBID} is updated. Linked branches: #{branches}"
#    console.log  "#{new Date()} - Processing branches  data is completed."     


# #filetype is 'SupplyChain' or 'EntitiesProfiles
# ProcessFile = (filetype)->
#    if ftpParams
#       try
#          # connect to FTP server
#          connection = new ftp()
#          # check if entities data ready
#          date = new Date()
#          month = date.getMonth()+1
#          if month < 10
#             month = "0#{month}"
#          day = date.getDate()
#          if day < 10
#             day = "0#{day}"
#          startsWithText = "#{date.getFullYear()}-#{month}-#{day}"
#          if filetype is 'SupplyChain'
#             endsWithText = "BEPIParticipants#{filetype}.txt"
#          else if filetype is 'EntitiesProfiles'
#             endsWithText = "#{filetype}.csv"
#          else
#             throw "'#{filetype}'' is not a correct filetype. Possible values are: 'SupplyChain' or 'EntitiesProfiles'."
#          dataFileName = ""
#          console.log "#{new Date()} - Connecting to FTP Server."
#          connection.on 'ready', ()->
#             connection.list (err, list) ->
#                if err  
#                   logAnError err, "#{new Date()} - File list can not be retrieved from FTP Server"
#                   throw new Meteor.Error 'not-found', "#{new Date()} - File list can not be retrieved from FTP Server", err
#                ready = false
#                _.each list , (file)->
#                   if _.startsWith file.name, startsWithText
#                      if _.endsWith file.name, endsWithText
#                         dataFileName = file.name
#                #dataFileName = dataFileName.split(".")[0]
#                eofFile = "#{dataFileName.split(".")[0]}.EOT"
#                _.each list, (file) ->
#                   if file.name is "#{dataFileName.split('.')[0]}.EOT" 
#                      ready  = true
#                if ready
#                   #download entities data to local file
#                   connection.get dataFileName,(err,stream)->
#                      unless err 
#                         if stream
#                            stream.once 'close' , () ->
#                               console.log "File #{dataFileName} is downloaded to local directory." if debugThis
#                               #delete .eof file
#                               connection.delete eofFile , (err) ->
#                                  if err
#                                     logAnError err, "#{new Date()} - Problem with deleting #{eofFile}" 
#                               # always close connection at last 
#                               connection.end()
#                               console.log "#{new Date()} - FTP connection closed." if debugThis
#                               if filetype is 'EntitiesProfiles'
#                                  processEntitiesData dataFileName
#                               else
#                                  processSupplyChainData dataFileName
#                               #whenever Entities or SupplyChain File handled. We need to go through for the branches
#                            #update database entities recods
#                            stream.pipe fs.createWriteStream(dataFileName) 
#                      else
#                         logAnError err, "File: #{dataFileName} does not exist. Update aborted."
#                else
#                   logAnError "File #{eofFile} not found." 
#                   connection.end() if connection
#          try 
#             connection.connect ftpParams
#          catch error
#             logAnError error, "Error connecting to FTP client"
#       catch error
#          logAnError error, "Error during updating Supply Chain Data: #{error}"
#          if connection
#             connection.end()
#    else
#       logAnError "FTP server is unknown. Please check FTP settings."

replyAddress = 'BEPI_Platform@fta-intl.org'

dormantsLog = (message) ->
   DormantsStatus.insert
      type: 'log'
      date: new Date()
      message: message

entityType =
   1:"participant"
   2:"producer"
   3:"supplier"

dormantLinks = (dormant) ->
   producers = dormant.supplychainLinks?.producer or []
   suppliers = dormant.supplychainLinks?.supplier or []
   return producers.concat suppliers

dormantUpstreamLinks = (dormant, dormantBepiId, userId) ->
   #find if there are companies already active in BEPI 
   type = entityType[dormant.EntityType]
   activeDormants = Dormants.find({BepiStatus:"active", "supplychainLinks.#{type}":dormant.DBID}).fetch()
   bepiCompany = Companies.findOne {_id:dormantBepiId}
   _.each activeDormants, (active) ->
      company = Companies.findOne {"details.DBID":active.DBID}
      if company 
         Companies.update {_id:dormantBepiId}, {$addToSet:{"link.#{company.type}":company._id}}
         #link data during Dormant activation is not neccessary. There is already a record as invitedBy 
         # linkData = 
         #    linkedAt:new Date()
         #    linkedBy:userId
         #    linkAction:"link" 
         # Companies.update {_id:dormantBepiId}, {$set:{"metaData.links.#{company._id}":linkData}}

updateCompanyLink = (type, id, company, userId) ->
   Companies.update company._id, {$addToSet:{"link.#{type}":id}}
   linkData =
      linkedAt:new Date()
      linkedBy:userId
      linkAction:"link" 
   result = Companies.update company._id, {$addToSet:{"metaData.links.#{id}":linkData}}

bepiProductGroupMapping =
   "Cocoa and cocoa preparations":"Food, beverages, tobacco"
   "Coffee and coffee preparations":"Food, beverages, tobacco"
   "House appliances":"House appliance"
   "Honey (both natural and blended)":"Food, beverages, tobacco"
   "Clocks and watches":"Household, office furniture, furnishings"
   "Fragrances":"Beauty, personal care and hygiene"
   "Optic, eye and prosthesis":"Health care"
   "Vegetal oils and margarines":"Food, beverages, tobacco"
   "Cereals (Including soy), leguminosae and their products":""
   "Oil, fuels and gas production":"Fuel, gases"
   "Other live animals products":"Pet care, food"
   "Eggs and eggs preparations":"Food, beverages, tobacco"
   "Building products":"Building products"
   "Safety production - DIY":"Safety production - DIY"
   "Baby care":"Baby care"
   "Lubricants":"Lubricants"
   "Office furniture":"Household, office furniture, furnishings"
   "Bathroom appliances":"Plumbing/heating/ventilation/Air conditioning"
   "Meat products (fresh and frosen":""
   "Flowers and ornemental flowers":"Lawns and garden supplies"
   "Dairy products (including butter)":""
   "Sugar and sugar confectionery":"Food, beverages, tobacco"
   "Other agriculture products":""
   "Pets, animal and pets food":"Pet care, food"
   "Lawns and garden supplies":"Lawns and garden supplies"
   "Fresh fruits and vegetables":""
   "Herbs and spices (including tobacco leaves)":""
   "Alcoholic beverage and spirits":"Food, beverages, tobacco"
   "Furnitures":"Household, office furniture, furnishings"
   "Other construction item":"Building products"
   "Personal beauty, hygiene and care (including alternative beauty products)":"Beauty, personal care and hygiene"
   "Electrical supplies":"Electrical supplies"
   "Jewellery":"Personal accessories"
   "Sports equipment":"Sport equipment"
   "Other chemical products":""
   "Audio, visual and photography":"Audio, visual and photography"
   "Other cosmetic products":"Beauty, personal care and hygiene"
   "Livestock":""
   "Other food productrs":"Food, beverages, tobacco"
   "Nuts and nuts prearations":"Food, beverages, tobacco"
   "Textuel and printed materials":"Textual, printed, reference materials"
   "Handbags, belts and shoes":"Personal accessories"
   "Games":"Toys/Games"
   "Processed fruits and vegetables":"Food, beverages, tobacco"
   "Non alcoholic beverages (including soft drinks and water)":"Food, beverages, tobacco"
   "First aid and wound care":"Health care"
   "Cleaning and hygiene products":"Cleaning and hygiene products"
   "Households":"Household, office furniture, furnishings"
   "Bathroom and kitchen ustensils":"Kitchen merchandise"
   "Tools equipment - Power":"Tools equipment - Power"
   "Kitchen merchandise":"Kitchen merchandise"
   "Glassware (eyewear)":"Health care"
   "Arts, craft and needlework":"Arts, craft and needlework"
   "Tranport and automotive":"Automotive"
   "Handbags, belts and shoes":"Personal accessories"
   "Other engineering":"House appliance"
   "Other fishery":""
   "Toys":"Toys/Games"
   "Other plastic and articles thereof":"Building products"
   "Sportswear":"Sport equipment"
   "PVC":"Building products"
   "Footwear (includind sports shoes)":"Footwear"
   "Pharmacy products":"Health care"
   "Other soft goods":"Household, office furniture, furnishings"
   "Safety/security/surveillance":"Safety/security/surveillance"
   "Home textiles":"Household, office furniture, furnishings"
   "Other health products":"Health care"
   "Other sports equipment":"Sport equipment"
   "Fish, crustaceans and molluscs (fresh and frozen)":""
   "Juices and vinegar":"Food, beverages, tobacco"
   "Apparel":"Clothing"
   "Forestry derivates":"Building products"
   "Metal production":"Building products"
   "Other accessories":"Personal accessories"
   "Roots and tubers (inlcuding potatoes)":""
   "Plumbing/heating/ventilation/Air conditioning":"Plumbing/heating/ventilation/Air conditioning"
   "Agrochemicals and pesticides":"Cleaning and hygiene products"
   "Alternative health products":"Health care"
   "Personal accessories":"Personal accessories"
   "Accessories":"Pet care, food"
   "Others":""
   "others (please specify)":""
   "Other plastic like products (please specify)":""


Meteor.methods
   # #allows updating BSCI data manually 
   # ProcessFile : (name)-> ProcessFile  name
   # processAllBSCI: ->
   #    console.log "######################"
   #    console.log "# Starting BSCI sync #"
   #    console.log "######################"
   #    ProcessFile 'EntitiesProfiles'
   #    ProcessFile 'SupplyChain'
   #    processBranchesData()
   # #this script will be run only ones when BSCI integration release 
   # addDBIDfieldsforCompanies : () -> 
   #    companies = Companies.find({}).fetch()
   #    _.each companies,(company)->
   #       unless company.details.DBID
   #          company.details.DBID = ""
   #          id = company._id
   #          updateObj = {$set:company}
   #          #remove _id and hashKey object to be able to update entire  object without specifiying one by one
   #          delete updateObj["$set"]["_id"]
   #          delete updateObj["$set"]["$$hashKey"]
   #          Companies.update {_id:id}, updateObj
   #          console.log "DBID field is added for Company: #{company.details.companyName} " if debugThis
   addDBIDfieldsForSites : () -> 
      sites = Sites.find({}).fetch()
      _.each sites,(site)->
         unless site.DBID
            site.DBID = ""
            id = site._id
            updateObj = {$set:site}
            #remove _id and hashKey object to be able to update entire  object without specifiying one by one
            delete updateObj["$set"]["_id"]
            delete updateObj["$set"]["$$hashKey"]
            Sites.update {_id:id}, updateObj
            console.log "DBID field is added for Site: #{site.siteName} " if debugThis

   activateDormant: (dormantId) ->
      dormant = Dormants.findOne(dormantId)
      #check if it is already in the system 
      dormantsLog "Activation request for DBID #{dormant.DBID}"
      company = Companies.findOne {"details.DBID":dormant.DBID}
      companyContact = Meteor.users.findOne {"emails.address":dormant.ContactEmail}
      site = Sites.findOne {"DBID":dormant.DBID}
      user = Meteor.user()
      userLanguage = Meteor.user().profile.language or 'en'
      if company  or companyContact or site
         throw new Meteor.Error 'dormant_can_not_be_activated' 
      else
         #create company
         address =
            street:dormant.Address1
            city:dormant.City
            state:dormant.State
            zip:dormant.Zip
            country:dormant.Country
         contact =
            name:dormant.ContactName
            email:dormant.ContactEmail
         #link to producer_site_systems_and_processes
         producer_site_systems_and_processes = 
            site_classification:bepiProductGroupMapping[dormant.ProductGroup]
            notUsed:false
         details = 
            companyName:dormant.EntityName
            address:address
            contact:contact
            DBID:dormant.DBID
            producer_site_systems_and_processes:producer_site_systems_and_processes
         invitedBy = 
            date:new Date()
            userId:this.userId
            name:user.profile.name
            email:user.emails[0].address

         type = entityType["#{dormant.EntityType}"]
         if  type is 'participant' and dormant.ParentID   then  type = "branch"
         company =
            type:type
            details:details
            invitedBy:invitedBy
            status:"open"
            #metaData:metaData

         unless user.isBepi()
            userCompany = user.company()
            company.link =
               "#{userCompany.type}": [userCompany._id]
         companyId = Companies.insert company

         #update if new companies link already active in BEPI
         links = dormantLinks dormant
         unless _.isEmpty links 
            companies = Companies.find({"details.DBID":{$in:links}}).fetch()
            _.each companies, (company)->
               dormantsLog "Company links will be updated _id #{company._id}"
               updateCompanyLink  type, companyId, company, user._id

         #update the link of the new activated company if it has already active supply chain links in BEPI
         dormantUpstreamLinks dormant, companyId, user._id

         if companyId
            dormantsLog "Dormant company DBID #{dormant.DBID} is activated. Created BEPI company _id #{companyId}" 
            #SendInviteMail companyId, 'invites', "#{dormant.ContactName} - BEPI <#{replyAddress}>", dormant.ContactEmail, invitedBy
            #console.log "invitation mail for the new company #{dormant.EntityName} is sent to  contact person #{dormant.ContactName}." if debugThis
            #change status in Dormant collections
            dormant = Dormants.update dormant._id, {$set:{BepiCompanyId:companyId, activatedBy:invitedBy, BepiStatus:"active"}}
            return companyId
         else
            throw new Meteor.Error "bcsi_activation_not_completed"
   addADormant: (dormant) ->
      if dormant.DBID
         exist = Dormants.findOne {DBID:dormant.DBID}
         unless exist
            id = Dormants.insert dormant
            dormantsLog "New Dormant account DBID #{id} is created"
         else
            dormantsLog "There is already a dormant account with the same DBID #{dormant.DBID}. Dormant will not be created."
   scanActiveDormants: () ->
      companies = Companies.find().fetch()
      _.each companies, (company)->
         if company.details.DBID and  company.details.DBID isnt ""
            dormant = Dormants.findOne {DBID:company.details.DBID}
            if dormant
               Dormants.update {DBID:company.details.DBID}, {$set:{BepiStatus:"active"}}
               dormantsLog "Dormant DBID #{dormant.DBID} is activated."
   foundDormantResults: (userId, selector={}) ->
      unless this.userId
         return 
      user = Meteor.users.findOne userId
      if user.isContractor()
         return 
      else
         _.assign selector, {ActiveDeactive:0}
         if user.isBepi()
            return Dormants.find(selector).count()
         #it is a company user
         userCompany = user.company()
         unless userCompany?.details?.DBID then return 
         else
            dormant = Dormants.findOne DBID:userCompany.details.DBID
            unless dormant.supplychainLinks then return 
            else
               links = []
               producers = dormant.supplychainLinks.producer or []
               suppliers = dormant.supplychainLinks.supplier or []
               links = links.concat producers,suppliersProducers
               if _.isEmpty links then return 
               else
                  _.assign selector, {DBID:{$in:links}}
                  return Dormants.find(selector).count()
   # processBranchesData: -> processBranchesData()
   # dormantErrorProcessed: (dormantErrorId, processed=true) ->
   #    status = Status.findOne {}
   #    if status?.dormantErrors
   #       counter = 0
   #       _.each status.dormantErrors , (err) ->
   #          if err.id is dormantErrorId 
   #             obj = status.dormantErrors["#{counter}"]
   #             obj.processed = processed
   #             Status.update {_id:status._id} , {$set:{"dormantErrors.#{counter}":obj}}
   #          else
   #             counter++
