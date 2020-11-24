 

 

pragma solidity 0.5.9;


 
contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Only owner is able call this function!");
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

 

pragma solidity ^0.5.9;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMul overflow!');

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, 'SafeDiv cannot divide by 0!');
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeSub underflow!');
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeAdd overflow!');

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMod cannot compute modulo of 0!');
        return a % b;
    }
}

 

pragma solidity 0.5.9;

 
contract ERC20Plus {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function mint(address _to, uint256 _amount) public returns (bool);
    function owner() public view returns (address);
    function transferOwnership(address newOwner) public;
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function decimals() public view returns (uint8);
    function paused() public view returns (bool);
}

 

pragma solidity 0.5.9;


contract Lockable is Ownable {

    bool public locked;

    modifier onlyWhenUnlocked() {
        require(!locked, 'Contract is locked by owner!');
        _;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function unlock() external onlyOwner {
        locked = false;
    }
}

 

pragma solidity 0.5.9;





 

contract BonusTokenDistribution is Lockable {
    using SafeMath for uint256;

    ERC20Plus public tokenOnSale;

    uint256 public startTime;
    uint256 public endTime;

    mapping (address => uint256) public bonusTokenBalances;

    modifier isAfterClaimPeriod {
        require(
            (now > endTime.add(60 days)),
            'Claim period is not yet finished!'
        );

        _;
    }

    modifier hasStarted {
        require(
            now >= startTime,
            "Distribution period not yet started!"
        );

        _;
    }

     
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address _tokenOnSale
    ) public {
        require(_startTime >= now, "startTime must be more than current time!");
        require(_endTime >= _startTime, "endTime must be more than startTime!");
        require(_tokenOnSale != address(0), "tokenOnSale cannot be 0!");

        startTime = _startTime;
        endTime = _endTime;
        tokenOnSale = ERC20Plus(_tokenOnSale);
    }

     
    function addBonusClaim(address _user, uint256 _amount)
        public
        onlyOwner
        hasStarted {
        require(_user != address(0), "user cannot be 0!");
        require(_amount > 0, "amount cannot be 0!");

        bonusTokenBalances[_user] = bonusTokenBalances[_user].add(_amount);
    }

     
    function withdrawBonusTokens() public onlyWhenUnlocked hasStarted {
        uint256 bonusTokens = bonusTokenBalances[msg.sender];
        uint256 tokenBalance = tokenOnSale.balanceOf(address(this));

        require(bonusTokens > 0, 'No bonus tokens to withdraw!');
        require(tokenBalance >= bonusTokens, 'Not enough bonus tokens left!');

        bonusTokenBalances[msg.sender] = 0;
        tokenOnSale.transfer(msg.sender, bonusTokens);
    }

     
    function withdrawLeftoverBonusTokensOwner()
        public
        isAfterClaimPeriod
        onlyOwner {
        uint256 tokenBalance = tokenOnSale.balanceOf(address(this));
        require(tokenBalance > 0, 'No bonus tokens leftover!');

        tokenOnSale.transfer(msg.sender, tokenBalance);
    }
}