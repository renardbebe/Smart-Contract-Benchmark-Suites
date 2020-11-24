 

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
     require(msg.data.length >= size + 4);
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

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract MigrationAgent {
  function migrateFrom(address _from, uint256 _value);
}

 
contract VotesPlatformToken is StandardToken, Ownable {

  string public name = "Votes Platform Token";
  string public symbol = "VOTES";
  uint256 public decimals = 2;
  uint256 public INITIAL_SUPPLY = 100000000 * 100;

  mapping(address => bool) refundAllowed;

  address public migrationAgent;
  uint256 public totalMigrated;

   
  function VotesPlatformToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

   
  function allowRefund(address _contractAddress) onlyOwner {
    refundAllowed[_contractAddress] = true;
  }

   
  function refundPresale(address _from, uint _count) {
    require(refundAllowed[msg.sender]);
    balances[_from] = balances[_from].sub(_count);
    balances[msg.sender] = balances[msg.sender].add(_count);
  }

  function setMigrationAgent(address _agent) external onlyOwner {
    migrationAgent = _agent;
  }

  function migrate(uint256 _value) external {
     
    require(migrationAgent != 0);

     
    require(_value > 0);
    require(_value <= balances[msg.sender]);

    balances[msg.sender] -= _value;
    totalSupply -= _value;
    totalMigrated += _value;
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
  }
}

 
contract VotesPlatformTokenPreSale is Ownable {
    using SafeMath for uint;

    string public name = "Votes Platform Token ICO";

    VotesPlatformToken public token;
    address public beneficiary;

    uint public hardCap;
    uint public softCap;
    uint public tokenPrice;
    uint public purchaseLimit;

    uint public tokensSold = 0;
    uint public weiRaised = 0;
    uint public investorCount = 0;
    uint public weiRefunded = 0;

    uint public startTime;
    uint public endTime;

    bool public softCapReached = false;
    bool public crowdsaleFinished = false;

    mapping(address => uint) sold;

    event GoalReached(uint amountRaised);
    event SoftCapReached(uint softCap1);
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Refunded(address indexed holder, uint256 amount);

    modifier onlyAfter(uint time) {
        require(now >= time);
        _;
    }

    modifier onlyBefore(uint time) {
        require(now <= time);
        _;
    }

    function VotesPlatformTokenPreSale(
        uint _hardCapUSD,        
        uint _softCapUSD,        
        address _token,          
        address _beneficiary,    
        uint _totalTokens,       
        uint _priceETH,          
        uint _purchaseLimitUSD,  
        uint _startTime,         
        uint _duration           
    ) {
        hardCap = _hardCapUSD * 1 ether / _priceETH;
        softCap = _softCapUSD * 1 ether / _priceETH;
        tokenPrice = hardCap / _totalTokens;

        purchaseLimit = _purchaseLimitUSD * 1 ether / _priceETH / tokenPrice;
        token = VotesPlatformToken(_token);
        beneficiary = _beneficiary;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 hours;
    }

    function () payable {
        require(msg.value / tokenPrice > 0);
        doPurchase(msg.sender);
    }

    function refund() external onlyAfter(endTime) {
        require(!softCapReached);
        uint balance = sold[msg.sender];
        require(balance > 0);
        uint refund = balance * tokenPrice;
        msg.sender.transfer(refund);
        delete sold[msg.sender];
        weiRefunded = weiRefunded.add(refund);
        token.refundPresale(msg.sender, balance);
        Refunded(msg.sender, refund);
    }

    function withdrawTokens() onlyOwner onlyAfter(endTime) {
        token.transfer(beneficiary, token.balanceOf(this));
    }

    function withdraw() onlyOwner {
        require(softCapReached);
        beneficiary.transfer(weiRaised);
        token.transfer(beneficiary, token.balanceOf(this));
        crowdsaleFinished = true;
    }

    function doPurchase(address _to) private onlyAfter(startTime) onlyBefore(endTime) {
        assert(crowdsaleFinished == false);

        require(weiRaised.add(msg.value) <= hardCap);

        if (!softCapReached && weiRaised < softCap && weiRaised.add(msg.value) >= softCap) {
            softCapReached = true;
            SoftCapReached(softCap);
        }

        uint tokens = msg.value / tokenPrice;
        require(token.balanceOf(_to) + tokens <= purchaseLimit);

        if (sold[_to] == 0)
            investorCount++;

        token.transfer(_to, tokens);
        sold[_to] += tokens;
        tokensSold = tokensSold.add(tokens);

        weiRaised = weiRaised.add(msg.value);

        NewContribution(_to, tokens, msg.value);

        if (weiRaised == hardCap) {
            GoalReached(hardCap);
        }
    }
}