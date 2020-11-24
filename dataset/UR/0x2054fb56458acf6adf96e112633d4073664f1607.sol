 

pragma solidity ^0.5.7;

 
 
 


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

     
    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0));

        uint256 balance = address(this).balance;

        require(balance >= amount);
        to.transfer(amount);
    }
}


 
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}


 
contract TGTeamFund is Ownable{
    using SafeMath for uint256;

    IERC20 public TG;

    uint256 private _till = 1671606000;
    uint256 private _TGAmount = 4200000000000000;  
    uint256 private _3mo = 2592000;  

    uint256[10] private _freezedPct = [
        100,     
        90,      
        80,      
        70,      
        60,      
        50,      
        40,      
        30,      
        20,      
        10       
    ];

    event Donate(address indexed account, uint256 amount);


     
    constructor() public {}

     
    function TGFreezed() public view returns (uint256) {
        uint256 __freezed;

        if (now > _till) {
            uint256 __qrPassed = now.sub(_till).div(_3mo);

            if (__qrPassed >= 10) {
                __freezed = 0;
            }
            else {
                __freezed = _TGAmount.mul(_freezedPct[__qrPassed]).div(100);
            }

            return __freezed;
        }

        return _TGAmount;
    }

     
    function () external payable {
        emit Donate(msg.sender, msg.value);
    }

     
    function transferTG(address to, uint256 amount) external onlyOwner {
        uint256 __freezed = TGFreezed();
        uint256 __released = TG.balanceOf(address(this)).sub(__freezed);

        require(__released >= amount);

        assert(TG.transfer(to, amount));
    }

     
    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(TG != _token);
        require(receiver != address(0));

        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount);
        assert(_token.transfer(receiver, amount));
    }

     
    function setTGAddress(address _TGAddr) public onlyOwner {
        TG = IERC20(_TGAddr);
    }

}