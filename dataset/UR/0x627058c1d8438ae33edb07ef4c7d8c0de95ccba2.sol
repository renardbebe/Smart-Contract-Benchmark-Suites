 

pragma solidity 0.4.24;


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMathLibExt {

    function times(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) public pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) public pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Allocatable is Ownable {

   
    mapping (address => bool) public allocateAgents;

    event AllocateAgentChanged(address addr, bool state  );

   
    function setAllocateAgent(address addr, bool state) public onlyOwner  
    {
        allocateAgents[addr] = state;
        emit AllocateAgentChanged(addr, state);
    }

    modifier onlyAllocateAgent() {
         
        require(allocateAgents[msg.sender]);
        _;
    }
}

 
contract TokenVesting is Allocatable {

    using SafeMathLibExt for uint;

    address public crowdSaleTokenAddress;

     
    uint256 public totalUnreleasedTokens;

     
    uint256 private startAt = 0;
    uint256 private cliff = 1;
    uint256 private duration = 4; 
    uint256 private step = 300;  
    bool private changeFreezed = false;

    struct VestingSchedule {
        uint256 startAt;
        uint256 cliff;
        uint256 duration;
        uint256 step;
        uint256 amount;
        uint256 amountReleased;
        bool changeFreezed;
    }

    mapping (address => VestingSchedule) public vestingMap;

    event VestedTokensReleased(address _adr, uint256 _amount);
    
    constructor(address _tokenAddress) public {
        
        crowdSaleTokenAddress = _tokenAddress;
    }

     
    modifier changesToVestingFreezed(address _adr) {
        require(vestingMap[_adr].changeFreezed);
        _;
    }

     
    modifier changesToVestingNotFreezed(address adr) {
        require(!vestingMap[adr].changeFreezed);  
        _;
    }

     
    function setDefaultVestingParameters(
        uint256 _startAt, uint256 _cliff, uint256 _duration,
        uint256 _step, bool _changeFreezed) public onlyAllocateAgent {

         
        require(_step != 0);
        require(_duration != 0);
        require(_cliff <= _duration);

        startAt = _startAt;
        cliff = _cliff;
        duration = _duration; 
        step = _step;
        changeFreezed = _changeFreezed;

    }

     
    function setVestingWithDefaultSchedule(address _adr, uint256 _amount) 
    public 
    changesToVestingNotFreezed(_adr) onlyAllocateAgent {
       
        setVesting(_adr, startAt, cliff, duration, step, _amount, changeFreezed);
    }    

     
    function setVesting(
        address _adr,
        uint256 _startAt,
        uint256 _cliff,
        uint256 _duration,
        uint256 _step,
        uint256 _amount,
        bool _changeFreezed) 
    public changesToVestingNotFreezed(_adr) onlyAllocateAgent {

        VestingSchedule storage vestingSchedule = vestingMap[_adr];

         
        require(_step != 0);
        require(_amount != 0 || vestingSchedule.amount > 0);
        require(_duration != 0);
        require(_cliff <= _duration);

         
        if (_startAt == 0) 
            _startAt = block.timestamp;

        vestingSchedule.startAt = _startAt;
        vestingSchedule.cliff = _cliff;
        vestingSchedule.duration = _duration;
        vestingSchedule.step = _step;

         
        if (vestingSchedule.amount == 0) {
             
            ERC20 token = ERC20(crowdSaleTokenAddress);
            require(token.balanceOf(this) >= totalUnreleasedTokens.plus(_amount));
            totalUnreleasedTokens = totalUnreleasedTokens.plus(_amount);
            vestingSchedule.amount = _amount; 
        }

        vestingSchedule.amountReleased = 0;
        vestingSchedule.changeFreezed = _changeFreezed;
    }

    function isVestingSet(address adr) public view returns (bool isSet) {
        return vestingMap[adr].amount != 0;
    }

    function freezeChangesToVesting(address _adr) public changesToVestingNotFreezed(_adr) onlyAllocateAgent {
        require(isVestingSet(_adr));  
        vestingMap[_adr].changeFreezed = true;
    }

     
    function releaseMyVestedTokens() public changesToVestingFreezed(msg.sender) {
        releaseVestedTokens(msg.sender);
    }

     
    function releaseVestedTokens(address _adr) public changesToVestingFreezed(_adr) {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
         
        require(vestingSchedule.amount.minus(vestingSchedule.amountReleased) > 0);
        
         
        uint256 totalTime = block.timestamp - vestingSchedule.startAt;
        uint256 totalSteps = totalTime / vestingSchedule.step;

         
        require(vestingSchedule.cliff <= totalSteps);

        uint256 tokensPerStep = vestingSchedule.amount / vestingSchedule.duration;
         
        if (tokensPerStep * vestingSchedule.duration != vestingSchedule.amount) tokensPerStep++;

        uint256 totalReleasableAmount = tokensPerStep.times(totalSteps);

         
        if (totalReleasableAmount > vestingSchedule.amount) totalReleasableAmount = vestingSchedule.amount;

        uint256 amountToRelease = totalReleasableAmount.minus(vestingSchedule.amountReleased);
        vestingSchedule.amountReleased = vestingSchedule.amountReleased.plus(amountToRelease);

         
        ERC20 token = ERC20(crowdSaleTokenAddress);
        token.transfer(_adr, amountToRelease);
         
        totalUnreleasedTokens = totalUnreleasedTokens.minus(amountToRelease);
        emit VestedTokensReleased(_adr, amountToRelease);
    }

     
    function setCrowdsaleTokenExtv1(address _token) public onlyAllocateAgent {       
        crowdSaleTokenAddress = _token;
    }
}