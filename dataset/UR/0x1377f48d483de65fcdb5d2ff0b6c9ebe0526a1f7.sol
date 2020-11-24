 

pragma solidity ^0.5.11;

 
 
 
 
 
 
 
 
 


 
library SafeMath256 {
     
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
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 
library Roles {
    struct Role {
        mapping(address => bool) bearer;
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


 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


 
interface IAllocation {
    function reservedOf(address account) external view returns (uint256);
}


 
interface IVoken2 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mintWithAllocation(address account, uint256 amount, address allocationContract) external returns (bool);
}


 
interface VokenPublicSale {
    function queryAccount(address account) external view returns (
        uint256 vokenIssued,
        uint256 vokenBonus,
        uint256 vokenReferral,
        uint256 vokenReferrals,
        uint256 weiPurchased,
        uint256 weiRewarded);
}


 
contract Ownable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);


     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address currentOwner, address newOwner) {
        currentOwner = _owner;
        newOwner = _newOwner;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _newOwner = newOwner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner address");
        require(msg.sender != address(0), "Ownable: caller is the zero address");

        emit OwnershipAccepted(_owner, msg.sender);
        _owner = msg.sender;
        _newOwner = address(0);
    }

     
    function rescueTokens(address tokenAddr, address recipient, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(recipient != address(0), "Rescue: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount, "Rescue: amount exceeds balance");
        _token.transfer(recipient, amount);
    }

     
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Withdraw: recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "Withdraw: amount exceeds balance");
        recipient.transfer(amount);
    }
}


 
contract VokenOffer is Ownable, IAllocation {
    using SafeMath256 for uint256;
    using Roles for Roles.Role;

    IVoken2 private _VOKEN = IVoken2(0xFfFAb974088Bd5bF3d7E6F522e93Dd7861264cDB);
    VokenPublicSale private _PUBLIC_SALE = VokenPublicSale(0xd4260e4Bfb354259F5e30279cb0D7F784Ea5f37A);

    Roles.Role private _proxies;

    mapping(address => bool) private _offered;
    mapping(address => uint256) private _allocations;
    mapping(address => uint256[]) private _rewards;
    mapping(address => uint256[]) private _sales;

    event Donate(address indexed account, uint256 amount);
    event ProxyAdded(address indexed account);
    event ProxyRemoved(address indexed account);


     
    modifier onlyProxy() {
        require(isProxy(msg.sender), "ProxyRole: caller does not have the Proxy role");
        _;
    }

     
    function isProxy(address account) public view returns (bool) {
        return _proxies.has(account);
    }

     
    function addProxy(address account) public onlyOwner {
        _proxies.add(account);
        emit ProxyAdded(account);
    }

     
    function removeProxy(address account) public onlyOwner {
        _proxies.remove(account);
        emit ProxyRemoved(account);
    }

     
    function allocation(address account) public view returns (uint256 amount, uint256[] memory sales, uint256[] memory rewards) {
        amount = _allocations[account];
        sales = _sales[account];
        rewards = _rewards[account];
    }

     
    function reservedOf(address account) public view returns (uint256 reserved) {
        reserved = _allocations[account];

        (,,, uint256 __vokenReferrals,,) = _PUBLIC_SALE.queryAccount(account);

        for (uint256 i = 0; i < _sales[account].length; i++) {
            if (__vokenReferrals >= _sales[account][i] && reserved >= _rewards[account][i]) {
                reserved = reserved.sub(_rewards[account][i]);
                break;
            }
        }
    }


     
    constructor () public {
        addProxy(msg.sender);
    }

     
    function() external payable {
        if (msg.value > 0) {
            emit Donate(msg.sender, msg.value);
        }
    }

     
    function offer(address account, uint256 amount, uint256[] memory sales, uint256[] memory rewards) public onlyProxy {
        require(!_offered[account], "VokenOffer: have already sent offer to this account");
        require(sales.length == rewards.length, "VokenOffer: length is not match (sales and rewards)");

        _offered[account] = true;
        _allocations[account] = amount;
        _sales[account] = sales;
        _rewards[account] = rewards;

        assert(_VOKEN.mintWithAllocation(account, amount, address(this)));
    }
}