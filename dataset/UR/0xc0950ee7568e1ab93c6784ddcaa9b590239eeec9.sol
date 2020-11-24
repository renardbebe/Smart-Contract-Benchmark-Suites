 

pragma solidity 0.4.19;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 
 
 
 
 
 
 
 
 
 
 
 




contract PrimeToken is StandardToken {
  string public constant name = 'PRIME PRETGE';
  string public constant symbol = 'PRIME';
  uint256 public constant decimals = 18;

  uint256 public constant tokenCreationCap = 250000000 * 10 ** decimals;
  string public constant LEGAL = 'By using this smart-contract you confirm to have read and agree to the terms and conditions set herein: http: 

  address public wallet;
  address public owner;

  bool public active = true;

  uint256 public oneTokenInWei = 50000000000000000;
  uint256 public minimumAllowedWei = 5000000000000000000;

  modifier onlyOwner {
    if (owner != msg.sender) {
      revert();
    }
    _;
  }

  modifier onlyActive {
    if (!active) {
      revert();
    }
    _;
  }

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  function PrimeToken(address _wallet) public {
    wallet = _wallet;
    owner = msg.sender;
  }

  function() payable public {
    createTokens();
  }

   
  function mintTokens(address _to, uint256 _amount) external onlyOwner {
    uint256 tokens = _amount.mul(10 ** decimals);
    uint256 checkedSupply = totalSupply_.add(tokens);
    require(tokenCreationCap > checkedSupply);

    balances[_to] += tokens;
    totalSupply_ = checkedSupply;

    Mint(_to, tokens);
    Transfer(address(0), _to, tokens);
  }

  function withdraw() external onlyOwner {
    wallet.transfer(this.balance);
  }

  function finalize() external onlyOwner {
    active = false;

    MintFinished();
  }

   
  function setTokenPriceInWei(uint256 _oneTokenInWei) external onlyOwner {
    oneTokenInWei = _oneTokenInWei;
  }

  function createTokens() internal onlyActive {
    require(msg.value >= minimumAllowedWei);

    uint256 multiplier = 10 ** decimals;
    uint256 tokens = msg.value.mul(multiplier).div(oneTokenInWei);
    uint256 checkedSupply = totalSupply_.add(tokens);

    require(tokenCreationCap > checkedSupply);

    balances[msg.sender] += tokens;
    totalSupply_ = checkedSupply;

    Mint(msg.sender, tokens);
    Transfer(address(0), msg.sender, tokens);
    TokenPurchase(
      msg.sender,
      msg.sender,
      msg.value,
      tokens
    );
  }

  function setMinimumAllowedWei(uint256 _wei) external onlyOwner {
    minimumAllowedWei = _wei;
  }
}