 

pragma solidity 0.5.2;

 

 
interface IERC20 {

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

}

 
library SafeMath {
     
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
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
contract LockDrop {
    using SafeMath for uint256;

     
    uint256 public _stakingEnd;

     
    uint256 public _weightsSum;

     
    address public _kongERC20Address;

     
    mapping(address => uint256) public _weights;

     
    mapping(address => uint256) public _lockingEnds;

     
    event Staked(
        address indexed contributor,
        address lockETHAddress,
        uint256 ethStaked,
        uint256 endDate
    );
    event Claimed(
        address indexed claimant,
        uint256 ethStaked,
        uint256 kongClaim
    );

    constructor (address kongERC20Address) public {

         
        _kongERC20Address = kongERC20Address;

         
        _stakingEnd = block.timestamp + 30 days;

    }

     
    function stakeETH(uint256 stakingPeriod) public payable {

         
        require(msg.value > 0, 'Msg value = 0.');

         
        require(_weights[msg.sender] == 0, 'No topping up.');

         
        require(block.timestamp <= _stakingEnd, 'Closed for contributions.');

         
        require(stakingPeriod >= 30 && stakingPeriod <= 365, 'Staking period outside of allowed range.');

         
        uint256 totalTime = _stakingEnd + stakingPeriod * 1 days - block.timestamp;
        uint256 weight = totalTime.mul(msg.value);

         
        _weightsSum = _weightsSum.add(weight);
        _weights[msg.sender] = weight;

         
        _lockingEnds[msg.sender] = _stakingEnd + stakingPeriod * 1 days;

         
        LockETH lockETH = (new LockETH).value(msg.value)(_lockingEnds[msg.sender], msg.sender);

         
        require(address(lockETH).balance >= msg.value);

         
        emit Staked(msg.sender, address(lockETH), msg.value, _lockingEnds[msg.sender]);

    }

     
    function claimKong() external {

         
        require(_weights[msg.sender] > 0, 'Zero contribution.');

         
        require(block.timestamp > _lockingEnds[msg.sender], 'Cannot claim yet.');

         
        uint256 weight = _weights[msg.sender];
        uint256 kongClaim = IERC20(_kongERC20Address).balanceOf(address(this)).mul(weight).div(_weightsSum);

         
        _weights[msg.sender] = 0;
        _weightsSum = _weightsSum.sub(weight);

         
        IERC20(_kongERC20Address).transfer(msg.sender, kongClaim);

         
        emit Claimed(msg.sender, weight, kongClaim);

    }

}

 
contract LockETH {

    uint256 public _endOfLockUp;
    address payable public _contractOwner;

    constructor (uint256 endOfLockUp, address payable contractOwner) public payable {

        _endOfLockUp = endOfLockUp;
        _contractOwner = contractOwner;

    }

     
    function unlockETH() external {

         
        require(block.timestamp > _endOfLockUp, 'Cannot claim yet.');

         
        _contractOwner.transfer(address(this).balance);

    }

}