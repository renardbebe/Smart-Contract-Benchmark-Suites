 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BBODServiceRegistry is Ownable {

   
   
  mapping(uint => address) public registry;

    constructor(address _owner) {
        owner = _owner;
    }

  function setServiceRegistryEntry (uint key, address entry) external onlyOwner {
    registry[key] = entry;
  }
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ManagerInterface {
  function createCustody(address) external {}

  function isExchangeAlive() public pure returns (bool) {}

  function isDailySettlementOnGoing() public pure returns (bool) {}
}

contract Custody {

  using SafeMath for uint;

  BBODServiceRegistry public bbodServiceRegistry;
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor(address _serviceRegistryAddress, address _owner) public {
    bbodServiceRegistry = BBODServiceRegistry(_serviceRegistryAddress);
    owner = _owner;
  }

  function() public payable {}

  modifier liveExchangeOrOwner(address _recipient) {
    var manager = ManagerInterface(bbodServiceRegistry.registry(1));

    if (manager.isExchangeAlive()) {

      require(msg.sender == address(manager));

      if (manager.isDailySettlementOnGoing()) {
        require(_recipient == address(manager), "Only manager can do this when the settlement is ongoing");
      } else {
        require(_recipient == owner);
      }

    } else {
      require(msg.sender == owner, "Only owner can do this when exchange is dead");
    }
    _;
  }

  function withdraw(uint _amount, address _recipient) external liveExchangeOrOwner(_recipient) {
    _recipient.transfer(_amount);
  }

  function transferToken(address _erc20Address, address _recipient, uint _amount)
    external liveExchangeOrOwner(_recipient) {

    ERC20 token = ERC20(_erc20Address);

    token.transfer(_recipient, _amount);
  }

  function transferOwnership(address newOwner) public {
    require(msg.sender == owner, "Only the owner can transfer ownership");
    require(newOwner != address(0));

    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract CustodyStorage {

  BBODServiceRegistry public bbodServiceRegistry;

  mapping(address => bool) public custodiesMap;

   
  uint public custodyCounter = 0;

  address[] public custodiesArray;

  event CustodyRemoved(address indexed custody);

  constructor(address _serviceRegistryAddress) public {
    bbodServiceRegistry = BBODServiceRegistry(_serviceRegistryAddress);
  }

  modifier onlyManager() {
    require(msg.sender == bbodServiceRegistry.registry(1));
    _;
  }

  function addCustody(address _custody) external onlyManager {
    custodiesMap[_custody] = true;
    custodiesArray.push(_custody);
    custodyCounter++;
  }

  function removeCustody(address _custodyAddress, uint _arrayIndex) external onlyManager {
    require(custodiesArray[_arrayIndex] == _custodyAddress);

    if (_arrayIndex == custodyCounter - 1) {
       
      custodiesMap[_custodyAddress] = false;
      emit CustodyRemoved(_custodyAddress);
      custodyCounter--;
      return;
    }

    custodiesMap[_custodyAddress] = false;
     
    custodiesArray[_arrayIndex] = custodiesArray[custodyCounter - 1];
    custodyCounter--;

    emit CustodyRemoved(_custodyAddress);
  }
}
contract Insurance is Custody {

  constructor(address _serviceRegistryAddress, address _owner)
  Custody(_serviceRegistryAddress, _owner) public {}

  function useInsurance (uint _amount) external {
    var manager = ManagerInterface(bbodServiceRegistry.registry(1));
     
    require(manager.isDailySettlementOnGoing() && msg.sender == address(manager));

    address(manager).transfer(_amount);
  }
}

contract Manager is Pausable {
using SafeMath for uint;

mapping(address => bool) public ownerAccountsMap;
mapping(address => bool) public exchangeAccountsMap;

 

enum SettlementPhase {
PREPARING, ONGOING, FINISHED
}

enum Cryptocurrency {
ETH, BBD
}

 
SettlementPhase public currentSettlementPhase = SettlementPhase.FINISHED;

uint public startingFeeBalance = 0;
uint public totalFeeFlows = 0;
uint public startingInsuranceBalance = 0;
uint public totalInsuranceFlows = 0;

uint public lastSettlementStartedTimestamp = 0;
uint public earliestNextSettlementTimestamp = 0;

mapping(uint => mapping(address => bool)) public custodiesServedETH;
mapping(uint => mapping(address => bool)) public custodiesServedBBD;

address public feeAccount;
address public insuranceAccount;
ERC20 public bbdToken;
CustodyStorage public custodyStorage;

address public custodyFactory;
uint public gweiBBDPriceInWei;
uint public lastTimePriceSet;
uint constant public gwei = 1000000000;

uint public maxTimeIntervalHB = 1 weeks;
uint public heartBeat = now;

constructor(address _feeAccount, address _insuranceAccount, address _bbdTokenAddress, address _custodyStorage,
address _serviceRegistryAddress) public {
 
ownerAccountsMap[msg.sender] = true;
feeAccount = _feeAccount;
insuranceAccount = _insuranceAccount;
bbdToken = ERC20(_bbdTokenAddress);
custodyStorage = CustodyStorage(_custodyStorage);
}

function() public payable {}

function setCustodyFactory(address _custodyFactory) external onlyOwner {
custodyFactory = _custodyFactory;
}

function pause() public onlyExchangeOrOwner {
paused = true;
}

function unpause() public onlyExchangeOrOwner {
paused = false;
}

modifier onlyAllowedInPhase(SettlementPhase _phase) {
require(currentSettlementPhase == _phase, "Not allowed in this phase");
_;
}

modifier onlyOwner() {
require(ownerAccountsMap[msg.sender] == true, "Only an owner can perform this action");
_;
}

modifier onlyExchange() {
require(exchangeAccountsMap[msg.sender] == true, "Only an exchange can perform this action");
_;
}

modifier onlyExchangeOrOwner() {
require(exchangeAccountsMap[msg.sender] == true ||
ownerAccountsMap[msg.sender] == true);
_;
}

function isDailySettlementOnGoing() external view returns (bool) {
return currentSettlementPhase != SettlementPhase.FINISHED;
}

function updateHeartBeat() external whenNotPaused onlyOwner {
heartBeat = now;
}

function isExchangeAlive() external view returns (bool) {
return now - heartBeat < maxTimeIntervalHB;
}

function addOwnerAccount(address _exchangeAccount) external onlyOwner {
ownerAccountsMap[_exchangeAccount] = true;
}

function addExchangeAccount(address _exchangeAccount) external onlyOwner whenNotPaused {
exchangeAccountsMap[_exchangeAccount] = true;
}

function rmExchangeAccount(address _exchangeAccount) external onlyOwner whenNotPaused {
exchangeAccountsMap[_exchangeAccount] = false;
}

function setBBDPrice(uint _priceInWei) external onlyExchangeOrOwner whenNotPaused
onlyAllowedInPhase(SettlementPhase.FINISHED) {
if(gweiBBDPriceInWei == 0) {
gweiBBDPriceInWei = _priceInWei;
} else {
 
if(_priceInWei > gweiBBDPriceInWei) {
require(_priceInWei - gweiBBDPriceInWei <= (gweiBBDPriceInWei / 2));
 
} else if(_priceInWei < gweiBBDPriceInWei) {
require(gweiBBDPriceInWei - _priceInWei <= (gweiBBDPriceInWei / 2));
}
gweiBBDPriceInWei = _priceInWei;
}
 
require(now - lastTimePriceSet > 23 hours);

lastTimePriceSet = now;
}

function createCustody(address _custody) external whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) {
require(msg.sender == custodyFactory);
custodyStorage.addCustody(_custody);
}

function removeCustody(address _custodyAddress, uint _arrayIndex) external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.FINISHED) {
custodyStorage.removeCustody(_custodyAddress, _arrayIndex);
}

 
 
 
function withdrawFromManager(uint _amount, address _recipient) external onlyExchangeOrOwner
whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) {
_recipient.transfer(_amount);
}

 
 
 
function withdrawFromCustody(uint _amount, address _custodyAddress,address _recipient) external onlyExchangeOrOwner
whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) {
Custody custody = Custody(_custodyAddress);
custody.withdraw(_amount, _recipient);
}

 
 
 
 
