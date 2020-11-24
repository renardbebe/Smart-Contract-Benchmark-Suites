 

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


 
contract Faucet {
    using SafeMath for uint;

    uint public constant BLOCK_REWARD = 1e18;
    uint public START_BLOCK = block.number;
    uint public END_BLOCK = block.number + 5000000;

    IERC20 public humanity;
    address public auction;

    uint public lastMined = block.number;

    constructor(IERC20 _humanity, address _auction) public {
        humanity = _humanity;
        auction = _auction;
    }

    function mine() public {
        uint rewardBlock = block.number < END_BLOCK ? block.number : END_BLOCK;
        uint reward = rewardBlock.sub(lastMined).mul(BLOCK_REWARD);
        humanity.transfer(auction, reward);
        lastMined = block.number;
    }
}