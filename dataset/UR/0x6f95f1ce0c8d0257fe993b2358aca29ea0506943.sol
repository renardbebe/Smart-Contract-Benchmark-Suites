 

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


 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
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


 
interface IVoken2 {
    function balanceOf(address owner) external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function whitelisted(address account) external view returns (bool);
}


 
contract Pausable is Ownable {
    bool private _paused;

    event Paused();
    event Unpaused();


     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

     
    function setPaused(bool value) external onlyOwner {
        _paused = value;

        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }
}


 
interface VokenPublicSale {
    function status() external view returns (uint16 stage,
                                             uint16 season,
                                             uint256 etherUsdPrice,
                                             uint256 vokenUsdPrice,
                                             uint256 shareholdersRatio);
}


 
contract Get1001Voken2 is Ownable, Pausable {
    using SafeMath256 for uint256;

     
    IVoken2 private _VOKEN = IVoken2(0xFfFAb974088Bd5bF3d7E6F522e93Dd7861264cDB);
    VokenPublicSale private _PUBLIC_SALE = VokenPublicSale(0xd4260e4Bfb354259F5e30279cb0D7F784Ea5f37A);

    uint256 private WEI_MIN = 1 ether;
    uint256 private VOKEN_PER_TX = 1001000000;  

    uint256 private _txs;

    mapping (address => bool) _got;

     
    function VOKEN() public view returns (IVoken2) {
        return _VOKEN;
    }

     
    function PUBLIC_SALE() public view returns (VokenPublicSale) {
        return _PUBLIC_SALE;
    }

     
    function txs() public view returns (uint256) {
        return _txs;
    }

     
    function () external payable whenNotPaused {
        require(msg.value >= WEI_MIN, "Get1001Voken2: sent less than 1 ether");
        require(!(_VOKEN.balanceOf(msg.sender) > 0), "Get1001Voken2: balance is greater than zero");
        require(!_VOKEN.whitelisted(msg.sender), "Get1001Voken2: already whitelisted");
        require(!_got[msg.sender], "Get1001Voken2: had got already");

        (, , uint256 __etherUsdPrice, uint256 __vokenUsdPrice, ) = _PUBLIC_SALE.status();
        __vokenUsdPrice = __vokenUsdPrice.mul(8).div(10);
        require(__etherUsdPrice > 0, "Voken2PublicSale2: empty ether price");

        uint256 __usd = VOKEN_PER_TX.mul(__vokenUsdPrice).div(1000000);
        uint256 __wei = __usd.mul(1 ether).div(__etherUsdPrice);

        require(msg.value >= __wei, "Get1001Voken2: ether is not enough");

        _txs = _txs.add(1);
        _got[msg.sender] = true;

        msg.sender.transfer(msg.value.sub(__wei));
        assert(_VOKEN.mint(msg.sender, VOKEN_PER_TX));
    }
}