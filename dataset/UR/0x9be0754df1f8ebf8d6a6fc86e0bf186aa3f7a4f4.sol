 

pragma solidity ^0.4.17;

 
 
 
 

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);_;
  }

   
  modifier whenPaused {
    require(paused);_;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract BasicToken is ERC20Basic, Ownable {
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

contract BurnableToken is StandardToken, Pausable {

    event Burn(address indexed burner, uint256 value);

    function transfer(address _to, uint _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 _value) whenNotPaused public {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);   
        Burn(msg.sender, _value);
    }
}

contract SECToken is BurnableToken {

    string public constant symbol = "SEC";
    string public name = "Erised(SEC)";
    uint8 public constant decimals = 18;

    function SECToken() {
        uint256 _totalSupply = 567648000;  
        uint256 capacity = _totalSupply.mul(1 ether);
        totalSupply = balances[msg.sender] = capacity;
    }

    function setName(string name_) onlyOwner {
        name = name_;
    }

    function burn(uint256 _value) whenNotPaused public {
        super.burn(_value);
    }

}

contract SecCrowdSale is Pausable{
    using SafeMath for uint;

     
    uint public constant MAX_CAP = 51088320000000000000000000;   
     
    uint public constant MIN_INVEST_ETHER = 0.1 ether;
     
    uint private constant CROWDSALE_PERIOD = 15 days;
     
    uint public constant SEC_PER_ETHER = 7000000000000000000000;  
     
    address public constant SEC_contract = 0x41ff967f9f8ec58abf88ca1caa623b3fd6277191;

     
    SECToken public SECCoin;
     
    uint public etherReceived;
     
    uint public SECCoinSold;
     
    uint public startTime;
     
    uint public endTime;
     
    bool public crowdSaleClosed;

    modifier respectTimeFrame() {
        require((now >= startTime) || (now <= endTime ));_;
    }

    event LogReceivedETH(address addr, uint value);
    event LogCoinsEmited(address indexed from, uint amount);

    function CrowdSale() {
        SECCoin = SECToken(SEC_contract);
    }

     
    function() whenNotPaused respectTimeFrame payable {
        BuyTokenSafe(msg.sender);
    }

     
    function start() onlyOwner external{
        require(startTime == 0);  
        startTime = now ;
        endTime =  now + CROWDSALE_PERIOD;
    }

     
    function BuyTokenSafe(address beneficiary) internal {
        require(msg.value >= MIN_INVEST_ETHER);  
        uint SecToSend = msg.value.mul(SEC_PER_ETHER).div(1 ether);  
        require(SecToSend.add(SECCoinSold) <= MAX_CAP);
        SECCoin.transfer(beneficiary, SecToSend);  
        etherReceived = etherReceived.add(msg.value);  
        SECCoinSold = SECCoinSold.add(SecToSend);
         
        LogCoinsEmited(msg.sender ,SecToSend);
        LogReceivedETH(beneficiary, etherReceived);
    }

     
    function finishSafe(address burner) onlyOwner external{
        require(burner!=address(0));
        require(now > endTime || SECCoinSold == MAX_CAP);  
        owner.send(this.balance);  
        uint remains = SECCoin.balanceOf(this);
        if (remains > 0) {  
            SECCoin.transfer(burner, remains);
        }
        crowdSaleClosed = true;
    }
}