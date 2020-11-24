 

pragma solidity 0.5.7;

 
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
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
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

 
contract RefStorage {
    function changeContracts(address contractAddr) external;
    function changePrize(uint256 newPrize) external;
    function changeInterval(uint256 newInterval) external;
    function newTicket() external;
    function addReferrer(address referrer) external;
    function sendBonus(address winner) external;
    function withdrawERC20(address ERC20Token, address recipient) external;
    function ticketsOf(address player) external view returns(uint256);
    function referrerOf(address player) external view returns(address);
    function transferOwnership(address newOwner) external;
}

 
contract GoldRubleBonusStorage is Ownable {

    IERC20 private _token;

    RefStorage private _refStorage;

    mapping (address => bool) admins;

    modifier restricted {
        require(admins[msg.sender] || isOwner());
        _;
    }

    constructor(address token, address refStorageAddr, address initialOwner) public Ownable(initialOwner) {
        _token = IERC20(token);
        _refStorage = RefStorage(refStorageAddr);
    }

    function setAdmins(address account, bool state) public onlyOwner {
        admins[account] = state;
    }

    function setToken(address token) public onlyOwner {
        _token = IERC20(token);
    }

    function setRefStorage(address refStorageAddr) public onlyOwner {
        _refStorage = RefStorage(refStorageAddr);
    }

    function sendBonus(address account, uint256 amount) public restricted {
        _token.transfer(account, amount);
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {
        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);
    }

     

    function RS_transferOwnership(address newOwner) external onlyOwner {
        _refStorage.transferOwnership(newOwner);
    }

    function RS_changeContracts(address contractAddr) external restricted {
        _refStorage.changeContracts(contractAddr);
    }

    function RS_changePrize(uint256 newPrize) external restricted {
        _refStorage.changePrize(newPrize);
    }

    function RS_changeInterval(uint256 newInterval) external restricted {
        _refStorage.changeInterval(newInterval);
    }

    function RS_newTicket() external restricted {
        _refStorage.newTicket();
    }

    function RS_addReferrer(address referrer) external restricted {
        _refStorage.addReferrer(referrer);
    }

    function RS_sendBonus(address winner) external restricted {
        _refStorage.sendBonus(winner);
    }

    function RS_withdrawERC20(address ERC20Token, address recipient) external restricted {
        _refStorage.withdrawERC20(ERC20Token, recipient);
    }

    function RS_ticketsOf(address player) external view returns(uint256) {
        _refStorage.ticketsOf(player);
    }

    function RS_referrerOf(address player) external view returns(address) {
        _refStorage.referrerOf(player);
    }

}