pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "jcc-solidity-utils/contracts/owner/Administrative.sol";
import "jcc-solidity-utils/contracts/utils/AddressUtils.sol";
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarm.sol";
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarmCallback.sol";

/**
任务合约
1. 注册预言机回调接口
 */
contract MockAlarmClient is Administrative, IJccMoacAlarmCallback {
  using SafeMath for uint256;
  using AddressUtils for address;

  uint callCounter;
  constructor() Administrative() public {
  }

  function jccMoacAlarmCallback() public {
    // 业务逻辑,调用计数器
    callCounter = callCounter.add(1);
  }

  function getCounter() public view returns (uint) {
    return callCounter;
  }

  function getNum() public view returns (uint) {
    uint percent = 60;
    uint voters = 9;
    uint base = percent.mul(voters);
    uint count = base.div(100);
    count = base.div(100).mul(100) == base ? count : count.add(1);
    return count;
  }

  function setAlarm(address _alarmAddr, uint256 _type, uint256 _period) public onlyPrivileged {
    // type, begin
    IJccMoacAlarm alarm = IJccMoacAlarm(_alarmAddr);
    // 可以检查设置成功与否
    alarm.createAlarm(address(this), _type, block.timestamp, _period);
  }

  function removeAlarm(address alarmAddr) public onlyPrivileged {
    IJccMoacAlarm alarm = IJccMoacAlarm(alarmAddr);
    // 可以检查设置成功与否
    alarm.removeAlarm(address(this));
  }
}