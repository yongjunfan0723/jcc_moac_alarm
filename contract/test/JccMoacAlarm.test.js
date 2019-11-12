/* eslint-disable indent */
/* eslint-disable semi */
/* eslint-disable no-undef */
const JccMoacAlarm = artifacts.require('JccMoacAlarm');
const MockAlarmClient = artifacts.require('MockAlarmClient');
const zeroAccount = require('./helpers/zeroAccount');
const assertRevert = require('./helpers/assertRevert');
const timeTravel = require('./helpers/timeTravel');

contract('JccMoacAlarm', (accounts) => {
  let jccAlarm;
  let alarmClient;
  let alarmAdmin = accounts[1];
  let clientAdmin = accounts[2];

  beforeEach(async () => {
    jccAlarm = await JccMoacAlarm.new({ from: alarmAdmin });
    alarmClient = await MockAlarmClient.new({ from: clientAdmin });
  });

  it('jcc moac alarm test once', async () => {
    await jccAlarm.addClient(alarmClient.address, { from: alarmAdmin });
    await jccAlarm.deposit(alarmClient.address, { from: accounts[3], value: web3.utils.toWei('1') })

    // client 注册一个一次性任务 30分钟后执行一次
    await alarmClient.setAlarm(jccAlarm.address, 0, 30 * 60, { from: clientAdmin });

    // 查询这个一次性任务，找出延时
    let count = await jccAlarm.getAlarmCount();
    let all = await jccAlarm.getAlarmList(0, count);
    // console.log(count, all.length, all[0].alarmType, all[0].begin, all[0].peroid);
    assert.equal(all[0].alarmType, '0', "一次性任务");
    // let a = await alarmClient.getNum();
    // console.log('----', a.toNumber());

    // 模拟延时
    // 这个时间只是区块链的时间偏移，和测试现实的Date.now不是一回事
    await timeTravel(Number(all[0].peroid));

    // 调用任务
    jccAlarm.execute(alarmClient.address, { from: alarmAdmin });
    let gas = await jccAlarm.balance(alarmClient.address);
    assert.isBelow(Number(web3.utils.fromWei(gas)), 1, "消耗了一点gas");

    let counter = await alarmClient.getCounter();
    assert.equal(counter.toNumber(), 1, "计数一次");

    // 延时再次调用
    await timeTravel(Number(all[0].peroid));

    count = await jccAlarm.getAlarmCount();
    assert.equal(count, 0, "自动删除没有定时任务了");

    counter = await alarmClient.getCounter();
    assert.equal(counter.toNumber(), 1, "计数一次");
  });

  it('jcc moac alarm test', async () => {
    await jccAlarm.addClient(alarmClient.address, { from: alarmAdmin });
    await jccAlarm.deposit(alarmClient.address, { from: accounts[3], value: web3.utils.toWei('1') })

    // client 注册一个周期性性任务 30分钟执行一次
    await alarmClient.setAlarm(jccAlarm.address, 1, 30 * 60, { from: clientAdmin });

    // 查询这个一次性任务，找出延时
    let count = await jccAlarm.getAlarmCount();
    let all = await jccAlarm.getAlarmList(0, count);
    // console.log(count, all.length, all[0].alarmType, all[0].begin, all[0].peroid);
    assert.equal(all[0].alarmType, '1', "周期性任务");

    // 模拟延时
    // 这个时间只是区块链的时间偏移，和测试现实的Date.now不是一回事
    await timeTravel(Number(all[0].peroid) + 20);

    // 调用任务
    jccAlarm.execute(alarmClient.address, { from: alarmAdmin });
    let gas = await jccAlarm.balance(alarmClient.address);
    assert.isBelow(Number(web3.utils.fromWei(gas)), 1, "消耗了一点gas");

    let counter = await alarmClient.getCounter();
    assert.equal(counter.toNumber(), 1, "计数一次");

    // 延时再次调用
    await timeTravel(Number(all[0].peroid));

    count = await jccAlarm.getAlarmCount();
    assert.equal(count, 1, "有定时任务了");

    jccAlarm.execute(alarmClient.address, { from: alarmAdmin });
    counter = await alarmClient.getCounter();
    assert.equal(counter.toNumber(), 2, "计数两次");
  });
});
