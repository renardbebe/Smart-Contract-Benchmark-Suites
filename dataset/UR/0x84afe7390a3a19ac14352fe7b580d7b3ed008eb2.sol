 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract Administratable is Ownable {

     
    mapping (address => bool) public administrators;

     
    event AdminAdded(address indexed addedAdmin, address indexed addedBy);
    event AdminRemoved(address indexed removedAdmin, address indexed removedBy);

     
    modifier onlyAdministrator() {
        require(isAdministrator(msg.sender), "Calling account is not an administrator.");
        _;
    }

     
    function isAdministrator(address addressToTest) public view returns (bool) {
        return administrators[addressToTest];
    }

     
    function addAdmin(address adminToAdd) public onlyOwner {
         
        require(administrators[adminToAdd] == false, "Account to be added to admin list is already an admin");

         
        administrators[adminToAdd] = true;

         
        emit AdminAdded(adminToAdd, msg.sender);
    }

     
    function removeAdmin(address adminToRemove) public onlyOwner {
         
        require(administrators[adminToRemove] == true, "Account to be removed from admin list is not already an admin");

         
        administrators[adminToRemove] = false;

         
        emit AdminRemoved(adminToRemove, msg.sender);
    }
}

 
contract Whitelistable is Administratable {
     
    uint8 constant NO_WHITELIST = 0;

     
     
    mapping (address => uint8) public addressWhitelists;

     
     
    mapping(uint8 => mapping (uint8 => bool)) public outboundWhitelistsEnabled;

     
    event AddressAddedToWhitelist(address indexed addedAddress, uint8 indexed whitelist, address indexed addedBy);
    event AddressRemovedFromWhitelist(address indexed removedAddress, uint8 indexed whitelist, address indexed removedBy);
    event OutboundWhitelistUpdated(address indexed updatedBy, uint8 indexed sourceWhitelist, uint8 indexed destinationWhitelist, bool from, bool to);

     
    function addToWhitelist(address addressToAdd, uint8 whitelist) public onlyAdministrator {
         
        require(whitelist != NO_WHITELIST, "Invalid whitelist ID supplied");

         
        uint8 previousWhitelist = addressWhitelists[addressToAdd];

         
        addressWhitelists[addressToAdd] = whitelist;        

         
        if(previousWhitelist != NO_WHITELIST) {
             
            emit AddressRemovedFromWhitelist(addressToAdd, previousWhitelist, msg.sender);
        }

         
        emit AddressAddedToWhitelist(addressToAdd, whitelist, msg.sender);
    }

     
    function removeFromWhitelist(address addressToRemove) public onlyAdministrator {
         
        uint8 previousWhitelist = addressWhitelists[addressToRemove];

         
        addressWhitelists[addressToRemove] = NO_WHITELIST;

         
        emit AddressRemovedFromWhitelist(addressToRemove, previousWhitelist, msg.sender);
    }

     
    function updateOutboundWhitelistEnabled(uint8 sourceWhitelist, uint8 destinationWhitelist, bool newEnabledValue) public onlyAdministrator {
         
        bool oldEnabledValue = outboundWhitelistsEnabled[sourceWhitelist][destinationWhitelist];

         
        outboundWhitelistsEnabled[sourceWhitelist][destinationWhitelist] = newEnabledValue;

         
        emit OutboundWhitelistUpdated(msg.sender, sourceWhitelist, destinationWhitelist, oldEnabledValue, newEnabledValue);
    }

     
    function checkWhitelistAllowed(address sender, address receiver) public view returns (bool) {
         
        uint8 senderWhiteList = addressWhitelists[sender];
        uint8 receiverWhiteList = addressWhitelists[receiver];

         
        if(senderWhiteList == NO_WHITELIST || receiverWhiteList == NO_WHITELIST){
            return false;
        }

         
        return outboundWhitelistsEnabled[senderWhiteList][receiverWhiteList];
    }
}

 
contract Restrictable is Ownable {
     
    bool private _restrictionsEnabled = true;

     
    event RestrictionsDisabled(address indexed owner);

     
    function isRestrictionEnabled() public view returns (bool) {
        return _restrictionsEnabled;
    }

     
    function disableRestrictions() public onlyOwner {
        require(_restrictionsEnabled, "Restrictions are already disabled.");
        
         
        _restrictionsEnabled = false;

         
        emit RestrictionsDisabled(msg.sender);
    }
}

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC1404 is IERC20 {
     
     
     
     
     
     
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);

     
     
     
     
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string memory);
}

 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

 
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
     
     
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
     
     
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

