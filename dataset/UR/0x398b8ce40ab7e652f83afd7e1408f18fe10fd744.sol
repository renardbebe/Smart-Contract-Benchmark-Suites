 

pragma solidity 0.5.10;

 
library SafeMath {

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

}

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

 
contract BlackListedRole is Ownable {
    using Roles for Roles.Role;

    event BlackListedAdded(address indexed account);
    event BlackListedRemoved(address indexed account);

    Roles.Role private _blackListeds;

    modifier onlyBlackListed() {
        require(isBlackListed(msg.sender), "Caller has no permission");
        _;
    }

    function isBlackListed(address account) public view returns (bool) {
        return(_blackListeds.has(account) || isOwner(account));
    }

    function addBlackListed(address account) public onlyOwner {
        _blackListeds.add(account);
        emit BlackListedAdded(account);
    }

    function removeBlackListed(address account) public onlyOwner {
        _blackListeds.remove(account);
        emit BlackListedRemoved(account);
    }
}

 
interface IGRSHAToken {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function amountOfHolders() external view returns (uint256);
    function holders() external view returns (address payable[] memory);

    function pause() external;
    function unpause() external;
}

 
contract Distribution is BlackListedRole {
    using SafeMath for uint256;

    IGRSHAToken token;

    uint256 public index;
    uint256 public maxShare;
    
    uint256 sendingAmount;

    event Payed(address recipient, uint256 amount);
    event Error(address recipient);
    event Success();
    event Suspended();

    constructor(address tokenAddr) public {
        token = IGRSHAToken(tokenAddr);
    }

    function() external payable {
        if (msg.value == 0) {
            if (sendingAmount == 0) {
                sendingAmount = address(this).balance;
            }
            massSending(sendingAmount);
        }
    }

    function massSending(uint256 weiAmount) public onlyOwner {
        require(weiAmount != 0);
        address payable[] memory addresses = token.holders();

        for (uint i = index; i < addresses.length; i++) {
            uint256 amount = getShare(addresses[i], weiAmount);
            if (!isBlackListed(addresses[i]) && amount > 0 && addresses[i].send(amount)) {
                emit Payed(addresses[i], amount);
            } else {
                emit Error(addresses[i]);
            }

            if (i == addresses.length - 1) {
                token.unpause();
                index = 0;
                sendingAmount = 0;
                emit Success();
                break;
            }

            if (gasleft() <= 50000) {
                token.pause();
                index = i + 1;
                emit Suspended();
                break;
            }
        }
    }

    function setIndex(uint256 newIndex) public onlyOwner {
        index = newIndex;
    }

    function setMaxShare(uint256 newMaxShare) public onlyOwner {
        maxShare = newMaxShare;
    }

    function withdrawBalance() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {
        uint256 amount = IGRSHAToken(ERC20Token).balanceOf(address(this));
        IGRSHAToken(ERC20Token).transfer(recipient, amount);
    }

    function getShare(address account, uint256 weiAmount) public view returns(uint256) {
        uint256 share = (token.balanceOf(account)).div(1e15).mul(weiAmount).div(token.totalSupply().div(1e15));
        if (share > maxShare && maxShare != 0) {
            return maxShare;
        } else {
            return share;
        }
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

}