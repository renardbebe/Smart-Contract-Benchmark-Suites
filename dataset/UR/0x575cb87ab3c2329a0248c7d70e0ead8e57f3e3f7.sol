 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
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
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require (!halted);
    _;
  }

  modifier onlyInEmergency {
    require (halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract AhooleeToken is StandardToken {

  string public name = "Ahoolee Token";
  string public symbol = "AHT";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 100000000 * 1 ether;

   
  function AhooleeToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}


contract AhooleeTokenSale is Haltable {
    using SafeMath for uint;

    string public name = "Ahoolee Token Sale";

    AhooleeToken public token;
    address public beneficiary;

    uint public hardCapLow;
    uint public hardCapHigh;
    uint public softCap;
    uint public hardCapLowUsd;
    uint public hardCapHighUsd;
    uint public softCapUsd;
    uint public collected;
    uint public priceETH;
    
    uint public investorCount = 0;
    uint public weiRefunded = 0;

    uint public startTime;
    uint public endTime;

    bool public softCapReached = false;
    bool public crowdsaleFinished = false;
    
    uint constant HARD_CAP_TOKENS = 25000000;

    mapping (address => bool) refunded;
    mapping (address => uint256) saleBalances ;  
    mapping (address => bool) claimed;   

    event GoalReached(uint amountRaised);
    event SoftCapReached(uint softCap);
    event NewContribution(address indexed holder, uint256 etherAmount);
    event Refunded(address indexed holder, uint256 amount);
    event LogClaim(address indexed holder, uint256 amount, uint price);

    modifier onlyAfter(uint time) {
        require (now > time);
        _;
    }

    modifier onlyBefore(uint time) {
        require (now < time);
        _;
    }

    function AhooleeTokenSale(
        uint _hardCapLowUSD,
        uint _hardCapHighUSD,
        uint _softCapUSD,
        address _token,
        address _beneficiary,
        uint _priceETH,

        uint _startTime,
        uint _durationHours
    ) {
        priceETH = _priceETH;
        hardCapLowUsd = _hardCapLowUSD;
        hardCapHighUsd = _hardCapHighUSD;
        softCapUsd = _softCapUSD;
        
        calculatePrice();
        
        token = AhooleeToken(_token);
        beneficiary = _beneficiary;

        startTime = _startTime;
        endTime = _startTime + _durationHours * 1 hours;
    }

    function calculatePrice() internal{
        hardCapLow = hardCapLowUsd  * 1 ether / priceETH;
        hardCapHigh = hardCapHighUsd  * 1 ether / priceETH;
        softCap = softCapUsd * 1 ether / priceETH;
    }

    function setEthPrice(uint _priceETH) onlyBefore(startTime) onlyOwner {
        priceETH = _priceETH;
        calculatePrice();
    }

    function () payable stopInEmergency{
        assert (msg.value > 0.01 * 1 ether || msg.value == 0);
        if(msg.value > 0.01 * 1 ether) doPurchase(msg.sender);
    }

    function saleBalanceOf(address _owner) constant returns (uint256) {
      return saleBalances[_owner];
    }

    function claimedOf(address _owner) constant returns (bool) {
      return claimed[_owner];
    }

    function doPurchase(address _owner) private onlyAfter(startTime) onlyBefore(endTime) {
        
        require(crowdsaleFinished == false);

        require (collected.add(msg.value) <= hardCapHigh);

        if (!softCapReached && collected < softCap && collected.add(msg.value) >= softCap) {
            softCapReached = true;
            SoftCapReached(softCap);
        }

        if (saleBalances[msg.sender] == 0) investorCount++;
      
        collected = collected.add(msg.value);

        saleBalances[msg.sender] = saleBalances[msg.sender].add(msg.value);

        NewContribution(_owner, msg.value);

        if (collected == hardCapHigh) {
            GoalReached(hardCapHigh);
        }
    }

    function claim() {
        require (crowdsaleFinished);
        require (!claimed[msg.sender]);
        
        uint price = HARD_CAP_TOKENS * 1 ether / hardCapLow;
        if(collected > hardCapLow){
          price = HARD_CAP_TOKENS * 1 ether / collected; 
        } 
        uint tokens = saleBalances[msg.sender] * price;

        require(token.transfer(msg.sender, tokens));
        claimed[msg.sender] = true;
        LogClaim(msg.sender, tokens, price);
    }

    function returnTokens() onlyOwner {
        require (crowdsaleFinished);

        uint tokenAmount = token.balanceOf(this);
        if(collected < hardCapLow){
          tokenAmount = (hardCapLow - collected) * HARD_CAP_TOKENS * 1 ether / hardCapLow;
        } 
        require (token.transfer(beneficiary, tokenAmount));
    }

    function withdraw() onlyOwner {
        require (softCapReached);
        require (beneficiary.send(collected));
        crowdsaleFinished = true;
    }

    function refund() public onlyAfter(endTime) {
        require (!softCapReached);
        require (!refunded[msg.sender]);
        require (saleBalances[msg.sender] != 0) ;

        uint refund = saleBalances[msg.sender];
        require (msg.sender.send(refund));
        refunded[msg.sender] = true;
        weiRefunded = weiRefunded.add(refund);
        Refunded(msg.sender, refund);
    }

}