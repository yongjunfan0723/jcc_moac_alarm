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

  bool callFlag;
  constructor() Administrative() public {
  }

  function jccMoacAlarmCallback() public {
      // 业务逻辑，自我检查状态，执行自己的逻辑
    if (!callFlag) {
      callFlag = true;
    }
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