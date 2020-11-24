 

 

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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
interface ISRC20 {

    event RestrictionsAndRulesUpdated(address restrictions, address rules);

    function transferToken(address to, uint256 value, uint256 nonce, uint256 expirationTime,
        bytes32 msgHash, bytes calldata signature) external returns (bool);
    function transferTokenFrom(address from, address to, uint256 value, uint256 nonce,
        uint256 expirationTime, bytes32 hash, bytes calldata signature) external returns (bool);
    function getTransferNonce() external view returns (uint256);
    function getTransferNonce(address account) external view returns (uint256);
    function executeTransfer(address from, address to, uint256 value) external returns (bool);
    function updateRestrictionsAndRules(address restrictions, address rules) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 value) external returns (bool);
    function decreaseAllowance(address spender, uint256 value) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface ISRC20Managed {
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    function burn(address account, uint256 value) external returns (bool);
    function mint(address account, uint256 value) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
contract ISRC20Roles {
    function isAuthority(address account) external view returns (bool);
    function removeAuthority(address account) external returns (bool);
    function addAuthority(address account) external returns (bool);

    function isDelegate(address account) external view returns (bool);
    function addDelegate(address account) external returns (bool);
    function removeDelegate(address account) external returns (bool);

    function manager() external view returns (address);
    function isManager(address account) external view returns (bool);
    function transferManagement(address newManager) external returns (bool);
    function renounceManagement() external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface IManager {
 
    event SRC20SupplyMinted(address src20, address swmAccount, uint256 swmValue, uint256 src20Value);
    event SRC20StakeIncreased(address src20, address swmAccount, uint256 swmValue);
    event SRC20StakeDecreased(address src20, address swmAccount, uint256 swmValue);

    function mintSupply(address src20, address swmAccount, uint256 swmValue, uint256 src20Value) external returns (bool);
    function increaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function decreaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function renounceManagement(address src20) external returns (bool);
    function transferManagement(address src20, address newManager) external returns (bool);
    function calcTokens(address src20, uint256 swmValue) external view returns (uint256);

    function getStake(address src20) external view returns (uint256);
    function swmNeeded(address src20, uint256 srcValue) external view returns (uint256);
    function getSrc20toSwmRatio(address src20) external returns (uint256);
    function getTokenOwner(address src20) external view returns (address);
}

 

pragma solidity ^0.5.0;









 
contract Manager is IManager, Ownable {
    using SafeMath for uint256;

    event SRC20SupplyMinted(address src20, address swmAccount, uint256 swmValue, uint256 src20Value);
    event SRC20SupplyIncreased(address src20, address swmAccount, uint256 srcValue);
    event SRC20SupplyDecreased(address src20, address swmAccount, uint256 srcValue);

    mapping (address => SRC20) internal _registry;

    struct SRC20 {
        address owner;
        address roles;
        uint256 stake;
        address minter;
    }

    IERC20 private _swmERC20;

    constructor(address swmERC20) public {
        require(swmERC20 != address(0), 'SWM ERC20 is zero address');

        _swmERC20 = IERC20(swmERC20);
    }

    modifier onlyTokenOwner(address src20) {
        require(_isTokenOwner(src20), "Caller not token owner.");
        _;
    }

     
     
    modifier onlyMinter(address src20) {
        require(msg.sender == _registry[src20].minter, "Caller not token minter.");
        _;
    }

     
    function mintSupply(address src20, address swmAccount, uint256 swmValue, uint256 src20Value)
        onlyMinter(src20)
        external
        returns (bool)
    {
        require(swmAccount != address(0), "SWM account is zero");
        require(swmValue != 0, "SWM value is zero");
        require(src20Value != 0, "SRC20 value is zero");
        require(_registry[src20].owner != address(0), "SRC20 token contract not registered");

        _registry[src20].stake = _registry[src20].stake.add(swmValue);

        require(_swmERC20.transferFrom(swmAccount, address(this), swmValue));
        require(ISRC20Managed(src20).mint(_registry[src20].owner, src20Value));

        emit SRC20SupplyMinted(src20, swmAccount, swmValue, src20Value);

        return true;
    }

     
    function increaseSupply(address src20, address swmAccount, uint256 srcValue)
        external
        onlyTokenOwner(src20)
        returns (bool)
    {
        require(swmAccount != address(0), "SWM account is zero");
        require(srcValue != 0, "SWM value is zero");
        require(_registry[src20].owner != address(0), "SRC20 token contract not registered");

        uint256 swmValue = _swmNeeded(src20, srcValue);

        require(_swmERC20.transferFrom(swmAccount, address(this), swmValue));
        require(ISRC20Managed(src20).mint(_registry[src20].owner, srcValue));

        _registry[src20].stake = _registry[src20].stake.add(swmValue);
        emit SRC20SupplyIncreased(src20, swmAccount, swmValue);

        return true;
    }

     
    function decreaseSupply(address src20, address swmAccount, uint256 srcValue)
        external
        onlyTokenOwner(src20)
        returns (bool)
    {
        require(swmAccount != address(0), "SWM account is zero");
        require(srcValue != 0, "SWM value is zero");
        require(_registry[src20].owner != address(0), "SRC20 token contract not registered");

        uint256 swmValue = _swmNeeded(src20, srcValue);

        require(_swmERC20.transfer(swmAccount, swmValue));
        require(ISRC20Managed(src20).burn(_registry[src20].owner, srcValue));

        _registry[src20].stake = _registry[src20].stake.sub(swmValue);
        emit SRC20SupplyDecreased(src20, swmAccount, srcValue);

        return true;
    }

     
    function renounceManagement(address src20)
        external
        onlyOwner
        returns (bool)
    {
        require(_registry[src20].owner != address(0), "SRC20 token contract not registered");

        require(ISRC20Roles(_registry[src20].roles).renounceManagement());

        return true;
    }

     
    function transferManagement(address src20, address newManager)
        public
        onlyOwner
        returns (bool)
    {
        require(_registry[src20].owner != address(0), "SRC20 token contract not registered");
        require(newManager != address(0), "newManager address is zero");

        require(ISRC20Roles(_registry[src20].roles).transferManagement(newManager));

        return true;
    }

     
    function calcTokens(address src20, uint256 swmValue) external view returns (uint256) {
        return _calcTokens(src20, swmValue);
    }

     
    function swmNeeded(address src20, uint256 srcValue) external view returns (uint256) {
        return _swmNeeded(src20, srcValue);
    }

     
    function getSrc20toSwmRatio(address src20) external returns (uint256) {
        uint256 totalSupply = ISRC20(src20).totalSupply();
        return totalSupply.mul(10 ** 18).div(_registry[src20].stake);
    }

     
    function getStake(address src20) external view returns (uint256) {
        return _registry[src20].stake;
    }

     
    function getTokenOwner(address src20) external view returns (address) {
        return _registry[src20].owner;
    }

     
    function _calcTokens(address src20, uint256 swmValue) internal view returns (uint256) {
        require(src20 != address(0), "Token address is zero");
        require(swmValue != 0, "SWM value is zero");
        require(_registry[src20].owner != address(0), "SRC20 token contract not registered");

        uint256 totalSupply = ISRC20(src20).totalSupply();

        return swmValue.mul(totalSupply).div(_registry[src20].stake);
    }

    function _swmNeeded(address src20, uint256 srcValue) internal view returns (uint256) {
        uint256 totalSupply = ISRC20(src20).totalSupply();

        return srcValue.mul(_registry[src20].stake).div(totalSupply);
    }

     
    function _isTokenOwner(address src20) internal view returns (bool) {
        return msg.sender == _registry[src20].owner;
    }
}

 

pragma solidity ^0.5.0;

 
contract ISRC20Registry {
    event FactoryAdded(address account);
    event FactoryRemoved(address account);
    event SRC20Registered(address token, address tokenOwner);
    event SRC20Removed(address token);
    event MinterAdded(address minter);
    event MinterRemoved(address minter);

    function put(address token, address roles, address tokenOwner, address minter) external returns (bool);
    function remove(address token) external returns (bool);
    function contains(address token) external view returns (bool);

    function addMinter(address minter) external returns (bool);
    function getMinter(address src20) external view returns (address);
    function removeMinter(address minter) external returns (bool);

    function addFactory(address account) external returns (bool);
    function removeFactory(address account) external returns (bool);
}

 

pragma solidity ^0.5.0;






 
contract SRC20Registry is ISRC20Registry, Manager {
    using Roles for Roles.Role;

    Roles.Role private _factories;
    mapping (address => bool) _authorizedMinters;

     
    constructor(address swmERC20)
        Manager(swmERC20)
        public
    {
    }

     
    function addFactory(address account) external onlyOwner returns (bool) {
        require(account != address(0), "account is zero address");

        _factories.add(account);

        emit FactoryAdded(account);

        return true;
    }

     
    function removeFactory(address account) external onlyOwner returns (bool) {
        require(account != address(0), "account is zero address");

        _factories.remove(account);

        emit FactoryRemoved(account);

        return true;
    }

     
    function put(address token, address roles, address tokenOwner, address minter) external returns (bool) {
        require(token != address(0), "token is zero address");
        require(roles != address(0), "roles is zero address");
        require(tokenOwner != address(0), "tokenOwner is zero address");
        require(_factories.has(msg.sender), "factory not registered");
        require(_authorizedMinters[minter] == true, 'minter not authorized');

        _registry[token].owner = tokenOwner;
        _registry[token].roles = roles;
        _registry[token].minter = minter;

        emit SRC20Registered(token, tokenOwner);

        return true;
    }

     
    function remove(address token) external onlyOwner returns (bool) {
        require(token != address(0), "token is zero address");
        require(_registry[token].owner != address(0), "token not registered");

        delete _registry[token];

        emit SRC20Removed(token);

        return true;
    }

     
    function contains(address token) external view returns (bool) {
        return _registry[token].owner != address(0);
    }

     
    function addMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "minter is zero address");

        _authorizedMinters[minter] = true;

        emit MinterAdded(minter);

        return true;
    }

     
    function getMinter(address src20) external view returns (address) {
        return _registry[src20].minter;
    }

     
    function removeMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "minter is zero address");

        _authorizedMinters[minter] = false;

        emit MinterRemoved(minter);

        return true;
    }
}