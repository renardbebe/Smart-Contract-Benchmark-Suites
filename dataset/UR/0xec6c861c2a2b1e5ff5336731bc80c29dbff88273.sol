 

pragma solidity ^0.4.24;

 
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
 
 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
 
 
 
 

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Freezing is Ownable {
  event Freeze();
  event Unfreeze();
  event Freeze(address to);
  event UnfreezeOf(address to);
  event TransferAccessOn();
  event TransferAccessOff();

  bool public freezed = false;
  
  mapping (address => bool) public freezeOf;
  mapping (address => bool) public transferAccess;

  modifier whenNotFreeze() {
    require(!freezed);
    _;
  }

  modifier whenFreeze() {
    require(freezed);
    _;
  }

  modifier whenNotFreezeOf(address _account) {
    require(!freezeOf[_account]);
    _;
  }

  modifier whenFreezeOf(address _account) {
    require(freezeOf[_account]);
    _;
  }
  
  modifier onTransferAccess(address _account) {
      require(transferAccess[_account]);
      _;
  }
  
  modifier offTransferAccess(address _account) {
      require(!transferAccess[_account]);
      _;
  }

  function freeze() onlyOwner whenNotFreeze public {
    freezed = true;
    emit Freeze();
  }

  function unfreeze() onlyOwner whenFreeze public {
    freezed = false;
    emit Unfreeze();
  }
  
  function freezeOf(address _account) onlyOwner whenNotFreeze public {
    freezeOf[_account] = true;
    emit Freeze(_account);
  }

  function unfreezeOf(address _account) onlyOwner whenFreeze public  {
    freezeOf[_account] = false;
    emit UnfreezeOf(_account);
  }
  
  function transferAccessOn(address _account) onlyOwner offTransferAccess(_account) public {
      transferAccess[_account] = true;
      emit TransferAccessOn();
  }
  
  function transferAccessOff(address _account) onlyOwner onTransferAccess(_account) public {
      transferAccess[_account] = false;
      emit TransferAccessOff();
  }
  
}


  
contract ERC20Basic {
     uint public totalSupply;
     function balanceOf(address who) public constant returns (uint); 
     function transfer(address to, uint value) public ; 
     event Transfer(address indexed from, address indexed to, uint value); 
    
} 

 

contract BasicToken is ERC20Basic, Freezing {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }
  
  function transfer(address _to, uint _value) 
    public 
    onlyPayloadSize(2 * 32)
    whenNotFreeze
    whenNotFreezeOf(msg.sender)
    whenNotFreezeOf(_to)
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }
  
  function accsessAccountTransfer(address _to, uint _value) 
    public 
    onlyPayloadSize(2 * 32)
    onTransferAccess(msg.sender)
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyPayloadSize(3 * 32)
    whenNotFreeze
    whenNotFreezeOf(_from)
    whenNotFreezeOf(_to)
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
}

contract ElacToken is MintableToken {
    using SafeMath for uint256;
    
    string public name = 'ElacToken';
    string public symbol = 'ELAC';
    uint8 public decimals = 18;
    
}