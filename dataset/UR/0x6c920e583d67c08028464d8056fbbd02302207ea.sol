 

 

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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity 0.5.0;


 
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

 

pragma solidity 0.5.0;




 
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

 

pragma solidity 0.5.0;


 
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

 

pragma solidity 0.5.0;


contract ERC1404 is IERC20 {
     
     
     
     
     
     
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);

     
     
     
     
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string memory);
}

 

pragma solidity 0.5.0;






contract GenericWhitelistToken is ERC1404, ERC20, ERC20Detailed, Whitelistable, Restrictable {

     
    string constant TOKEN_NAME = "Generic White List";
    string constant TOKEN_SYMBOL = "GWL";
    uint8 constant TOKEN_DECIMALS = 18;

     
    uint256 constant BILLION = 1000000000;
    uint256 constant TOKEN_SUPPLY = 50 * BILLION * (10 ** uint256(TOKEN_DECIMALS));

     
    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant FAILURE_NON_WHITELIST = 1;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant FAILURE_NON_WHITELIST_MESSAGE = "The transfer was restricted due to white list configuration.";
    string public constant UNKNOWN_ERROR = "Unknown Error Code";


     
    constructor(address owner) public 
        ERC20Detailed(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS)
    {		
        _transferOwnership(owner);
        _mint(owner, TOKEN_SUPPLY);
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
}