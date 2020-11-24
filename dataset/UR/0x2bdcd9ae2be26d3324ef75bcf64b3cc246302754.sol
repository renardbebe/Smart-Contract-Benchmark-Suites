 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    if ((a == 0) || (c / a == b)) {
      return c;
    }
    revert();
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    if (a == b * c + a % b) {
      return c;
    }
    revert();
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    if (b <= a) {
      return a - b;
    }
    revert();
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    if (c >= a) {
      return c;
    }
    revert();
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Haltable is Ownable {
  bool public halted;

  event Halted(uint256 _time);
  event Unhalted(uint256 _time);
  
  modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
    Halted( now );
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    Unhalted( now );
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 {
  using SafeMath for uint256;
  
  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) {   

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract EtalonToken is StandardToken, Haltable {
  using SafeMath for uint256;
  
  string  public name        = "Etalon Token";
  string  public symbol      = "ETL";
  uint256 public decimals    = 0;
  uint256 public INITIAL     = 4000000;
  
  event MoreTokensMinted(uint256 _minted, string reason);

   
  function EtalonToken() {
    totalSupply = INITIAL;
    balances[msg.sender] = INITIAL;
  }
  
   
  function mint( uint256 _amount, string reason ) onlyOwner {
    totalSupply = totalSupply.add(_amount);
    balances[msg.sender] = balances[msg.sender].add(_amount);
    MoreTokensMinted(_amount, reason);
  }
}

 
contract EtalonTokenPresale is Haltable {
  using SafeMath for uint256;

  string public name = "Etalon Token Presale";

  EtalonToken public token;
  address public beneficiary;

  uint256 public hardCap;
  uint256 public softCap;
  uint256 public collected;
  uint256 public price;

  uint256 public tokensSold = 0;
  uint256 public weiRaised = 0;
  uint256 public investorCount = 0;
  uint256 public weiRefunded = 0;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public duration;

  bool public softCapReached = false;
  bool public crowdsaleFinished = false;

  mapping (address => bool) refunded;

  event CrowdsaleStarted(uint256 _time, uint256 _softCap, uint256 _hardCap, uint256 _price );
  event CrowdsaleFinished(uint256 _time);
  event CrowdsaleExtended(uint256 _endTime);
  event GoalReached(uint256 _amountRaised);
  event SoftCapReached(uint256 _softCap);
  event NewContribution(address indexed _holder, uint256 _tokenAmount, uint256 _etherAmount);
  event Refunded(address indexed _holder, uint256 _amount);

  modifier onlyAfter(uint256 time) {
    if (now < time) revert();
    _;
  }

  modifier onlyBefore(uint256 time) {
    if (now > time) revert();
    _;
  }
  
   
  function EtalonTokenPresale(
    address _token,
    address _beneficiary
  ) {
    hardCap = 0;
    softCap = 0;
    price   = 0;
  
    token = EtalonToken(_token);
    beneficiary = _beneficiary;

    startTime = 0;
    endTime   = 0;
  }
  
     
  function start(
    uint256 _hardCap,
    uint256 _softCap,
    uint256 _duration,
    uint256 _price ) onlyOwner
  {
    if (startTime > 0) revert();
    hardCap = _hardCap * 1 ether;
    softCap = _softCap * 1 ether;
    price   = _price;
    startTime = now;
    endTime   = startTime + _duration * 1 hours;
    duration  = _duration;
    CrowdsaleStarted(now, softCap, hardCap, price );
  }

    
  function finish() onlyOwner onlyAfter(endTime) {
    crowdsaleFinished = true;
    CrowdsaleFinished( now );
  }

   
  function extend( uint256 _duration ) onlyOwner {
    endTime  = endTime + _duration * 1 hours;
    duration = duration + _duration;
    if ((startTime + 4500 hours) < endTime) revert();
    CrowdsaleExtended( endTime );
  }

   
  function () payable stopInEmergency {
    if ( msg.value < uint256( 1 ether ).div( price ) ) revert();
    doPurchase(msg.sender, msg.value);
  }

   
  function refund() external onlyAfter(endTime) stopInEmergency {   
    if (!crowdsaleFinished) revert();
    if (softCapReached) revert();
    if (refunded[msg.sender]) revert();

    uint256 balance = token.balanceOf(msg.sender);
    if (balance == 0) revert();

    uint256 to_refund = balance.mul(1 ether).div(price);
    if (to_refund > this.balance) {
      to_refund = this.balance;   
    }

    msg.sender.transfer( to_refund );  
    refunded[msg.sender] = true;
    weiRefunded = weiRefunded.add( to_refund );
    Refunded( msg.sender, to_refund );
  }

   
  function withdraw() onlyOwner {
    if (!softCapReached) revert();
    beneficiary.transfer( collected );
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

   
  function doPurchase(address _buyer, uint256 _amount) private onlyAfter(startTime) onlyBefore(endTime) stopInEmergency {
    
    if (crowdsaleFinished) revert();

    if (collected.add(_amount) > hardCap) revert();

    if ((!softCapReached) && (collected < softCap) && (collected.add(_amount) >= softCap)) {
      softCapReached = true;
      SoftCapReached(softCap);
    }

    uint256 tokens = _amount.mul( price ).div( 1 ether );  
    if (tokens == 0) revert();

    if (token.balanceOf(_buyer) == 0) investorCount++;
    
    collected = collected.add(_amount);

    token.transfer(_buyer, tokens);

    weiRaised = weiRaised.add(_amount);
    tokensSold = tokensSold.add(tokens);

    NewContribution(_buyer, tokens, _amount);

    if (collected == hardCap) {
      GoalReached(hardCap);
    }
  }

   
  function burn() onlyOwner onlyInEmergency { selfdestruct(owner); }
}