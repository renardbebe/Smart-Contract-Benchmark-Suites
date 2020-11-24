 

pragma solidity 0.4.24;
 
 

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface Token {
     
     
     
     
    function mintToken(address to, uint amount) external returns (bool success);  

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);    
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

 
contract Vesting is Ownable {
    using SafeMath for uint256;

    Token public tokenReward;

     
    address private _beneficiary;

    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    address public _addressOfTokenUsedAsReward;
    address public creator;

    mapping (address => uint256) private _released;

     
    function Vesting() payable {
        creator = msg.sender;
    }

     
    function createVestingPeriod(address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, address addressOfTokenUsedAsReward) public {
        require(msg.sender == creator);
        require(cliffDuration <= duration);
        require(duration > 0);
        require(start.add(duration) > block.timestamp);

        _beneficiary = beneficiary;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
        _addressOfTokenUsedAsReward = addressOfTokenUsedAsReward;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function cliff() public view returns (uint256) {
        return _cliff;
    }

     
    function start() public view returns (uint256) {
        return _start;
    }

     
    function duration() public view returns (uint256) {
        return _duration;
    }

     
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

     
    function release(address token) public {
        require(msg.sender == creator);
    
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0);

        _released[token] = _released[token].add(unreleased);

        tokenReward.transfer(_beneficiary, unreleased);
    }

     
    function _releasableAmount(address token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[token]);
    }

     
    function _vestedAmount(address token) private view returns (uint256) {
        uint256 currentBalance = tokenReward.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[token]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}