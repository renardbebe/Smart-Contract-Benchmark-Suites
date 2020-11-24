 

pragma solidity ^0.4.13;


 
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}


 
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}


contract FluencePreSale is Haltable, SafeMath {

    mapping (address => uint256) public balanceOf;

     

    string public constant name = "Fluence Presale Token";

    string public constant symbol = "FPT";

    uint   public constant decimals = 18;

     
    uint256 public constant SUPPLY_LIMIT = 6000000 ether;

     
    uint256 public totalSupply;

     
    uint256 public softCap = 1000 ether;

     
    uint256 public constant basicThreshold = 500 finney;

    uint public constant basicTokensPerEth = 1500;

     
    uint256 public constant advancedThreshold = 5 ether;

    uint public constant advancedTokensPerEth = 2250;

     
    uint256 public constant expertThreshold = 100 ether;

    uint public constant expertTokensPerEth = 3000;

     
     
    mapping (address => uint256) public etherContributions;

     
    uint256 public etherCollected;

     
    address public beneficiary;

    uint public startAtBlock;

    uint public endAtBlock;

     
    event GoalReached(uint amountRaised);

     
    event SoftCapReached(uint softCap);

     
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

     
    event Refunded(address indexed holder, uint256 amount);

     
    modifier softCapReached {
        if (etherCollected < softCap) {
            revert();
        }
        assert(etherCollected >= softCap);
        _;
    }

     
    modifier duringPresale {
        if (block.number < startAtBlock || block.number > endAtBlock || totalSupply >= SUPPLY_LIMIT) {
            revert();
        }
        assert(block.number >= startAtBlock && block.number <= endAtBlock && totalSupply < SUPPLY_LIMIT);
        _;
    }

     
    modifier duringRefund {
        if(block.number <= endAtBlock || etherCollected >= softCap || this.balance == 0) {
            revert();
        }
        assert(block.number > endAtBlock && etherCollected < softCap && this.balance > 0);
        _;
    }

    function FluencePreSale(uint _startAtBlock, uint _endAtBlock, uint softCapInEther){
        require(_startAtBlock > 0 && _endAtBlock > 0);
        beneficiary = msg.sender;
        startAtBlock = _startAtBlock;
        endAtBlock = _endAtBlock;
        softCap = softCapInEther * 1 ether;
    }

     
    function setBeneficiary(address to) onlyOwner external {
        require(to != address(0));
        beneficiary = to;
    }

     
    function withdraw() onlyOwner softCapReached external {
        require(this.balance > 0);
        beneficiary.transfer(this.balance);
    }

     
    function contribute(address _address) private stopInEmergency duringPresale {
        if(msg.value < basicThreshold && owner != _address) {
            revert();
        }
        assert(msg.value >= basicThreshold || owner == _address);
         

        uint256 tokensToIssue;

        if (msg.value >= expertThreshold) {
            tokensToIssue = safeMult(msg.value, expertTokensPerEth);
        }
        else if (msg.value >= advancedThreshold) {
            tokensToIssue = safeMult(msg.value, advancedTokensPerEth);
        }
        else {
            tokensToIssue = safeMult(msg.value, basicTokensPerEth);
        }

        assert(tokensToIssue > 0);

        totalSupply = safeAdd(totalSupply, tokensToIssue);

         
        if(totalSupply > SUPPLY_LIMIT) {
            revert();
        }
        assert(totalSupply <= SUPPLY_LIMIT);

         
        etherContributions[_address] = safeAdd(etherContributions[_address], msg.value);

         
        uint collectedBefore = etherCollected;
        etherCollected = safeAdd(etherCollected, msg.value);

         
        balanceOf[_address] = safeAdd(balanceOf[_address], tokensToIssue);

        NewContribution(_address, tokensToIssue, msg.value);

        if (totalSupply == SUPPLY_LIMIT) {
            GoalReached(etherCollected);
        }
        if (etherCollected >= softCap && collectedBefore < softCap) {
            SoftCapReached(etherCollected);
        }
    }

    function() external payable {
        contribute(msg.sender);
    }

    function refund() stopInEmergency duringRefund external {
        uint tokensToBurn = balanceOf[msg.sender];


         
        require(tokensToBurn > 0);

         
        balanceOf[msg.sender] = 0;

         
        uint amount = etherContributions[msg.sender];

         
        assert(amount > 0);

        etherContributions[msg.sender] = 0;
         

         
        etherCollected = safeSubtract(etherCollected, amount);
        totalSupply = safeSubtract(totalSupply, tokensToBurn);

         
        msg.sender.transfer(amount);

        Refunded(msg.sender, amount);
    }


}