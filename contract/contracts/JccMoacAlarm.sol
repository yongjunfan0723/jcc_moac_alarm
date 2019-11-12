pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "jcc-solidity-utils/contracts/owner/Administrative.sol";
import "jcc-solidity-utils/contracts/utils/AddressUtils.sol";
import "jcc-solidity-utils/contracts/list/AlarmList.sol";
import "jcc-solidity-utils/contracts/list/AddressList.sol";
import "jcc-solidity-utils/contracts/list/BalanceList.sol";
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
  using AddressList for AddressList.addressMap;
  using BalanceList for BalanceList.balanceMap;

  AlarmList.alarmMap _alarms;
  // 对允许注册的合约地址做限制
  AddressList.addressMap _acceptAddress;

  // 充值计费
  BalanceList.balanceMap _balances;

  constructor() Administrative() public {
  }

  event Deposit(address indexed _from, address indexed _contractAddr, uint256 indexed _amount);

  // 为某个合约定时任务充值
  function deposit(address _addr) public payable returns (uint256) {
    emit Deposit(msg.sender, _addr, msg.value);
    return _balances.add(_addr, msg.value);
  }

  event Withdraw(address indexed _to, uint256 indexed _amount);

  // 提现到执行钱包中做燃料用
  function withdraw(uint256 _amount) public payable onlyPrivileged {
    emit Withdraw(msg.sender, _amount);
    msg.sender.transfer(_amount);
  }

  // 获取合约的存款
  function balance(address _addr) public view returns (uint256) {
    return _balances.balance(_addr);
  }

  // 注册合约不需要权限
  function addClient(address _addr) public returns (bool) {
    return _acceptAddress.insert(_addr);
  }

  // 移除合约需要权限
  function removeClient(address _addr) public onlyPrivileged returns (bool) {
    return _acceptAddress.remove(_addr);
  }

  // 获取所有客户合约数量
  function getClientCount() public view returns (uint256) {
    return _acceptAddress.count();
  }

  function getClientList(uint256 from, uint256 _count) public view returns (address[] memory) {
    return _acceptAddress.getList(from, _count);
  }

  function createAlarm(address _addr, uint256 _type, uint256 _begin, uint256 _peroid) public returns (bool) {
    require(_acceptAddress.exist(msg.sender), "not accept contract call");
    require(_alarms.insert(_addr, msg.sender, _type, _begin, _peroid), "insert alarm successful");

    emit CreateAlarm(_addr, _type, _begin, _peroid);

    return true;
  }

  function removeAlarm(address _addr) public returns (bool) {
    // 允许注册者和管理员删除
    require(_acceptAddress.exist(msg.sender) || msg.sender == this.admin(), "not accept contract call");
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

  event Balance(address indexed _contractAddr, uint256 indexed _origin, uint256 indexed _cost);

  function execute(address _addr) public onlyPrivileged {
    // 检查余额，防止无意义的消耗 不能小于0.1MOAC
    require((_balances.balance(_addr) > 100000000000000000), "must have enough gas");

    uint256 _gasBefore = gasleft();
    // 调用合约的callback，触发定时调用
    AlarmList.element memory e = _alarms.getByAddr(_addr);

    uint256 gap = block.timestamp.sub(e.begin).mod(e.peroid);

    // 一次性任务直接过，周期性任务时差在两分钟之内都是有效的
    if (e.alarmType == 0 || gap < 120 ) {
      // NEEDFIX:如果这里revert了，会消耗gas但是没有入账
      IJccMoacAlarmCallback(e.contractAddr).jccMoacAlarmCallback();
    }

    // 一次性任务，执行完毕就自动删除定义
    if (e.alarmType == 0) {
      _alarms.remove(e.contractAddr);
    }

    uint256 _gasAfter = gasleft();
    uint256 _cost = (_gasBefore.sub(_gasAfter)).mul(tx.gasprice);
    emit Balance(_addr, _balances.balance(_addr), _cost);
    _balances.sub(_addr, _cost);
    // 周期性任务定义不必删除，为什么不检查区块时间和任务周期关系？
    // 这个逻辑在外部的调用者那里实现，也就是说我们不能期望和保证调用者分秒不差的发起调用
  }
}