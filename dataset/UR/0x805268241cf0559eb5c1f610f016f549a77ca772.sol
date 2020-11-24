 

pragma solidity ^0.4.18;

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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;
    address public publisher;


    function MultiOwners() {
        owners[msg.sender] = true;
        publisher = msg.sender;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() constant returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function checkOwner(address maybe_owner) constant returns (bool) {
        return owners[maybe_owner] ? true : false;
    }


    function grant(address _owner) onlyOwner {
        owners[_owner] = true;
        AccessGrant(_owner);
    }

    function revoke(address _owner) onlyOwner {
        require(_owner != publisher);
        require(msg.sender != _owner);

        owners[_owner] = false;
        AccessRevoke(_owner);
    }
}

contract Haltable is MultiOwners {
    bool public halted;

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

contract FixedRate {
    uint256 public rateETHUSD = 470e2;
}

contract Stage is FixedRate, MultiOwners {
    using SafeMath for uint256;

     
    string _stageName = "Pre-ICO";

     
    uint256 public mainCapInUSD = 1000000e2;

     
    uint256 public hardCapInUSD = mainCapInUSD;

     
    uint256 public period = 30 days;

     
    uint256 public tokenPriceUSD = 50;

     
    uint256 public weiPerToken;
    
     
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public totalWei;

     
    uint256 public mainCapInWei;
     
    uint256 public hardCapInWei;

    function Stage (uint256 _startTime) {
        startTime = _startTime;
        endTime = startTime.add(period);
        weiPerToken = tokenPriceUSD.mul(1 ether).div(rateETHUSD);
        mainCapInWei = mainCapInUSD.mul(1 ether).div(rateETHUSD);
        hardCapInWei = mainCapInWei;

    }

     
    function calcAmountAt(uint256 _value, uint256 _at) constant returns (uint256, uint256) {
        uint256 estimate;
        uint256 odd;

        if(_value.add(totalWei) > hardCapInWei) {
            odd = _value.add(totalWei).sub(hardCapInWei);
            _value = hardCapInWei.sub(totalWei);
        } 
        estimate = _value.mul(1 ether).div(weiPerToken);
        require(_value + totalWei <= hardCapInWei);
        return (estimate, odd);
    }
}

contract TripleAlphaCrowdsalePreICO is MultiOwners, Haltable, Stage {
    using SafeMath for uint256;

     
    uint256 public minimalTokens = 1e18;

     
    TripleAlphaTokenPreICO public token;

     
    address public wallet;

     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event OddMoney(address indexed beneficiary, uint256 value);

    modifier validPurchase() {
        bool nonZeroPurchase = msg.value != 0;

        require(withinPeriod() && nonZeroPurchase);

        _;        
    }

    modifier isExpired() {
        require(now > endTime);

        _;        
    }

     
    function withinPeriod() constant returns(bool res) {
        return (now >= startTime && now <= endTime);
    }

     
    function TripleAlphaCrowdsalePreICO(uint256 _startTime, address _wallet) Stage(_startTime)

    {
        require(_startTime >= now);
        require(_wallet != 0x0);

        token = new TripleAlphaTokenPreICO();
        wallet = _wallet;
    }

     
    function stageName() constant public returns (string) {
        bool before = (now < startTime);
        bool within = (now >= startTime && now <= endTime);

        if(before) {
            return 'Not started';
        }

        if(within) {
            return _stageName;
        } 

        return 'Finished';
    }

    
    function totalEther() public constant returns(uint256) {
        return totalWei.div(1e18);
    }

     
    function() payable {
        return buyTokens(msg.sender);
    }

     
    function buyTokens(address contributor) payable stopInEmergency validPurchase public {
        uint256 amount;
        uint256 odd_ethers;
        
        (amount, odd_ethers) = calcAmountAt(msg.value, now);
  
        require(contributor != 0x0) ;
        require(minimalTokens <= amount);

        token.mint(contributor, amount);
        TokenPurchase(contributor, msg.value, amount);

        totalWei = totalWei.add(msg.value);

        if(odd_ethers > 0) {
            require(odd_ethers < msg.value);
            OddMoney(contributor, odd_ethers);
            contributor.transfer(odd_ethers);
        }

        wallet.transfer(this.balance);
    }

     
    function finishCrowdsale() onlyOwner public {
        require(now > endTime || totalWei == hardCapInWei);
        require(!token.mintingFinished());
        token.finishMinting();
    }

     
    function running() constant public returns (bool) {
        return withinPeriod() && !token.mintingFinished();
    }
}

contract TripleAlphaTokenPreICO is MintableToken {

    string public constant name = 'Triple Alpha Token Pre-ICO';
    string public constant symbol = 'pTRIA';
    uint8 public constant decimals = 18;

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        revert();
    }

    function transfer(address to, uint256 value) returns (bool) {
        revert();
    }
}