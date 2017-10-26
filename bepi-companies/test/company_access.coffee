###
#  Test the correct access rights and properties.
###
_ = lodash

loadTestCompanies = ->
   _.each mockCompanies, (company)-> Companies.insert company

loadedCompanies = -> _.reduce mockCompanies,
   (a, mock)->
      a[mock._id] = Companies.findOne(mock._id)
      return a
   , {}

removeTestCompanies = ->
   _.each mockCompanies, (company)-> Companies.remove company._id

TinyTest.add 'Experimental test', (test)->
   loadTestCompanies()
   {participantA} = loadedCompanies()
   test.isTrue participantA.isParticipant(), "Participant test"
   test.isFalse participantA.isProducer(), "Participant is not a producer"
   removeTestCompanies()
   

