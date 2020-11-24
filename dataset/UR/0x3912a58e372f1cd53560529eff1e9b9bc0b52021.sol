 

pragma solidity ^0.4.13;
 

 
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

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is ERC20 {

  using SafeMath for uint;

   
  mapping (address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool) {
    return true;
  }

   
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[_from] >= _value && allowed[_from][_to] >= _value);
    allowed[_from][_to] = allowed[_from][_to].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
   
  function approve(address _spender, uint _value) returns (bool success) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}



 
contract Ownable {
  address public owner = msg.sender;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


contract EmeraldToken is StandardToken, Ownable {

  string public name;
  string public symbol;
  uint public decimals;

  mapping (address => bool) public producers;

  bool public released = false;

   
  modifier onlyProducer() {
    require(producers[msg.sender] == true);
    _;
  }

   
  modifier canTransfer(address _sender) {
    if (_sender != owner)
      require(released);
    _;
  }

  modifier inProduction() {
    require(!released);
    _;
  }

  function EmeraldToken(string _name, string _symbol, uint _decimals) {
    require(_decimals > 0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

     
    producers[msg.sender] = true;
  }

   
  function setProducer(address _addr, bool _status) onlyOwner {
    producers[_addr] = _status;
  }

   
  function produceEmeralds(address _receiver, uint _amount) onlyProducer inProduction {
    balances[_receiver] = balances[_receiver].add(_amount);
    totalSupply = totalSupply.add(_amount);
    Transfer(0, _receiver, _amount);
  }

   
  function releaseTokenTransfer() onlyOwner {
    released = true;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool) {
     
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 
contract Haltable is Ownable {
  bool public halted = false;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

 

contract TokenDistribution is Haltable {

  using SafeMath for uint;

  address public wallet;                 
  uint public presaleStart;              
  uint public start;                     
  uint public end;                       
  EmeraldToken public token;             
  uint public weiGoal;                   
  uint public weiPresaleMax;             
  uint public contributorsCount = 0;     
  uint public weiTotal = 0;              
  uint public weiDistributed = 0;        
  uint public maxCap;                    
  uint public tokensSold = 0;            
  uint public loadedRefund = 0;          
  uint public weiRefunded = 0;           
  mapping (address => uint) public contributors;         
  mapping (address => uint) public presale;              

  enum States {Preparing, Presale, Waiting, Distribution, Success, Failure, Refunding}

  event Contributed(address _contributor, uint _weiAmount, uint _tokenAmount);
  event GoalReached(uint _weiAmount);
  event LoadedRefund(address _address, uint _loadedRefund);
  event Refund(address _contributor, uint _weiAmount);

  modifier inState(States _state) {
    require(getState() == _state);
    _;
  }

  function TokenDistribution(EmeraldToken _token, address _wallet, uint _presaleStart, uint _start, uint _end, 
    uint _ethPresaleMaxNoDecimals, uint _ethGoalNoDecimals, uint _maxTokenCapNoDecimals) {
    
    require(_token != address(0) && _wallet != address(0) && _presaleStart > 0 && _start > _presaleStart && _end > _start && _ethPresaleMaxNoDecimals > 0 
      && _ethGoalNoDecimals > _ethPresaleMaxNoDecimals && _maxTokenCapNoDecimals > 0);
    require(_token.isToken());

    token = _token;
    wallet = _wallet;
    presaleStart = _presaleStart;
    start = _start;
    end = _end;
    weiPresaleMax = _ethPresaleMaxNoDecimals * 1 ether;
    weiGoal = _ethGoalNoDecimals * 1 ether;
    maxCap = _maxTokenCapNoDecimals * 10 ** token.decimals();
  }

  function() payable {
    buy();
  }

   
  function buy() payable stopInEmergency {
    require(getState() == States.Presale || getState() == States.Distribution);
    require(msg.value > 0);
    if (getState() == States.Presale)
      presale[msg.sender] = presale[msg.sender].add(msg.value);
    else {
      contributors[msg.sender] = contributors[msg.sender].add(msg.value);
      weiDistributed = weiDistributed.add(msg.value);
    }
    contributeInternal(msg.sender, msg.value, getTokenAmount(msg.value));
  }

   
  function preallocate(address _receiver, uint _tokenAmountNoDecimals) onlyOwner stopInEmergency {
    require(getState() != States.Failure && getState() != States.Refunding && !token.released());
    uint tokenAmount = _tokenAmountNoDecimals * 10 ** token.decimals();
    contributeInternal(_receiver, 0, tokenAmount);
  }

   
  function loadRefund() payable {
    require(getState() == States.Failure || getState() == States.Refunding);
    require(msg.value > 0);
    loadedRefund = loadedRefund.add(msg.value);
    LoadedRefund(msg.sender, msg.value);
  }

   
  function setDates(uint _presaleStart, uint _start, uint _end) onlyOwner {
    require(_presaleStart > 0 && _start > _presaleStart && _end > _start);
    presaleStart = _presaleStart;
    start = _start;
    end = _end;
  }

   
  function contributeInternal(address _receiver, uint _weiAmount, uint _tokenAmount) internal {
    require(token.totalSupply().add(_tokenAmount) <= maxCap);
    token.produceEmeralds(_receiver, _tokenAmount);
    if (_weiAmount > 0) 
      wallet.transfer(_weiAmount);
    if (contributors[_receiver] == 0) contributorsCount++;
    tokensSold = tokensSold.add(_tokenAmount);
    weiTotal = weiTotal.add(_weiAmount);
    Contributed(_receiver, _weiAmount, _tokenAmount);
  }

   
  function refund() inState(States.Refunding) {
    uint weiValue = contributors[msg.sender];
    require(weiValue <= loadedRefund && weiValue <= this.balance);
    msg.sender.transfer(weiValue);
    contributors[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    loadedRefund = loadedRefund.sub(weiValue);
    Refund(msg.sender, weiValue);
  }

   
  function getState() constant returns (States) {
    if (now < presaleStart) return States.Preparing;
    if (now >= presaleStart && now < start && weiTotal < weiPresaleMax) return States.Presale;
    if (now < start && weiTotal >= weiPresaleMax) return States.Waiting;
    if (now >= start && now < end) return States.Distribution;
    if (weiTotal >= weiGoal) return States.Success;
    if (now >= end && weiTotal < weiGoal && loadedRefund == 0) return States.Failure;
    if (loadedRefund > 0) return States.Refunding;
  }

   
  function getTokenAmount(uint _weiAmount) internal constant returns (uint) {
    uint rate = 1000 * 10 ** 18 / 10 ** token.decimals();  
    uint tokenAmount = _weiAmount * rate;
    if (getState() == States.Presale)
      tokenAmount *= 2;
    return tokenAmount;
  }

}