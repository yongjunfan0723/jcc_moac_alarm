# jcc_moac_alarm

jcc moac alarm 是一个朴素的预言机，就是一个定时执行驱动的合约，用来辅助业务合约的定时任务唤醒操作，任何人都能注册该服务，并充值方便自动驱动调用。

主网合约地址: 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8

测试网合约地址: 0xc87f0b41e26da5919837427e46eb8b2e683380e7

## 如何使用

jcc moac alarm 服务的是需要定时执行的合约，也就是说你的合约需要一个定时触发的调用，而合约本身是不能自动执行的，需要一个外部的输入来驱动，jcc moac alarm 通过标准接口方式可以提供这种服务。

使用这个服务，简单四步即可：

1. 加入 IJccMoacAlarmCallback 接口定义，给自己合约扩展一个驱动接口
2. 在 jcc_moac_alarm 合约中注册需要驱动的合约地址
3. 充值，为驱动者消耗燃料
4. 创建定时回调任务

### 合约接口定义

安装 jcc_solidity_utils

```bash
npm install jcc_solidity_utils
```

在合约代码中引用

```javascript
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarmCallback.sol";
...
// 回调接口实现
function jccMoacAlarmCallback() public {
  // 定时业务逻辑
}
...
```

示例代码请参见我们的测试代码[MockAlarmClient.sol](https://github.com/JCCDex/jcc_moac_alarm/blob/master/contract/contracts/mock/MockAlarmClient.sol)

### 注册服务

用户只需要在 jcc moac alarm 中注册自己的合约（已经实现 jccMoacAlarmCallback）,给出定时要求。有两种方式，一种直接在命令行上调用注册，一种在 DAPP 中，通过人机交互方式注册。

命令行方式使用[jcc_moac_tool](https://github.com/JCCDex/jcc-moac-tool)

```bash
# 添加服务的合约:只有注册的合约地址才能调用预言机创建定时任务
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "addClient" --parameters '"客户合约地址"' --gas_limit 80000

# 删除服务的合约
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "removeClient" --parameters '"客户合约地址"' --gas_limit 100000
```

### 充值

jcc moac alarm 是一个公益性的服务，通过合约方式计算每次的燃料消耗，从用户充值的资产中扣除，因此需要客户进行充值。

```bash
# 充值：朴素预言机发起定时调用前，一般和该合约关联的余额少于0.1MOAC则放弃调用
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "deposit" --parameters '"待充值的合约"' --amount 10 --gas_limit 150000

# 查询指定合约的充值余额
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "balance" --parameters '"待服务的合约地址"'
```

### 创建定时任务

创建定时任务可以从命令行发起，也可以在 DAPP 中操作。

```bash
# 创建定时任务
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "createAlarm" --parameters '"待服务的合约地址",类型(0:一次性, 1:周期性), 开始时间(单位秒), 周期(秒)'

# 查询定时任务数量
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "getAlarmCount"

# 查询定时任务清单
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "getAlarmList" --parameters '起始索引, 数量'

# 删除定时任务
jcc_moac_tool --abi JccMoacAlarm.json --contractAddr 0xf28f3c6c6bd4911d9947c5dfea1c3b4cb09ea7d8 --method "removeAlarm" --parameters '"待服务的合约地址"'
```

除了在 DAPP 中可以操作定时任务的管理之外，也可以在合约中动态创建定时任务，做到这一点，客户合约还需要实现 IJccMoacAlarm 接口。

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

### DAPP 模式

在[TokenPocket](https://www.tokenpocket.pro/)钱包 APP 中的发现模块，查找 JCC 墨客朴素预言机，进行合约注册和充值。

## 多签名钱包执行任务的注册（示例）

```bash
jcc_moac_tool --abi JccMoacMultiSig.json --contractAddr "多签名钱包地址" --method "setAlarm" --parameters '"预言机合约地址",1,600' --gas_limit 200000

```

**_注意事项_**
区块链的出块是否稳定受到很多因素影响，本合约发起执行的时间窗口为 2 分钟，如果合约和高精度时间相关，不建议使用这种方式。
