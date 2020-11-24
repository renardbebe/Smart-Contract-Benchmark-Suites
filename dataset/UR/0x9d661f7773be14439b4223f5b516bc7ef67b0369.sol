 

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


contract IRegistry {
    function add(address who) public;
}


contract IUniswapExchange {
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 timestamp) public payable returns (uint256);
}


contract IGovernance {
    function proposeWithFeeRecipient(address feeRecipient, address target, bytes memory data) public returns (uint);
    function proposalFee() public view returns (uint);
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


 
contract HumanityApplicant {
    using SafeMath for uint;

    IGovernance public governance;
    IRegistry public registry;
    IERC20 public humanity;

    constructor(IGovernance _governance, IRegistry _registry, IERC20 _humanity) public {
        governance = _governance;
        registry = _registry;
        humanity = _humanity;
        humanity.approve(address(governance), uint(-1));
    }

    function applyFor(address who) public returns (uint) {
        uint fee = governance.proposalFee();
        uint balance = humanity.balanceOf(address(this));
        if (fee > balance) {
            require(humanity.transferFrom(msg.sender, address(this), fee.sub(balance)), "HumanityApplicant::applyFor: Transfer failed");
        }
        bytes memory data = abi.encodeWithSelector(registry.add.selector, who);
        return governance.proposeWithFeeRecipient(msg.sender, address(registry), data);
    }

}


 
contract PayableHumanityApplicant is HumanityApplicant {

    IUniswapExchange public exchange;

    constructor(IGovernance _governance, IRegistry _registry, IERC20 _humanity, IUniswapExchange _exchange) public
        HumanityApplicant(_governance, _registry, _humanity)
    {
        exchange = _exchange;
    }

    function () external payable {}

    function applyWithEtherFor(address who) public payable returns (uint) {
         
        uint fee = governance.proposalFee();
        exchange.ethToTokenSwapOutput.value(msg.value)(fee, block.timestamp);

         
        uint proposalId = applyFor(who);

         
        msg.sender.send(address(this).balance);

        return proposalId;
    }

}


 
contract TwitterHumanityApplicant is PayableHumanityApplicant {

    event Apply(uint indexed proposalId, address indexed applicant, string username);

    constructor(
        IGovernance _governance,
        IRegistry _registry,
        IERC20 _humanity,
        IUniswapExchange _exchange
    ) public
        PayableHumanityApplicant(_governance, _registry, _humanity, _exchange) {}

    function applyWithTwitter(string memory username) public returns (uint) {
        return applyWithTwitterFor(msg.sender, username);
    }

    function applyWithTwitterFor(address who, string memory username) public returns (uint) {
        uint proposalId = applyFor(who);
        emit Apply(proposalId, who, username);
        return proposalId;
    }

    function applyWithTwitterUsingEther(string memory username) public payable returns (uint) {
        return applyWithTwitterUsingEtherFor(msg.sender, username);
    }

    function applyWithTwitterUsingEtherFor(address who, string memory username) public payable returns (uint) {
        uint proposalId = applyWithEtherFor(who);
        emit Apply(proposalId, who, username);
        return proposalId;
    }

}