interface IFundsDistributionToken {

	 
	function withdrawableFundsOf(address owner) external view returns (uint256);

	 
	function withdrawFunds() external;

	 
	event FundsDistributed(address indexed by, uint256 fundsDistributed);

	 
	event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn);
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 
contract FundsDistributionToken is IFundsDistributionToken, ERC20Detailed, ERC20Mintable {

	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;

	 
	uint256 constant internal pointsMultiplier = 2**128;
	uint256 internal pointsPerShare;

	mapping(address => int256) internal pointsCorrection;
	mapping(address => uint256) internal withdrawnFunds;


	constructor (
		string memory name, 
		string memory symbol
	) 
		public 
		ERC20Detailed(name, symbol, 18) 
	{}

	 
	function _distributeFunds(uint256 value) internal {
		require(totalSupply() > 0, "FundsDistributionToken._distributeFunds: SUPPLY_IS_ZERO");

		if (value > 0) {
			pointsPerShare = pointsPerShare.add(
				value.mul(pointsMultiplier) / totalSupply()
			);
			emit FundsDistributed(msg.sender, value);
		}
	}

	 
	function _prepareWithdraw() internal returns (uint256) {
		uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);

		withdrawnFunds[msg.sender] = withdrawnFunds[msg.sender].add(_withdrawableDividend);

		emit FundsWithdrawn(msg.sender, _withdrawableDividend);

		return _withdrawableDividend;
	}

	 
	function withdrawableFundsOf(address _owner) public view returns(uint256) {
		return accumulativeFundsOf(_owner).sub(withdrawnFunds[_owner]);
	}

	 
	function withdrawnFundsOf(address _owner) public view returns(uint256) {
		return withdrawnFunds[_owner];
	}

	 
	function accumulativeFundsOf(address _owner) public view returns(uint256) {
		return pointsPerShare.mul(balanceOf(_owner)).toInt256Safe()
			.add(pointsCorrection[_owner]).toUint256Safe() / pointsMultiplier;
	}

	 
	function _transfer(address from, address to, uint256 value) internal {
		super._transfer(from, to, value);

		int256 _magCorrection = pointsPerShare.mul(value).toInt256Safe();
		pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);
		pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);
	}

	 
	function _mint(address account, uint256 value) internal {
		super._mint(account, value);

		pointsCorrection[account] = pointsCorrection[account]
			.sub( (pointsPerShare.mul(value)).toInt256Safe() );
	}

	 
	function _burn(address account, uint256 value) internal {
		super._burn(account, value);

		pointsCorrection[account] = pointsCorrection[account]
			.add( (pointsPerShare.mul(value)).toInt256Safe() );
	}
}

contract SimpleRestrictedFDT is FundsDistributionToken, ERC1404, Whitelistable, Restrictable {
     

	using SafeMathUint for uint256;
	using SafeMathInt for int256;
	
	  
    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant FAILURE_NON_WHITELIST = 1;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant FAILURE_NON_WHITELIST_MESSAGE = "The transfer was restricted due to white list configuration.";
    string public constant UNKNOWN_ERROR = "Unknown Error Code";

	 
	IERC20 public fundsToken;

	 
	uint256 public fundsTokenBalance;

	modifier onlyFundsToken () {
		require(msg.sender == address(fundsToken), "FDT_ERC20Extension.onlyFundsToken: UNAUTHORIZED_SENDER");
		_;
	}

	constructor(
		string memory name, 
		string memory symbol,
		IERC20 _fundsToken,
        address[] memory initialOwner,
        uint256[] memory initialAmount
	) 
		public 
		FundsDistributionToken(name, symbol)
	{
		require(address(_fundsToken) != address(0), "SimpleRestrictedFDT: INVALID_FUNDS_TOKEN_ADDRESS");

        for (uint256 i = 0; i < initialOwner.length; i++) {
		    _mint(initialOwner[i], initialAmount[i]);
        }

		fundsToken = _fundsToken;
        _addMinter(initialOwner[0]);
        _transferOwnership(initialOwner[0]);
	}

     
    function detectTransferRestriction (address from, address to, uint256)
        public
        view
        returns (uint8)
    {               
         
         
        if(!isRestrictionEnabled()) {
            return SUCCESS_CODE;
        }

         
        if(from == owner()) {
            return SUCCESS_CODE;
        }

         
         
        if(!checkWhitelistAllowed(from, to)) {
            return FAILURE_NON_WHITELIST;
        }

         
        return SUCCESS_CODE;
    }
    
     
    function messageForTransferRestriction (uint8 restrictionCode)
        public
        view
        returns (string memory)
    {
        if (restrictionCode == SUCCESS_CODE) {
            return SUCCESS_MESSAGE;
        }

        if (restrictionCode == FAILURE_NON_WHITELIST) {
            return FAILURE_NON_WHITELIST_MESSAGE;
        }

         
        return UNKNOWN_ERROR;
    }

     
    modifier notRestricted (address from, address to, uint256 value) {        
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

     
    function transfer (address to, uint256 value)
        public
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        success = super.transfer(to, value);
    }

     
    function transferFrom (address from, address to, uint256 value)
        public
        notRestricted(from, to, value)
        returns (bool success)
    {
        success = super.transferFrom(from, to, value);
    }

	 
	function withdrawFunds() 
		external 
	{
		uint256 withdrawableFunds = _prepareWithdraw();

		require(fundsToken.transfer(msg.sender, withdrawableFunds), "FDT_ERC20Extension.withdrawFunds: TRANSFER_FAILED");

		_updateFundsTokenBalance();
	}

	 
	function _updateFundsTokenBalance() internal returns (int256) {
		uint256 prevFundsTokenBalance = fundsTokenBalance;

		fundsTokenBalance = fundsToken.balanceOf(address(this));

		return int256(fundsTokenBalance).sub(int256(prevFundsTokenBalance));
	}

	 
	function updateFundsReceived() external {
		int256 newFunds = _updateFundsTokenBalance();

		if (newFunds > 0) {
			_distributeFunds(newFunds.toUint256Safe());
		}
	}
}

contract SimpleRestrictedFDTFactory {
     
    
    SimpleRestrictedFDT private SRFDT;
    
    address[] public tokens;
    
    event Deployed(address indexed SRFDT, address indexed owner);
    
    function newSRFDT(
        string memory name, 
		string memory symbol,
		IERC20 _fundsToken,
		address[] memory initialOwner,
		uint256[] memory initialAmount) public {
       
        SRFDT = new SimpleRestrictedFDT(
            name, 
            symbol, 
            _fundsToken,
            initialOwner,
            initialAmount);
        
        tokens.push(address(SRFDT));
        
        emit Deployed(address(SRFDT), initialOwner[0]);

    }
    
    function getTokenCount() public view returns (uint256 tokenCount) {
        return tokens.length;
    }
}