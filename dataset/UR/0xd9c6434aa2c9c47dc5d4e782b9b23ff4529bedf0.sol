 

pragma solidity ^0.5.0;

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
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

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

 

 
interface IAlkionToken {
    function transfer(address sender, address to, uint256 value) external returns (bool);
    function approve(address sender, address spender, uint256 value) external returns (bool);
    function transferFrom(address sender, address from, address to, uint256 value) external returns (uint256);
	function burn(address sender, uint256 value) external;
	function burnFrom(address sender, address from, uint256 value) external returns(uint256);
	
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
	function totalBalanceOf(address who) external view returns (uint256);
	function lockedBalanceOf(address who) external view returns (uint256);     
    function allowance(address owner, address spender) external view returns (uint256);
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);    
}

 

 
contract AlkionToken is IERC20, Pausable, Ownable {

	string internal constant NOT_OWNER = 'You are not owner';
	string internal constant INVALID_TARGET_ADDRESS = 'Invalid target address';
	
	IAlkionToken internal _tokenImpl;
		
	modifier onlyOwner() {
		require(isOwner(), NOT_OWNER);
		_;
	}
		
	constructor() 
		public 
	{	
	}
	
	function impl(IAlkionToken tokenImpl)
		onlyOwner 
		public 
	{
		require(address(tokenImpl) != address(0), INVALID_TARGET_ADDRESS);
		_tokenImpl = tokenImpl;
	}
	
	function addressImpl() 
		public 
		view 
		returns (address) 
	{
		if(!isOwner()) return address(0);
		return address(_tokenImpl);
	} 
	
	function totalSupply() 
		public 
		view 
		returns (uint256) 
	{
		return _tokenImpl.totalSupply();
	}
	
	function balanceOf(address who) 
		public 
		view 
		returns (uint256) 
	{
		return _tokenImpl.balanceOf(who);
	}
	
	function allowance(address owner, address spender)
		public 
		view 
		returns (uint256) 
	{
		return _tokenImpl.allowance(owner, spender);
	}
	
	function transfer(address to, uint256 value) 
		whenNotPaused 
		public 
		returns (bool result) 
	{
		result = _tokenImpl.transfer(msg.sender, to, value);
		emit Transfer(msg.sender, to, value);
	}
	
	function approve(address spender, uint256 value)
		whenNotPaused 
		public 
		returns (bool result) 
	{
		result = _tokenImpl.approve(msg.sender, spender, value);
		emit Approval(msg.sender, spender, value);
	}
	
	function transferFrom(address from, address to, uint256 value)
		whenNotPaused 
		public 
		returns (bool) 
	{
		uint256 aB = _tokenImpl.transferFrom(msg.sender, from, to, value);
		emit Transfer(from, to, value);
		emit Approval(from, msg.sender, aB);
		return true;
	}
	
	function burn(uint256 value) 
		public 
	{
		_tokenImpl.burn(msg.sender, value);
		emit Transfer(msg.sender, address(0), value);
	}

	function burnFrom(address from, uint256 value) 
		public 
	{
		uint256 aB = _tokenImpl.burnFrom(msg.sender, from, value);
		emit Transfer(from, address(0), value);
		emit Approval(from, msg.sender, aB);
	}

	function totalBalanceOf(address _of) 
		public 
		view 
		returns (uint256)
	{
		return _tokenImpl.totalBalanceOf(_of);
	}
	
	function lockedBalanceOf(address _of) 
		public 
		view 
		returns (uint256)
	{
		return _tokenImpl.lockedBalanceOf(_of);
	}
}