function withdrawTokensFromCustody(address _tokenAddress, uint _amount, address _custodyAddress, address _recipient)
external whenNotPaused onlyAllowedInPhase(SettlementPhase.FINISHED) onlyExchangeOrOwner {
Custody custody = Custody(_custodyAddress);
custody.transferToken(_tokenAddress, _recipient,_amount);
}

 

 
 
function startSettlementPreparation() external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.FINISHED) {
require(now > earliestNextSettlementTimestamp, "A settlement can happen once per day");
require(gweiBBDPriceInWei > 0, "BBD Price cannot be 0 during settlement");

lastSettlementStartedTimestamp = now;
totalFeeFlows = 0;
totalInsuranceFlows = 0;

currentSettlementPhase = SettlementPhase.ONGOING;


startingFeeBalance = feeAccount.balance +
((bbdToken.balanceOf(feeAccount) * gweiBBDPriceInWei) / gwei);

startingInsuranceBalance = insuranceAccount.balance;
}

 
 
 
 
 
 
 
function settleETHBatch(address[] _custodies, int[] _flows, uint _fee, uint _insurance) external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.ONGOING) {

require(_custodies.length == _flows.length);

uint preBatchBalance = address(this).balance;

if(_insurance > 0) {
Insurance(insuranceAccount).useInsurance(_insurance);
}

for (uint flowIndex = 0; flowIndex < _flows.length; flowIndex++) {

 
require(custodiesServedETH[lastSettlementStartedTimestamp][_custodies[flowIndex]] == false);

 
require(custodyStorage.custodiesMap(_custodies[flowIndex]));

if (_flows[flowIndex] > 0) {
 
var outboundFlow = uint(_flows[flowIndex]);

 
if(outboundFlow > 10 ether) {
 
require(getTotalBalanceFor(_custodies[flowIndex]) >= outboundFlow);
}

_custodies[flowIndex].transfer(uint(_flows[flowIndex]));

} else if (_flows[flowIndex] < 0) {
Custody custody = Custody(_custodies[flowIndex]);

custody.withdraw(uint(-_flows[flowIndex]), address(this));
}

custodiesServedETH[lastSettlementStartedTimestamp][_custodies[flowIndex]] = true;
}

if(_fee > 0) {
feeAccount.transfer(_fee);
totalFeeFlows = totalFeeFlows + _fee;
 
require(totalFeeFlows <= startingFeeBalance);
}

uint postBatchBalance = address(this).balance;

 
if(address(this).balance > preBatchBalance) {
uint leftovers = address(this).balance - preBatchBalance;
insuranceAccount.transfer(leftovers);
totalInsuranceFlows += leftovers;
 
require(totalInsuranceFlows <= startingInsuranceBalance);
}
}

 
 
 
 
 
 
