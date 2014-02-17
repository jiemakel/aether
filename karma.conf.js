// Karma configuration
// http://karma-runner.github.io/0.10/config/configuration-file.html

module.exports = function(config) {
  config.set({
    // base path, that will be used to resolve files and exclude
    basePath: '',

    // testing framework to use (jasmine/mocha/qunit/...)
    frameworks: ['jasmine'],

    // list of files / patterns to load in the browser
    files: [
      'app/bower_components/angular/angular.js',
      'app/bower_components/angular-mocks/angular-mocks.js',
      'app/bower_components/angular-animate/angular-animate.js',
      'app/bower_components/angular-ui-router/release/angular-ui-router.js',
      'app/bower_components/d3/d3.js',
      'app/bower_components/nvd3/nv.d3.js',
      'app/bower_components/angularjs-nvd3-directives/dist/angularjs-nvd3-directives.js',
      'app/bower_components/angular-bootstrap/ui-bootstrap-tpls.js',
      'app/scripts/*/*.coffee',
//      '.tmp/scripts/*/*.js',

      'app/scripts/**/*.coffee',
//      '.tmp/scripts/**/*.js',

      'test/mock/**/*.coffee',
//      '.tmp/test/mock/**/*.js',
      
      'test/spec/**/*.js'
//      '.tmp/test/spec/**/*.js',

//      {pattern: 'app/scripts/**/*.coffee', watched: true, included:false, served: true},
//      {pattern: 'test/mock/**/*.coffee', watched: true, included:false, served: true},      
//      {pattern: 'test/spec/**/*.coffee', watched: true, included:false, served: true},

//      {pattern: '.tmp/scripts/**/*.js.map', watched: true, included:false, served: true},
//      {pattern: '.tmp/mock/**/*.js.map', watched: true, included:false, served: true},      
//      {pattern: '.tmp/spec/**/*.js.map', watched: true, included:false, served: true}
    ],

    // list of files / patterns to exclude
    exclude: [],

    // web server port
    port: 8080,

    // level of logging
    // possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: false,


    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera
    // - Safari (only Mac)
    // - PhantomJS
    // - IE (only Windows)
    browsers: ['Chrome'],


    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: false
  });
};
