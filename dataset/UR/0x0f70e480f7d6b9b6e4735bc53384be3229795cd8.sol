 

 
 
 
    
 
 
  
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.25;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC223Interface {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value)  public ;
    function transfer(address to, uint value, bytes data)  public ;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 
 
contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
contract Pausable is Ownable {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract FOOToken is IERC20, ERC223Interface, Ownable, Pausable {
    using SafeMath for uint;
    
    mapping(address => uint) balances;  
    
    mapping (address => mapping (address => uint256)) private _allowed;
    
    modifier validDestination( address to ) {
      require(to != address(0x0));
      _;
    }
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
 constructor() public {
      _name = "FOOToken";
      _symbol = "FOOT";
      _decimals = 18;
      _mint(msg.sender, 100000000 * (10 ** 18));
    }

     
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
    function name() public view returns(string) {
      return _name;
    }

   
    function symbol() public view returns(string) {
      return _symbol;
    }

   
    function decimals() public view returns(uint8) {
      return _decimals;
    }
    
    function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }
  
   
   function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  
   function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  
  
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    validDestination(_to) 
    public
    whenNotPaused
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= _allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);

    
    uint codeLength;
    bytes memory empty;
    assembly {
       
      codeLength := extcodesize(_to)
    }
    if(codeLength>0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(_from, _value, empty);
    }
    

    return true;
  }

  
     
    function transfer(address _to, uint _value, bytes _data)  whenNotPaused validDestination(_to) public {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
    
    
     
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    _totalSupply = _totalSupply.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);

    
    uint codeLength;
    bytes memory empty;
    assembly {
       
      codeLength := extcodesize(_account)
    }
    if(codeLength>0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_account);
      receiver.tokenFallback(address(0), _amount, empty);
    }
    
  }

  
     
    function transfer(address _to, uint _value) whenNotPaused validDestination(_to) public {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }

    
     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
     
  
  function() public payable {
    revert();
  }
  
  struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) pure public {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);

       
    }
    
}