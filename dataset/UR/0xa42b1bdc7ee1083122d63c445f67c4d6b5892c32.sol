 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Haltable is Ownable {
  bool public halted = false;

  modifier inNormalState {
    require(!halted);
    _;
  }

  modifier inEmergencyState {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner inNormalState {
    halted = true;
  }

   
  function unhalt() external onlyOwner inEmergencyState {
    halted = false;
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Burnable is StandardToken {
  using SafeMath for uint;

   
  event Burn(address indexed from, uint value);

  function burn(uint _value) returns (bool success) {
    require(_value > 0 && balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint _value) returns (bool success) {
    require(_from != 0x0 && _value > 0 && balances[_from] >= _value);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Burn(_from, _value);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    require(_to != 0x0);  

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    require(_to != 0x0);  

    return super.transferFrom(_from, _to, _value);
  }
}

 
contract QuantorToken is Burnable, Ownable {

  string public constant name = "Quant";
  string public constant symbol = "QNT";
  uint8 public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 2000000000 * 1 ether;

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }


   
  function QuantorToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }


   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);

     
    releaseAgent = addr;
  }

  function release() onlyReleaseAgent inReleaseState(false) public {
    released = true;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);
    transferAgents[addr] = state;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

  function burn(uint _value) onlyOwner returns (bool success) {
    return super.burn(_value);
  }

  function burnFrom(address _from, uint _value) onlyOwner returns (bool success) {
    return super.burnFrom(_from, _value);
  }
}

contract InvestorWhiteList is Ownable {
  mapping (address => bool) public investorWhiteList;

  mapping (address => address) public referralList;

  function InvestorWhiteList() {

  }

  function addInvestorToWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && !investorWhiteList[investor]);
    investorWhiteList[investor] = true;
  }

  function removeInvestorFromWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && investorWhiteList[investor]);
    investorWhiteList[investor] = false;
  }

   
  function addReferralOf(address investor, address referral) external onlyOwner {
    require(investor != 0x0 && referral != 0x0 && referralList[investor] == 0x0 && investor != referral);
    referralList[investor] = referral;
  }

  function isAllowed(address investor) constant external returns (bool result) {
    return investorWhiteList[investor];
  }

  function getReferralOf(address investor) constant external returns (address result) {
    return referralList[investor];
  }
}

contract PriceReceiver {

  address public ethPriceProvider;

  modifier onlyEthPriceProvider() {
    require(msg.sender == ethPriceProvider);
    _;
  }

  function receiveEthPrice(uint ethUsdPrice) external;

  function setEthPriceProvider(address provider) external;
}

contract QuantorPreSale is Haltable, PriceReceiver {

  using SafeMath for uint;

  string public constant name = "Quantor Token ICO";

  QuantorToken public token;

  address public beneficiary;

  InvestorWhiteList public investorWhiteList;

  uint public constant QNTUsdRate = 1;  

  uint public ethUsdRate;

  uint public btcUsdRate;

  uint public hardCap;

  uint public softCap;

  uint public collected = 0;

  uint public tokensSold = 0;

  uint public weiRefunded = 0;

  uint public startTime;

  uint public endTime;

  bool public softCapReached = false;

  bool public crowdsaleFinished = false;

  mapping (address => uint) public deposited;

  uint public constant PRICE_BEFORE_SOFTCAP = 65;  
  uint public constant PRICE_AFTER_SOFTCAP = 80;  

  event SoftCapReached(uint softCap);

  event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);

  event NewReferralTransfer(address indexed investor, address indexed referral, uint tokenAmount);

  event Refunded(address indexed holder, uint amount);

  modifier icoActive() {
    require(now >= startTime && now < endTime);
    _;
  }

  modifier icoEnded() {
    require(now >= endTime);
    _;
  }

  modifier minInvestment() {
    require(msg.value.mul(ethUsdRate).div(QNTUsdRate) >= 50000 * 1 ether);
    _;
  }

  modifier inWhiteList() {
    require(investorWhiteList.isAllowed(msg.sender));
    _;
  }

  function QuantorPreSale(
    uint _hardCapQNT,
    uint _softCapQNT,
    address _token,
    address _beneficiary,
    address _investorWhiteList,
    uint _baseEthUsdPrice,

    uint _startTime,
    uint _endTime
  ) {
    hardCap = _hardCapQNT.mul(1 ether);
    softCap = _softCapQNT.mul(1 ether);

    token = QuantorToken(_token);
    beneficiary = _beneficiary;
    investorWhiteList = InvestorWhiteList(_investorWhiteList);

    startTime = _startTime;
    endTime = _endTime;

    ethUsdRate = _baseEthUsdPrice;
  }

  function() payable minInvestment inWhiteList {
    doPurchase();
  }

  function refund() external icoEnded {
    require(softCapReached == false);
    require(deposited[msg.sender] > 0);

    uint refund = deposited[msg.sender];

    deposited[msg.sender] = 0;
    msg.sender.transfer(refund);

    weiRefunded = weiRefunded.add(refund);
    Refunded(msg.sender, refund);
  }

  function withdraw() external icoEnded onlyOwner {
    require(softCapReached);
    beneficiary.transfer(collected);
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  function calculateTokens(uint ethReceived) internal view returns (uint) {
    if (!softCapReached) {
      uint tokens = ethReceived.mul(ethUsdRate.mul(100)).div(PRICE_BEFORE_SOFTCAP);
      if (softCap >= tokensSold.add(tokens)) return tokens;
      uint firstPart = softCap.sub(tokensSold);
      uint  firstPartInWei = firstPart.mul(PRICE_BEFORE_SOFTCAP).div(ethUsdRate.mul(100));
      uint secondPartInWei = ethReceived.sub(firstPart.mul(PRICE_BEFORE_SOFTCAP).div(ethUsdRate.mul(100)));
      return firstPart.add(secondPartInWei.mul(ethUsdRate.mul(100)).div(PRICE_AFTER_SOFTCAP));
    }
    return ethReceived.mul(ethUsdRate.mul(100)).div(PRICE_AFTER_SOFTCAP);
  }

  function receiveEthPrice(uint ethUsdPrice) external onlyEthPriceProvider {
    require(ethUsdPrice > 0);
    ethUsdRate = ethUsdPrice;
  }

  function setEthPriceProvider(address provider) external onlyOwner {
    require(provider != 0x0);
    ethPriceProvider = provider;
  }

  function setNewWhiteList(address newWhiteList) external onlyOwner {
    require(newWhiteList != 0x0);
    investorWhiteList = InvestorWhiteList(newWhiteList);
  }

  function doPurchase() private icoActive inNormalState {
    require(!crowdsaleFinished);

    uint tokens = calculateTokens(msg.value);

    uint newTokensSold = tokensSold.add(tokens);

    require(newTokensSold <= hardCap);

    if (!softCapReached && newTokensSold >= softCap) {
      softCapReached = true;
      SoftCapReached(softCap);
    }

    collected = collected.add(msg.value);

    tokensSold = newTokensSold;

    deposited[msg.sender] = deposited[msg.sender].add(msg.value);

    token.transfer(msg.sender, tokens);
    NewContribution(msg.sender, tokens, msg.value);
  }

  function transferOwnership(address newOwner) onlyOwner icoEnded {
    super.transferOwnership(newOwner);
  }
}