 

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


 
contract TGEarlyInvestorsFund is Ownable{
    using SafeMath for uint256;

    IERC20 public TG;
    address TG_Addr = address(0);

    uint32 private _till = 1592722800;
    uint256 private _holdings;

    mapping (address => uint256) private _investors;

    event InvestorRegistered(address indexed account, uint256 amount);
    event Donate(address indexed account, uint256 amount);


     
    constructor() public {
        TG = IERC20(TG_Addr);
    }

     
    function () external payable {
        if (now > _till && _investors[msg.sender] > 0) {
            assert(TG.transfer(msg.sender, _investors[msg.sender]));
            _investors[msg.sender] = 0;
        }

        if (msg.value > 0) {
            emit Donate(msg.sender, msg.value);
        }
    }

     
    function holdings() public view returns (uint256) {
        return _holdings;
    }

     
    function investor(address owner) public view returns (uint256) {
        return _investors[owner];
    }

     
    function registerInvestor(address to, uint256 amount) external onlyOwner {
        _holdings = _holdings.add(amount);
        require(_holdings <= TG.balanceOf(address(this)));
        _investors[to] = _investors[to].add(amount);
        emit InvestorRegistered(to, amount);
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
        TG_Addr = _TGAddr;
        TG = IERC20(_TGAddr);
    }
}