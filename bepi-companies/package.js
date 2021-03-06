Package.describe({
  name: 'fta:bepi-companies',
  summary: 'Participant, producers, etc. handling for bepi',
  version: '1.0.0'
});

Package.onUse(function(api) {
   api.use(['coffeescript',
              'tracker',
              'stevezhu:lodash',
              'fta:bepi-translation',
              'mquandalle:jade',
              'templating',
              'mongo',
              'less',
              'iron:router',
              'meteorhacks:ssr',
              'aldeed:autoform-select2',
              'natestrauser:select2',
              'zimme:select2-bootstrap3-css',
              'aldeed:autoform@5.3.2',
              'aldeed:simple-schema',
              'alanning:roles',
              'fta:bepi-core',
              'fta:bepi-search',
              'email',
              'fta:bepi-alerts',
              'fta:bepi-dormants',
              'reactive-var'
          ]);
   api.use(['session@1.1.0'],['client']);
   api.addFiles([
                'lib/companyType.coffee',
                'lib/company.coffee',
                'lib/schemas.coffee',
                'lib/user.coffee'
                ]);
   api.addFiles([
                'server/startup.coffee',
                'server/indexes.coffee',
                'server/company.coffee',
                'server/companyGuard.coffee',
                'server/companies.coffee',
                'server/companyMethods.coffee',
                'server/companyLinkMethods.coffee',
                'server/publish.coffee',
                'server/search.coffee'
                ],'server');
   api.addFiles([
                'client/company.jade',
                'client/supplychain.jade',
                'client/links.jade',
                'client/rsvp.html',
                'client/companySearch.jade',
                'client/companySearch.coffee',
                'client/companies.jade',
                'client/companies.coffee',
                'client/company.coffee',
                'client/helpers.coffee',
                'client/companyInvite.coffee',
                'client/companyLink.jade',
                'client/companyLink.coffee',
                'client/subscriptions.coffee',
                'client/companyErrors.coffee',
                'client/selector.coffee',
                'style/style.less'
                ],'client');
   api.addAssets([
                'assets/companyTypes.json',
                'assets/companies.json',
                'assets/bp_invitations.json'
                ],'server');
   api.addAssets([
                'assets/images/upstream.png',
                'assets/images/downstream.png',
                'assets/images/downstream2.png'
                ],'client');
});

Package.onTest(function(api) {
   api.use(['tinytest',
             'stevezhu:lodash', 
             'coffeescript',
             'meteorhacks:ssr@2.2.0',
             'fta:bepi-companies']);
   api.imply('underscore');
   api.addFiles(['test/mock.coffee','test/company_access.coffee'], 'server');
});
