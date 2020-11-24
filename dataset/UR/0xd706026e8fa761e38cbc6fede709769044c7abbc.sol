 

pragma solidity >=0.4.24;
 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 




 
contract Ownable {
    address public owner;
    address public pendingOwner;


    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Account is not owner");
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "Account is not pending owner");
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Empty address");
        pendingOwner = _newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 





 
contract AllowanceSheet is Ownable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

 





 
contract BalanceSheet is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
    }

    function addTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = totalSupply.add(_value);
    }

    function subTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = totalSupply.sub(_value);
    }

    function setTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = _value;
    }
}

 





 
contract TokenStorage {
     
    BalanceSheet public balances;
    AllowanceSheet public allowances;


    string public name;    
    uint8  public decimals;         
    string public symbol;    

     
    constructor (address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) public {
        balances = BalanceSheet(_balances);
        allowances = AllowanceSheet(_allowances);

        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }

     
    function claimBalanceOwnership() public {
        balances.claimOwnership();
    }

     
    function claimAllowanceOwnership() public {
        allowances.claimOwnership();
    }
}

 

pragma solidity ^0.4.24;


 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 








 
contract AkropolisBaseToken is ERC20, TokenStorage, Ownable {
    using SafeMath for uint256;

     
    event Mint(address indexed to, uint256 value);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor (address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) public 
    TokenStorage(_balances, _allowances, _name, _decimals, _symbol) {}

     

    modifier canMint() {
        require(!isMintingFinished());
        _;
    }

     

    function mint(address _to, uint256 _amount) public onlyOwner canMint {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
    }


    function isMintingFinished() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Minting", "mint"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }


    function setMintingFinished(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Minting", "mint"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function mintFinished() public onlyOwner {
        setMintingFinished(true);
        emit MintFinished();
    }


    function approve(address _spender, uint256 _value) 
    public returns (bool) {
        allowances.setAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(msg.sender),"not enough balance to transfer");

        balances.subBalance(msg.sender, _amount);
        balances.addBalance(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) 
    public returns (bool) {
        require(_amount <= allowance(_from, msg.sender),"not enough allowance to transfer");
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(_from),"not enough balance to transfer");
        
        allowances.subAllowance(_from, msg.sender, _amount);
        balances.addBalance(_to, _amount);
        balances.subBalance(_from, _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
    function balanceOf(address who) public view returns (uint256) {
        return balances.balanceOf(who);
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances.allowanceOf(owner, spender);
    }

     
    function totalSupply() public view returns (uint256) {
        return balances.totalSupply();
    }


     

    function _burn(address _tokensOf, uint256 _amount) internal {
        require(_amount <= balanceOf(_tokensOf),"not enough balance to burn");
         
         
        balances.subBalance(_tokensOf, _amount);
        balances.subTotalSupply(_amount);
        emit Burn(_tokensOf, _amount);
        emit Transfer(_tokensOf, address(0), _amount);
    }

    function _mint(address _to, uint256 _amount) internal {
        balances.addTotalSupply(_amount);
        balances.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

}

 




 

contract Lockable is Ownable {
	 
	event Unlocked();
	event Locked();

	 
	 
	modifier whenUnlocked() {
		require(!isLocked(), "Contact is locked");
		_;
	}

	 
	function lock() public  onlyOwner {
		setLock(true);
		emit Locked();
	}

	 
	 
	function unlock() public onlyOwner  {
		setLock(false);
		emit Unlocked();
	}

	function setLock(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Lockable", "lock"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function isLocked() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Lockable", "lock"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }

}

 





 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

     
    modifier whenNotPaused() {
        require(!isPaused(), "Contract is paused");
        _;
    }

     
    modifier whenPaused() {
        require(isPaused(), "Contract is not paused");
        _;
    }

     
    function pause() public onlyOwner  whenNotPaused  {
        setPause(true);
        emit Pause();
    }

     
    function unpause() public onlyOwner  whenPaused {
        setPause(false);
        emit Unpause();
    }

    function setPause(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Pausable", "pause"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function isPaused() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Pausable", "pause"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }
}

 



 
 
contract Whitelist is Ownable {
    event AddToWhitelist(address indexed to);
    event RemoveFromWhitelist(address indexed to);
    event EnableWhitelist();
    event DisableWhitelist();
    event AddPermBalanceToWhitelist(address indexed to, uint256 balance);
    event RemovePermBalanceToWhitelist(address indexed to);

    mapping(address => bool) internal whitelist;
    mapping (address => uint256) internal permBalancesForWhitelist;

     
    modifier onlyWhitelist() {
        if (isWhitelisted() == true) {
            require(whitelist[msg.sender] == true, "Address is not in whitelist");
        }
        _;
    }

     
    modifier checkPermBalanceForWhitelist(uint256 value) {
        if (isWhitelisted() == true) {
            require(permBalancesForWhitelist[msg.sender]==0 || permBalancesForWhitelist[msg.sender]>=value, "Not permitted balance for transfer");
        }
        
        _;
    }

     

    function addPermBalanceToWhitelist(address _owner, uint256 _balance) public onlyOwner {
        permBalancesForWhitelist[_owner] = _balance;
        emit AddPermBalanceToWhitelist(_owner, _balance);
    }

     
    function removePermBalanceToWhitelist(address _owner) public onlyOwner {
        permBalancesForWhitelist[_owner] = 0;
        emit RemovePermBalanceToWhitelist(_owner);
    }
   
     

    function enableWhitelist() public onlyOwner {
        setWhitelisted(true);
        emit EnableWhitelist();
    }


     
    function disableWhitelist() public onlyOwner {
        setWhitelisted(false);
        emit DisableWhitelist();
    }

     
    function addToWhitelist(address _address) public onlyOwner  {
        whitelist[_address] = true;
        emit AddToWhitelist(_address);
    }

     
    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemoveFromWhitelist(_address);
    }


     

    function setWhitelisted(bool value) internal {
        bytes32 slot = keccak256(abi.encode("Whitelist", "whitelisted"));
        uint256 v = value ? 1 : 0;
        assembly {
            sstore(slot, v)
        }
    }

    function isWhitelisted() public view returns (bool) {
        bytes32 slot = keccak256(abi.encode("Whitelist", "whitelisted"));
        uint256 v;
        assembly {
            v := sload(slot)
        }
        return v != 0;
    }
}

 








 
contract AkropolisToken is AkropolisBaseToken, Pausable, Lockable, Whitelist {
    using SafeMath for uint256;

     

    constructor (address _balances, address _allowances, string _name, uint8 _decimals, string _symbol) public 
    AkropolisBaseToken(_balances, _allowances, _name, _decimals, _symbol) {}

     

     

    function mint(address _to, uint256 _amount) public {
        super.mint(_to, _amount);
    }

    function burn(uint256 _amount) public whenUnlocked  {
        super.burn(_amount);
    }

     
    function approve(address _spender, uint256 _value) 
    public whenNotPaused  whenUnlocked returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) 
    public whenNotPaused returns (bool) {
        increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    public whenNotPaused returns (bool) {
        decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function transfer(address _to, uint256 _amount) public whenNotPaused onlyWhitelist checkPermBalanceForWhitelist(_amount) returns (bool) {
        return super.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) 
    public whenNotPaused onlyWhitelist checkPermBalanceForWhitelist(_amount) returns (bool) {
        return super.transferFrom(_from, _to, _amount);
    }


     
    
    function decreaseApprovalAllArgs(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowances.allowanceOf(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            allowances.setAllowance(_tokenHolder, _spender, 0);
        } else {
            allowances.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder, _spender, allowances.allowanceOf(_tokenHolder, _spender));
    }

    function increaseApprovalAllArgs(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        allowances.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowances.allowanceOf(_tokenHolder, _spender));
    }
}