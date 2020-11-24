 

pragma solidity 0.4.24;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
      c = a + b;
      require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
      require(b <= a);
      c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
      c = a * b;
      require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
      require(b > 0);
      c = a / b;
  }
}

contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Burn(address indexed from, uint value);
}



contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    owner = newOwner;
    newOwner = address(0);
    emit OwnershipTransferred(owner, newOwner);
  }
}

contract Pausable is Owned {
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
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract OxyCoin is ERC20Interface, Owned, Pausable {
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "OXY";
    name = "Oxycoin";
    decimals = 18;
    _totalSupply = 1200000000 * 10 ** uint(decimals);
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  
  modifier onlyPayloadSize(uint numWords) {
    assert(msg.data.length >= numWords * 32 + 4);
    _;
  }
    
  
    function isContract(address _address) private view returns (bool is_contract) {
      uint256 length;
      assembly {
       
        length := extcodesize(_address)
      }
      return (length > 0);
    }
    
   
    function totalSupply() public view returns (uint) {
      return _totalSupply;
    }
    
    
  

  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }


  
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
    
    
  
  function transfer(address to, uint tokens) public whenNotPaused onlyPayloadSize(2) returns (bool success) {
    require(to != address(0));
    require(tokens > 0);
    require(tokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
 
  function approve(address spender, uint tokens) public whenNotPaused onlyPayloadSize(2) returns (bool success) {
    require(spender != address(0));
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
    
      


    function transferFrom(address from, address to, uint tokens) public whenNotPaused onlyPayloadSize(3) returns (bool success) {
        require(tokens > 0);
        require(from != address(0));
        require(to != address(0));
        require(allowed[from][msg.sender] > 0);
        require(balances[from]>0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 

    
    function burn(uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply =_totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
  
   
    function burnFrom(address from, uint _value) public returns (bool success) {
        require(balances[from] >= _value);
        require(_value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(_value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(from, _value);
        return true;
    }
  
    function mintToken(address target, uint mintedAmount) onlyOwner public  returns (bool) {
        require(mintedAmount > 0);
        require(target != address(0));
        balances[target] = balances[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(owner, target, mintedAmount);
        return true;
    }

    function () public payable {
        revert();
    }
    
    
 
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        require(isContract(tokenAddress));
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}