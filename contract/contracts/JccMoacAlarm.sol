pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "jcc-solidity-utils/contracts/owner/Administrative.sol";
import "jcc-solidity-utils/contracts/utils/AddressUtils.sol";
import "jcc-solidity-utils/contracts/list/AlarmList.sol";
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarm.sol";
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarmCallback.sol";

/**
定时任务合约
1. 提供注册定时任务和销毁定时任务的接口
2. 提供合约interface定义
 */
contract JccMoacAlarm is Administrative, IJccMoacAlarm {
  using SafeMath for uint256;
  using AddressUtils for address;
  using AlarmList for AlarmList.alarmMap;

  AlarmList.alarmMap _alarms;

  constructor() Administrative() public {
  }

  function createAlarm(address _addr, uint256 _type, uint256 _begin, uint256 _peroid) public returns (bool) {
    require(_alarms.insert(_addr, msg.sender, _type, _begin, _peroid), "insert alarm successful");

    emit CreateAlarm(_addr, _type, _begin, _peroid);

    return true;
  }

  function removeAlarm(address _addr) public returns (bool) {
    AlarmList.element memory alarm = _alarms.getByAddr(_addr);
    require(alarm.creatorAddr == msg.sender || msg.sender == this.admin(), "remove alarm caller must be creator or admin");

    require(_alarms.remove(_addr), "remove alarm successful");

    emit RemoveAlarm(_addr);

    return true;
  }

  function getAlarmCount() public view returns (uint256) {
    return _alarms.count();
  }

  function getAlarmList(uint256 from, uint256 _count) public view returns (AlarmList.element[] memory) {
    return _alarms.getList(from, _count);
  }

  function execute(address _addr) public {
    // uint256 count = _alarms.count();
    // if (count == 0 ) {
    //   return;
    // }

    // for (uint256 i = 0; i < count; i++) {
    //   AlarmList.element storage alarm = _alarms.get(i);
    //   // 如果是一次性的，检查时间是否到了
    //   // 如果是周期性的，那么计算周期是否到了
    //   // TODO: 因为区块链的出块不精确性，一个任务是否执行过了，需要判别
    //   // 对于一次性任务，可以执行完成后删除定义，周期性的呢，要有记录备查
    //   // 全部在合约里面判断，可信但是燃料太高了，如果这个逻辑放到外部执行，那么笨函数将非常简单
    // }
    // 调用合约的callback，触发定时调用
    AlarmList.element memory e = _alarms.getByAddr(_addr);
    IJccMoacAlarmCallback(e.contractAddr).jccMoacAlarmCallback();
  }
}