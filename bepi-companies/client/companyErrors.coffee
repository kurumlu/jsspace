Tracker.autorun ->
	if Meteor.user()
	   companies = Companies.find().fetch()
	   Alert.closeContext "companyError"
	   _.each companies, (company) ->
         ###
         #   check both upstream and downstream
         ###
         upstreamLinks = Companies.find "link.#{company.type}": company._id 
         upstreams = upstreamLinks.fetch()
         if company.status is 'active'
            if company.producerLinkError()
               if !upstreams.length 
                  #Alert.new "Producer #{company.details.companyName} has no participant, supplier or producer associated to it. <a href=\"/link/company/#{company.type}/#{company._id}?edit=true\">Please fix this</a> before continuing.", "danger", 0, "companyError"
                  msg1 = Translation.translate 'Producer_company_has_no_participant_supplier_or_producer_associated' ,  [{noTranslation:"__companyName",with:"#{company.details.companyName}"}] or ''
                  msg2 = "<a href=\"/link/company/#{company.type}/#{company._id}?edit=true\">" 
                  msg3 = Translation.translate 'Please_fix_this_before_continuing' or '' 
                  Alert.new "#{msg1}#{msg2}#{msg3}", "danger", 0, "companyError"
