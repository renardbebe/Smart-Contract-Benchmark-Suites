 

pragma solidity 0.5.9;


 
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



 
contract Claimable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 
contract Keeper is Claimable {
    using SafeMath for uint256;
    IERC20 public token;
     
    uint256 public unFreezeStartDate;
     
    uint256 public totalUnFreezeDate;
     
    mapping(address => uint256) public balances;
     
    mapping(address => uint256) public withdrawnBalances;
     
    uint256 public totalBalance;

    constructor(
        IERC20 _token,
        uint256 _unFreezeStartDate,
        uint256 _totalUnFreezeDate
    ) public {
         
        require(_unFreezeStartDate >= block.timestamp);
        require(_totalUnFreezeDate > _unFreezeStartDate);
        token = _token;
        unFreezeStartDate = _unFreezeStartDate;
        totalUnFreezeDate = _totalUnFreezeDate;
    }

     
    function addBalance(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0));
        require(_value > 0);
        require(totalBalance.add(_value)
                <= token.balanceOf(address(this)), "not enough tokens");
        balances[_to] = balances[_to].add(_value);
        totalBalance = totalBalance.add(_value);
    }

     
    function withdraw(address _to, uint256 _value) public {
        require(_to != address(0));
        require(_value > 0);
        require(unFreezeStartDate < now, "not unfrozen yet");
        require(
            (getUnfrozenAmount(msg.sender).sub(withdrawnBalances[msg.sender]))
            >= _value
        );
        withdrawnBalances[msg.sender] = withdrawnBalances[msg.sender].add(_value);
        totalBalance = totalBalance.sub(_value);
        token.transfer(_to, _value);
    }

     
    function getUnfrozenAmount(address _holder) public view returns (uint256) {
        if (now > unFreezeStartDate) {
            if (now > totalUnFreezeDate) {
                 
                return balances[_holder];
            }
             
            uint256 partialFreezePeriodLen =
                totalUnFreezeDate.sub(unFreezeStartDate);
            uint256 secondsSincePeriodStart = now.sub(unFreezeStartDate);
            uint256 amount = balances[_holder]
                .mul(secondsSincePeriodStart)
                .div(partialFreezePeriodLen);
            return amount;
        }
         
        return 0;
    }
}