function settleBBDBatch(address[] _custodies, int[] _flows, uint _fee) external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.ONGOING) {
 

require(_custodies.length == _flows.length);

uint preBatchBalance = bbdToken.balanceOf(address(this));

for (uint flowIndex = 0; flowIndex < _flows.length; flowIndex++) {

 
require(custodiesServedBBD[lastSettlementStartedTimestamp][_custodies[flowIndex]] == false);
 
require(custodyStorage.custodiesMap(_custodies[flowIndex]));

if (_flows[flowIndex] > 0) {
var flowValue = ((uint(_flows[flowIndex]) * gweiBBDPriceInWei)/gwei);

 
require(flowValue >= 1);

 
if(flowValue > 10 ether) {
 
require((getTotalBalanceFor(_custodies[flowIndex]) / 2) >= flowValue);
}

bbdToken.transfer(_custodies[flowIndex], uint(_flows[flowIndex]));

} else if (_flows[flowIndex] < 0) {
Custody custody = Custody(_custodies[flowIndex]);

custody.transferToken(address(bbdToken),address(this), uint(-(_flows[flowIndex])));
}

custodiesServedBBD[lastSettlementStartedTimestamp][_custodies[flowIndex]] = true;
}

if(_fee > 0) {
bbdToken.transfer(feeAccount, _fee);
 
totalFeeFlows += ((_fee * gweiBBDPriceInWei) / gwei);
require (totalFeeFlows <= startingFeeBalance);
}

uint postBatchBalance = bbdToken.balanceOf(address(this));

 
require(postBatchBalance <= preBatchBalance);
}

 
function finishSettlement() external whenNotPaused onlyExchangeOrOwner
onlyAllowedInPhase(SettlementPhase.ONGOING) {
 
earliestNextSettlementTimestamp = lastSettlementStartedTimestamp + 23 hours;

currentSettlementPhase = SettlementPhase.FINISHED;
}

function getTotalBalanceFor(address _custody) internal view returns (uint) {

var bbdHoldingsInWei = ((bbdToken.balanceOf(_custody) * gweiBBDPriceInWei) / gwei);

return _custody.balance + bbdHoldingsInWei;
}

function checkIfCustodiesServedETH(address[] _custodies) external view returns (bool) {
for (uint custodyIndex = 0; custodyIndex < _custodies.length; custodyIndex++) {
if(custodiesServedETH[lastSettlementStartedTimestamp][_custodies[custodyIndex]]) {
return true;
}
}
return false;
}

function checkIfCustodiesServedBBD(address[] _custodies) external view returns (bool) {
for (uint custodyIndex = 0; custodyIndex < _custodies.length; custodyIndex++) {
if(custodiesServedBBD[lastSettlementStartedTimestamp][_custodies[custodyIndex]]) {
return true;
}
}
return false;
}
}