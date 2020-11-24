 

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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract Presale {
    using SafeMath for uint256;

     
    uint256 public minimalCap;

     
    uint256 public maximumCap;

     
    Token public token;

     
    uint256 public early_bird_minimal;

     
    address public wallet;

     
    uint256 public minimal_token_sell;

     
    uint256 public wei_per_token;

     
    uint256 public startTime;
    uint256 public endTime;


    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function Presale(uint256 _startTime, address _wallet) {
        require(_startTime >=  now);
        require(_wallet != 0x0);

        token = new Token();
        wallet = _wallet;
        startTime = _startTime;
        minimal_token_sell = 1e10;
        endTime = _startTime + 86400 * 7;
        wei_per_token = 62500000;   
        early_bird_minimal = 30e18;
        maximumCap = 1875e18 / wei_per_token;
        minimalCap = 350e18 / wei_per_token;
    }

     
    function() payable {
        return buyTokens(msg.sender);
    }

     
    function calcAmount() internal returns (uint256) {
        if (now < startTime && msg.value >= early_bird_minimal) {
            return (msg.value / wei_per_token / 60) * 70;   
        }
        return msg.value / wei_per_token;
    }

     
    function buyTokens(address contributor) payable {
        uint256 amount = calcAmount();

        require(contributor != 0x0) ;
        require(minimal_token_sell < amount);
        require((token.totalSupply() + amount) <= maximumCap);
        require(validPurchase());

        token.mint(contributor, amount);
        TokenPurchase(0x0, contributor, msg.value, amount);
        Transfer(0x0, contributor, amount);
        wallet.transfer(msg.value);
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return token.balanceOf(_owner);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = ((now >= startTime  || msg.value >= early_bird_minimal) && now <= endTime);
        bool nonZeroPurchase = msg.value != 0;

        return withinPeriod && nonZeroPurchase;
    }

     
    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime || token.totalSupply() == maximumCap;
    }

}

contract Token is MintableToken {

    string public constant name = 'Privatix Presale';
    string public constant symbol = 'PRIXY';
    uint256 public constant decimals = 8;

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        revert();
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        revert();
    }

}