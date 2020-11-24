 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;


 
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
        require(c / a == b, "SafeMath::mul: Integer overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath::div: Invalid divisor zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath::sub: Integer underflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath::add: Integer overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath::mod: Invalid divisor zero");
        return a % b;
    }
}


contract IHumanity {
    function mint(address account, uint256 value) public;
    function totalSupply() public view returns (uint256);
}


 
contract HumanityRegistry {

    mapping (address => bool) public humans;

    IHumanity public humanity;
    address public governance;

    constructor(IHumanity _humanity, address _governance) public {
        humanity = _humanity;
        governance = _governance;
    }

    function add(address who) public {
        require(msg.sender == governance, "HumanityRegistry::add: Only governance can add an identity");
        require(humans[who] == false, "HumanityRegistry::add: Address is already on the registry");

        _reward(who);
        humans[who] = true;
    }

    function remove(address who) public {
        require(
            msg.sender == governance || msg.sender == who,
            "HumanityRegistry::remove: Only governance or the identity owner can remove an identity"
        );
        delete humans[who];
    }

    function isHuman(address who) public view returns (bool) {
        return humans[who];
    }

    function _reward(address who) internal {
        uint totalSupply = humanity.totalSupply();

        if (totalSupply < 28000000e18) {
            humanity.mint(who, 30000e18);  
        } else if (totalSupply < 46000000e18) {
            humanity.mint(who, 20000e18);  
        } else if (totalSupply < 100000000e18) {
            humanity.mint(who, 6000e18);  
        }

    }

}


 
contract UniversalBasicIncome {
    using SafeMath for uint;

    HumanityRegistry public registry;
    IERC20 public dai;

    uint public constant MONTHLY_INCOME = 1e18;  
    uint public constant INCOME_PER_SECOND = MONTHLY_INCOME / 30 days;

    mapping (address => uint) public claimTimes;

    constructor(HumanityRegistry _registry, IERC20 _dai) public {
        registry = _registry;
        dai = _dai;
    }

    function claim() public {
        require(registry.isHuman(msg.sender), "UniversalBasicIncome::claim: You must be on the Humanity registry to claim income");

        uint income;
        uint time = block.timestamp;

         
        if (claimTimes[msg.sender] == 0) {
            income = MONTHLY_INCOME;
        } else {
            income = time.sub(claimTimes[msg.sender]).mul(INCOME_PER_SECOND);
        }

        uint balance = dai.balanceOf(address(this));
         
        uint actualIncome = balance < income ? balance : income;

        dai.transfer(msg.sender, actualIncome);
        claimTimes[msg.sender] = time;
    }

}