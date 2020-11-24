 

pragma solidity ^0.5.2;

 
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

contract TokenSwap is Ownable {
    using SafeMath for uint256;

    IERC20 private _fromToken;
    IERC20 private _toToken;
    uint256 private _rate;

    event Swap(address indexed sender, uint256 indexed fromTokenAmount, uint256 indexed toTokenAmount);
    event Deactivate(uint256 indexed amount);

    constructor(
        address fromToken,
        address toToken,
        uint256 rate
    ) Ownable() public {
        require(fromToken != address(0x0) && toToken != address(0x0), "token address can not be 0.");
        require(rate > 0, "swap rate can not be 0.");

        _fromToken = IERC20(fromToken);
        _toToken = IERC20(toToken);
        _rate = rate;
    }

    function swap() external returns (bool) {
        uint256 allowance = _fromToken.allowance(msg.sender, address(this));
        require(allowance > 0, "sender need to approve token to swap contract.");

        if (_fromToken.transferFrom(msg.sender, address(0x0), allowance)) {
             
            uint256 swappedValue = allowance.add(999);
            swappedValue = swappedValue.div(_rate);

            require(_toToken.transferFrom(Ownable.owner(), msg.sender, swappedValue));

            emit Swap(msg.sender, allowance, swappedValue);
        }

        return true;
    }

    function deactivate() external onlyOwner {
        uint256 reserve = _fromToken.balanceOf(address(this));
        require(_fromToken.transfer(address(0x0), reserve));

        emit Deactivate(reserve);
    }
}