 

pragma solidity ^0.4.11;

 
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
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
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

 
contract HoQuToken is StandardToken, Pausable {
    
    string public constant name = "HOQU Token";
    string public constant symbol = "HQX";
    uint32 public constant decimals = 18;
    
     
    function HoQuToken(uint _totalSupply) {
        require (_totalSupply > 0);
        totalSupply = balances[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint _value) whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 
contract BaseCrowdsale is Pausable {
    using SafeMath for uint256;

     
    address beneficiaryAddress;

     
    address public bankAddress;

     
    HoQuToken public token;

    uint256 public maxTokensAmount;
    uint256 public issuedTokensAmount = 0;
    uint256 public minBuyableAmount;
    uint256 public tokenRate;  
    
    uint256 endDate;

    bool public isFinished = false;

     
    event TokenBought(address indexed buyer, uint256 tokens, uint256 amount);

    modifier inProgress() {
        require (!isFinished);
        require (issuedTokensAmount < maxTokensAmount);
        require (now <= endDate);
        _;
    }
    
     
    function BaseCrowdsale(
        address _tokenAddress,
        address _bankAddress,
        address _beneficiaryAddress,
        uint256 _tokenRate,
        uint256 _minBuyableAmount,
        uint256 _maxTokensAmount,
        uint256 _endDate
    ) {
        token = HoQuToken(_tokenAddress);

        bankAddress = _bankAddress;
        beneficiaryAddress = _beneficiaryAddress;

        tokenRate = _tokenRate;
        minBuyableAmount = _minBuyableAmount.mul(1 ether);
        maxTokensAmount = _maxTokensAmount.mul(1 ether);
    
        endDate = _endDate;
    }

     
    function setTokenRate(uint256 _tokenRate) onlyOwner inProgress {
        require (_tokenRate > 0);
        tokenRate = _tokenRate;
    }

     
    function setMinBuyableAmount(uint256 _minBuyableAmount) onlyOwner inProgress {
        require (_minBuyableAmount > 0);
        minBuyableAmount = _minBuyableAmount.mul(1 ether);
    }

     
    function buyTokens() payable inProgress whenNotPaused {
        require (msg.value >= minBuyableAmount);
    
        uint256 payAmount = msg.value;
        uint256 returnAmount = 0;

         
        uint256 tokens = tokenRate.mul(payAmount);
    
        if (issuedTokensAmount + tokens > maxTokensAmount) {
            tokens = maxTokensAmount.sub(issuedTokensAmount);
            payAmount = tokens.div(tokenRate);
            returnAmount = msg.value.sub(payAmount);
        }
    
        issuedTokensAmount = issuedTokensAmount.add(tokens);
        require (issuedTokensAmount <= maxTokensAmount);

         
        token.transfer(msg.sender, tokens);
         
        TokenBought(msg.sender, tokens, payAmount);

         
        beneficiaryAddress.transfer(payAmount);
    
        if (returnAmount > 0) {
            msg.sender.transfer(returnAmount);
        }
    }

     
    function pauseToken() onlyOwner returns (bool) {
        require(!token.paused());
        token.pause();
        return true;
    }

     
    function unpauseToken() onlyOwner returns (bool) {
        require(token.paused());
        token.unpause();
        return true;
    }
    
     
    function finish() onlyOwner {
        require (issuedTokensAmount >= maxTokensAmount || now > endDate);
        require (!isFinished);
        isFinished = true;
        token.transfer(bankAddress, token.balanceOf(this));
    }
    
     
    function() external payable {
        buyTokens();
    }
}

 
contract PrivatePlacement is BaseCrowdsale {

     
    address public foundersAddress;
    address public supportAddress;
    address public bountyAddress;

     
    uint256 public constant totalSupply = 888888000 ether;
    uint256 public constant initialFoundersAmount = 266666400 ether;
    uint256 public constant initialSupportAmount = 8888880 ether;
    uint256 public constant initialBountyAmount = 35555520 ether;

     
    bool allocatedInternalWallets = false;
    
     
    function PrivatePlacement(
        address _bankAddress,
        address _foundersAddress,
        address _supportAddress,
        address _bountyAddress,
        address _beneficiaryAddress
    ) BaseCrowdsale(
        createToken(totalSupply),
        _bankAddress,
        _beneficiaryAddress,
        10000,  
        100,  
        23111088,  
        1507939200  
    ) {
        foundersAddress = _foundersAddress;
        supportAddress = _supportAddress;
        bountyAddress = _bountyAddress;
    }

     
    function allocateInternalWallets() onlyOwner {
        require (!allocatedInternalWallets);

        allocatedInternalWallets = true;

        token.transfer(foundersAddress, initialFoundersAmount);
        token.transfer(supportAddress, initialSupportAmount);
        token.transfer(bountyAddress, initialBountyAmount);
    }
    
     
    function createToken(uint256 _totalSupply) internal returns (HoQuToken) {
        return new HoQuToken(_totalSupply);
    }
}