/* eslint-disable indent */
/* eslint-disable semi */
/* eslint-disable no-undef */
const JccMoacAlarm = artifacts.require('JccMoacAlarm');
const zeroAccount = require('./helpers/zeroAccount');
const assertRevert = require('./helpers/assertRevert');
const timeTravel = require('./helpers/timeTravel');

contract('JccMoacAlarm', (accounts) => {
  let jccAlarm;
  let admin = accounts[0];

  beforeEach(async () => {
    jccAlarm = await JccMoacAlarm.new({ from: admin });
  });

  it('jcc moac alarm test', async () => {
  });
});
