 

pragma solidity 0.5.3;

 
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

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
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

 
contract TokenDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address account, uint256 amount);

     
    IERC20 private _token;

     
    uint256 private _releaseTime;

    uint256 private _totalReleased;
    mapping(address => uint256) private _released;

     
    address private _beneficiary1;
    address private _beneficiary2;
    address private _beneficiary3;
    address private _beneficiary4;

    uint256 public releasePerStep = uint256(1000000) * 10 ** 18;

     
    constructor (IERC20 token, uint256 releaseTime, address beneficiary1, address beneficiary2, address beneficiary3, address beneficiary4) public {
        _token = token;
        _releaseTime = releaseTime;
        _beneficiary1 = beneficiary1;
        _beneficiary2 = beneficiary2;
        _beneficiary3 = beneficiary3;
        _beneficiary4 = beneficiary4;
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

     
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

     
    function beneficiary1() public view returns (address) {
        return _beneficiary1;
    }

     
    function beneficiary2() public view returns (address) {
        return _beneficiary2;
    }

     
    function beneficiary3() public view returns (address) {
        return _beneficiary3;
    }

     
    function beneficiary4() public view returns (address) {
        return _beneficiary4;
    }

     
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

     
    function releaseToAccount(address account, uint256 amount) internal {
        require(amount != 0, 'The amount must be greater than zero.');

        _released[account] = _released[account].add(amount);
        _totalReleased = _totalReleased.add(amount);

        _token.safeTransfer(account, amount);
        emit TokensReleased(account, amount);
    }

     
    function release() onlyOwner public {
        require(block.timestamp >= releaseTime(), 'Team�s tokens can be released every six months.');

        uint256 _value1 = releasePerStep.mul(10).div(100);       
        uint256 _value2 = releasePerStep.mul(68).div(100);       
        uint256 _value3 = releasePerStep.mul(12).div(100);       
        uint256 _value4 = releasePerStep.mul(10).div(100);       

        _releaseTime = _releaseTime.add(180 days);

        releaseToAccount(_beneficiary1, _value1);
        releaseToAccount(_beneficiary2, _value2);
        releaseToAccount(_beneficiary3, _value3);
        releaseToAccount(_beneficiary4, _value4);
    }
}