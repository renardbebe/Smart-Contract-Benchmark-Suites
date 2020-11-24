 

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

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract PreSaleCDT is StandardToken, Ownable, Pausable {
   
  function PreSaleCDT() public { paused = true; }

   
  address public minter;

   
  function setMinter(address _minter) public onlyOwner {
      minter = _minter;
  }

   
  function mint(address _to, uint256 _amount) public returns (bool) {
    require(msg.sender == minter);

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  string public constant name = "Presale CDT Token";
  string public constant symbol = "CDT";
  uint8  public constant decimals = 18;
}

 
contract PreSaleCrowd is Ownable {
     
    using SafeMath for uint256;

     
    address public wallet;

     
    PreSaleCDT public token;

     
    uint public START_TIME = 1508544000;
    uint public CLOSE_TIME = 1509728400;
    uint256 public HARDCAP = 50000000000000000000000000;
    uint256 public exchangeRate = 9000;

     
    function () payable public {
      require(msg.sender == tx.origin);
      buyTokens(msg.sender);
    }

     
    function withdraw() onlyOwner public {
      wallet.transfer(this.balance);
    }

     
    function PreSaleCrowd(address _token, address _wallet) public {
      token  = PreSaleCDT(_token);
      wallet = _wallet;
    }

     
    event TokenPurchase(
      address indexed purchaser,
      address indexed beneficiary,
      uint256 value,
      uint256 amount
    );

     
    function setTime(uint _start, uint _close) public onlyOwner {
      require( _start < _close );
      START_TIME = _start;
      CLOSE_TIME = _close;
    }

     
    function setExchangeRate(uint256 _exchangeRate) public onlyOwner  {
      require(now < START_TIME);
      exchangeRate = _exchangeRate;
    }

     
    function buyTokens(address beneficiary) payable public {
      uint256 total = token.totalSupply();
      uint256 amount = msg.value;
      require(amount > 0);

       
      require(total < HARDCAP);
      require(now >= START_TIME);
      require(now < CLOSE_TIME);

       
      if (now < START_TIME + 3600 * 24 * 1) {
          exchangeRate = 10800;
      } else if (now < START_TIME + 3600 * 24 * 2) {
          exchangeRate = 10350;
      } else if (now < START_TIME + 3600 * 24 * 3) {
          exchangeRate = 9900;
      }

       
      uint256 tokens = amount.mul(exchangeRate);

      token.mint(beneficiary, tokens);
      TokenPurchase(msg.sender, beneficiary, amount, tokens);

       
      uint256 teamTokens = tokens / 100 * 8;
      token.mint(wallet, teamTokens);

       
      wallet.transfer(amount);
    }
}