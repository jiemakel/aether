'use strict';

describe('Service: VoIDservice', function () {

  // load the controller's module
  beforeEach(module('fi.seco.aether'));

  it('should contain a voidService service',
     inject(function(voidService) {
       expect(voidService).toBeDefined();
     }));
});
