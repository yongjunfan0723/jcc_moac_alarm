# jcc_moac_alarm

jcc moac alarm 是一个朴素的预言机，就是一个定时执行驱动的合约，用来辅助业务合约的定时任务唤醒操作，任何人都能注册该服务，并充值方便自动驱动调用。

主网合约地址: 0xbf271db47c93aaaf7750174d47ac460edb72aa6e

测试网合约地址: 0xfb8591a66a54d66e80518de71a6509d0e573f9ab

# 如何使用
## DAPP模式
在[TokenPocket](https://www.tokenpocket.pro/)钱包APP中的发现模块，查找JCC墨客朴素预言机，进行合约注册和充值。

## 命令行模式

[jcc moac tool](https://github.com/JCCDex/jcc-moac-tool)安装和使用，请参考官网说明，以下为朴素预言机的使用示例

```bash
# 定时器管理员添加服务的合约
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xbf271db47c93aaaf7750174d47ac460edb72aa6e --method "addContract" --parameters '"客户合约地址"' --gas_limit 55000
```

```bash
# 充值
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xbf271db47c93aaaf7750174d47ac460edb72aa6e --method "deposit" --parameters '"待充值的合约"' --amount 10 --gas_limit 85000
```

```bash
# 查询指定合约的充值余额
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xbf271db47c93aaaf7750174d47ac460edb72aa6e --method "balance" --parameters '"待服务的合约地址"'
```

## 合约接口定义

如果自己写的合约需要jcc moac alarm的服务，合约接口应符合以下要求

```javascript
// 预言机调用客户合约的jccMoacAlarmCallback方法，实现定时驱动
interface IJccMoacAlarmCallback {
  function jccMoacAlarmCallback() external;
}
```

客户合约需要访问预言机合约订阅定时提醒

```javascript
// 客户合约注册定时任务通过createAlarm，取消定时任务通过removeAlarm
// createAlarm建立新定时任务的调用者地址，必须是管理员添加的地址，防止恶意攻击
interface IJccMoacAlarm {
  event CreateAlarm(address indexed contractAddr, uint256 indexed _type, uint256 indexed _begin, uint256 _peroid);
  event RemoveAlarm(address indexed contractAddr);
  event Alarm(address indexed contractAddr, uint256 indexed time);

  function createAlarm(address _addr, uint256 _type, uint256 _begin, uint256 _peroid) external returns (bool);
  function removeAlarm(address _addr) external returns (bool);
}
```

客户合约的例子，请参考[MockAlarmClient.sol](https://github.com/JCCDex/jcc_moac_alarm/blob/master/contract/contracts/mock/MockAlarmClient.sol)

