 

pragma solidity ^0.5.7;

 
 
 
 
 
 

 
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
        address __previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(__previousOwner, newOwner);
    }

     
    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount);
        assert(_token.transfer(receiver, amount));
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


 
contract WesionAirdrop is Ownable {
    using SafeMath for uint256;

    IERC20 public wesion;

    uint256 private _wei_min;

    mapping(address => bool) public _airdopped;

    event Donate(address indexed account, uint256 amount);

     
    function wei_min() public view returns (uint256) {
        return _wei_min;
    }

     
    constructor() public {
        wesion = IERC20(0x2c1564A74F07757765642ACef62a583B38d5A213);
    }

     
    function () external payable {
        require(_airdopped[msg.sender] != true);
        require(msg.sender.balance >= _wei_min);

        uint256 balance = wesion.balanceOf(address(this));
        require(balance > 0);

        uint256 wesionAmount = 100;
        wesionAmount = wesionAmount.add(uint256(keccak256(abi.encode(now, msg.sender, now))) % 100).mul(10 ** 6);

        if (wesionAmount <= balance) {
            assert(wesion.transfer(msg.sender, wesionAmount));
        } else {
            assert(wesion.transfer(msg.sender, balance));
        }

        if (msg.value > 0) {
            emit Donate(msg.sender, msg.value);
        }
    }

     
    function setWeiMin(uint256 value) external onlyOwner {
        _wei_min = value;
    }

     
    function setWesionAddress(address _WesionAddr) public onlyOwner {
        wesion = IERC20(_WesionAddr);
    }
}