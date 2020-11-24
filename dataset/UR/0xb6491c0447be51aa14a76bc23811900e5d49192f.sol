 

 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    
    return a % b;
  }
}

 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = tx.origin;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

 
contract ERC20 is Ownable {
  using SafeMath for uint256;

  uint public totalSupply;
  string public name;
  string public symbol;
  uint8 public decimals;
  bool public transferable;

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

   
  function balanceOf(address _holder) public view returns (uint) {
       return balances[_holder];
  }

  
  function transfer(address _to, uint _amount) public returns (bool) {
      require(_to != address(0) && _to != address(this));
      if (!transferable) {
        require(msg.sender == owner);
      }
      balances[msg.sender] = balances[msg.sender].sub(_amount);  
      balances[_to] = balances[_to].add(_amount);
      emit Transfer(msg.sender, _to, _amount);
      return true;
  }

  
  function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
      require(_to != address(0) && _to != address(this));
      balances[_from] = balances[_from].sub(_amount);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Transfer(_from, _to, _amount);
      return true;
   }

  
  function approve(address _spender, uint _amount) public returns (bool) {
      require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
      allowed[msg.sender][_spender] = _amount;
      emit Approval(msg.sender, _spender, _amount);
      return true;
  }

  
  function allowance(address _owner, address _spender) public view returns (uint) {
      return allowed[_owner][_spender];
  }

   
  function unfreeze() public onlyOwner {
      transferable = true;
      emit Unfreezed(now);
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event Unfreezed(uint indexed _timestamp);
}

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

   
  constructor(string _name, string _symbol, uint8 _decimals, uint _totalSupply, bool _transferable) public {   
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply = _totalSupply;
      balances[tx.origin] = _totalSupply;
      transferable = _transferable;
      emit Transfer(address(0), tx.origin, _totalSupply);
  }

   
  function airdrop(address[] _addresses, uint256[] _values) public onlyOwner returns (bool) {
      require(_addresses.length == _values.length);
      for (uint256 i = 0; i < _addresses.length; i++) {
          require(transfer(_addresses[i], _values[i]));
      }        
      return true;
  }
}

 
contract MintableToken is Ownable, ERC20 {
  using SafeMath for uint256;

  bool public mintingFinished = false;

  
  constructor(string _name, string _symbol, uint8 _decimals, bool _transferable) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    transferable = _transferable;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  
  function mintTokens(address _holder, uint _value) public canMint onlyOwner returns (bool) {
     require(_value > 0);
     require(_holder != address(0));
     balances[_holder] = balances[_holder].add(_value);
     totalSupply = totalSupply.add(_value);
     emit Transfer(address(0), _holder, _value);
     return true;
  }

   
  function airdrop(address[] _addresses, uint256[] _values) public onlyOwner returns (bool) {
      require(_addresses.length == _values.length);
      for (uint256 i = 0; i < _addresses.length; i++) {
          require(mintTokens(_addresses[i], _values[i]));
      }
      return true;
  }
 
   
  function finishMinting() public onlyOwner {
      mintingFinished = true;
      emit MintFinished(now);
  }

  event MintFinished(uint indexed _timestamp);
}

 
contract TokenCreator {
  using SafeMath for uint256;

  mapping(address => address[]) public mintableTokens;
  mapping(address => address[]) public standardTokens;
  mapping(address => uint256) public amountMintTokens;
  mapping(address => uint256) public amountStandTokens;
  
   
  function createStandardToken(string _name, string _symbol, uint8 _decimals, uint _totalSupply, bool _transferable) public returns (address) {
    address token = new StandardToken(_name, _symbol, _decimals, _totalSupply, _transferable);
    standardTokens[msg.sender].push(token);
    amountStandTokens[msg.sender]++;
    emit TokenCreated(msg.sender, token);
    return token;
  }

   
  function createMintableToken(string _name, string _symbol, uint8 _decimals, bool _transferable) public returns (address) {
    address token = new MintableToken(_name, _symbol, _decimals, _transferable);
    mintableTokens[msg.sender].push(token);
    amountMintTokens[msg.sender]++;
    emit TokenCreated(msg.sender, token);
    return token;
  }

  event TokenCreated(address indexed _creator, address indexed _token);
}