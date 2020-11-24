 

pragma solidity ^0.4.24;

 

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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

 

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

 

 
contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool public paused = true;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Paused();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpaused();
  }
}

 

 
contract Freezable is Ownable {

    mapping(address => bool) public frozenAccount;

     
    modifier isFreezenAccount(){
        require(frozenAccount[msg.sender]);
        _;
    }

     
    modifier isNonFreezenAccount(){
        require(!frozenAccount[msg.sender]);
        _;
    }

     
    function freezeAccount(address _address, bool _freeze) onlyOwner public {
        frozenAccount[_address] = _freeze;
    }

     
    function freezeAccounts(address[] _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            frozenAccount[_addresses[i]] = true;
        }
    }

     
    function unFreezeAccounts(address[] _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            frozenAccount[_addresses[i]] = false;
        }
    }

}

 

 
contract Whitelist is Ownable {

  mapping(address => bool) public whitelistedAddress;

   
  modifier onlyIfWhitelisted(address _address) {
    require(whitelistedAddress[_address]);
     _;
  }

   
  function addAddressToWhitelist(address _address)
    public
    onlyOwner
  {
      whitelistedAddress[_address] = true;
  }

   
  function addAddressesToWhitelist(address[] _addresses)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addAddressToWhitelist(_addresses[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _address)
    public
    onlyOwner
  {
      whitelistedAddress[_address] = false;
  }

   
  function removeAddressesFromWhitelist(address[] _addresses)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      removeAddressFromWhitelist(_addresses[i]);
    }
  }

}

 

contract CustomERC20 is StandardToken, Ownable, Pausable, Freezable, Whitelist {

	 
	modifier onlyIfTransferable() {
		require(!paused || whitelistedAddress[msg.sender] || msg.sender == owner);
		require(!frozenAccount[msg.sender]);
		_;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) onlyIfTransferable public returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	 
	function transfer(address _to, uint256 _value) onlyIfTransferable public returns (bool) {
		return super.transfer(_to, _value);
	}

	 
	function sendAirdrops(address[] _addresses, uint256[] _amounts) public {
		require(_addresses.length == _amounts.length);
		for (uint i = 0; i < _addresses.length; i++) { 
			transfer(_addresses[i], _amounts[i]);
		}
	}

}

 

contract G7Token is CustomERC20 {
  string public constant version = "1.0";
  string public constant name = "G7 Token";
  string public constant symbol = "G7T";
  uint8 public constant decimals = 18;

  uint256 private constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));

   
  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

}