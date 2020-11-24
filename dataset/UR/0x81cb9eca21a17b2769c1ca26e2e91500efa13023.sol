 

pragma solidity ^0.4.11;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
   
  modifier whenPaused() {
    require(paused);
    _;
  }
   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 
contract QuantstampSale is Pausable {
    using SafeMath for uint256;
     
    address public beneficiary;
     
    uint public fundingCap;
    uint public minContribution;
    bool public fundingCapReached = false;
    bool public saleClosed = false;
     
    mapping(address => bool) public registry;
     
     
    mapping(address => uint256) public cap1;         
    mapping(address => uint256) public cap2;         
    mapping(address => uint256) public cap3;         
    mapping(address => uint256) public cap4;         
     
    mapping(address => uint256) public contributed1;
    mapping(address => uint256) public contributed2;
    mapping(address => uint256) public contributed3;
    mapping(address => uint256) public contributed4;
     
    uint public rate1 = 10000;
    uint public rate2 = 7000;
    uint public rate3 = 6000;
    uint public rate4 = 5000;
     
    uint public startTime;
    uint public endTime;
     
    uint public amountRaised;
     
    bool private rentrancy_lock = false;
     
     
     
    mapping(address => uint256) public balanceOf;
     
    mapping(address => uint256) public tokenBalanceOf;
     
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event RegistrationStatusChanged(address target, bool isRegistered, uint c1, uint c2, uint c3, uint c4);
     
    modifier beforeDeadline()   { require (currentTime() < endTime); _; }
     
    modifier afterStartTime()    { require (currentTime() >= startTime); _; }
    modifier saleNotClosed()    { require (!saleClosed); _; }
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }
     
    function QuantstampSale(
        address ifSuccessfulSendTo,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint durationInMinutes
         
    ) {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this));
         
        require(durationInMinutes > 0);
        beneficiary = ifSuccessfulSendTo;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        endTime = start + (durationInMinutes * 1 minutes);
         
    }
     
    function () payable {
        buy();
    }
    function buy ()
        payable public
        whenNotPaused
        beforeDeadline
        afterStartTime
        saleNotClosed
        nonReentrant
    {
        require(msg.value >= minContribution);
        uint amount = msg.value;
         
        require(registry[msg.sender]);
        uint numTokens = computeTokenAmount(msg.sender, amount);
        assert(numTokens > 0);
         
        amountRaised = amountRaised.add(amount);
        require(amountRaised <= fundingCap);
         
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
         
        tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(numTokens);
        FundTransfer(msg.sender, amount, true);
        updateFundingCap();
    }
     
    function computeTokenAmount(address addr, uint amount) internal
        returns (uint){
        require(amount > 0);
        uint r3 = cap3[addr].sub(contributed3[addr]);
        uint r2 = cap2[addr].sub(contributed2[addr]);
        uint r1 = cap1[addr].sub(contributed1[addr]);
        uint r4 = cap4[addr].sub(contributed4[addr]);
        uint numTokens = 0;
         
        assert(amount <= r3.add(r2).add(r1).add(r4));
         
        if(r3 > 0){
            if(amount <= r3){
                contributed3[addr] = contributed3[addr].add(amount);
                return rate3.mul(amount);
            }
            else{
                numTokens = rate3.mul(r3);
                amount = amount.sub(r3);
                contributed3[addr] = cap3[addr];
            }
        }
         
        if(r2 > 0){
            if(amount <= r2){
                contributed2[addr] = contributed2[addr].add(amount);
                return numTokens.add(rate2.mul(amount));
            }
            else{
                numTokens = numTokens.add(rate2.mul(r2));
                amount = amount.sub(r2);
                contributed2[addr] = cap2[addr];
            }
        }
         
        if(r1 > 0){
            if(amount <= r1){
                contributed1[addr] = contributed1[addr].add(amount);
                return numTokens.add(rate1.mul(amount));
            }
            else{
                numTokens = numTokens.add(rate1.mul(r1));
                amount = amount.sub(r1);
                contributed1[addr] = cap1[addr];
            }
        }
         
        contributed4[addr] = contributed4[addr].add(amount);
        return numTokens.add(rate4.mul(amount));
    }
     
    function hasPreviouslyRegistered(address contributor)
        internal
        constant
        onlyOwner returns (bool)
    {
         
        return (cap1[contributor].add(cap2[contributor]).add(cap3[contributor]).add(cap4[contributor])) > 0;
    }
     
    function validateUpdatedRegistration(address addr, uint c1, uint c2, uint c3, uint c4)
        internal
        constant
        onlyOwner returns(bool)
    {
        return (contributed3[addr] <= c3) && (contributed2[addr] <= c2)
            && (contributed1[addr] <= c1) && (contributed4[addr] <= c4);
    }
     
    function registerUser(address contributor, uint c1, uint c2, uint c3, uint c4)
        public
        onlyOwner
    {
        require(contributor != address(0));
         
        if(hasPreviouslyRegistered(contributor)){
            require(validateUpdatedRegistration(contributor, c1, c2, c3, c4));
        }
        require(c1.add(c2).add(c3).add(c4) >= minContribution);
        registry[contributor] = true;
        cap1[contributor] = c1;
        cap2[contributor] = c2;
        cap3[contributor] = c3;
        cap4[contributor] = c4;
        RegistrationStatusChanged(contributor, true, c1, c2, c3, c4);
    }
      
    function deactivate(address contributor)
        public
        onlyOwner
    {
        require(registry[contributor]);
        registry[contributor] = false;
        RegistrationStatusChanged(contributor, false, cap1[contributor], cap2[contributor], cap3[contributor], cap4[contributor]);
    }
     
    function reactivate(address contributor)
        public
        onlyOwner
    {
        require(hasPreviouslyRegistered(contributor));
        registry[contributor] = true;
        RegistrationStatusChanged(contributor, true, cap1[contributor], cap2[contributor], cap3[contributor], cap4[contributor]);
    }
     
    function registerUsers(address[] contributors,
                           uint[] caps1,
                           uint[] caps2,
                           uint[] caps3,
                           uint[] caps4)
        external
        onlyOwner
    {
         
        require(contributors.length == caps1.length);
        require(contributors.length == caps2.length);
        require(contributors.length == caps3.length);
        require(contributors.length == caps4.length);
        for (uint i = 0; i < contributors.length; i++) {
            registerUser(contributors[i], caps1[i], caps2[i], caps3[i], caps4[i]);
        }
    }
     
    function terminate() external onlyOwner {
        saleClosed = true;
    }
     
    function ownerAllocateTokensForList(address[] addrs, uint[] weiAmounts, uint[] miniQspAmounts)
            external onlyOwner
    {
        require(addrs.length == weiAmounts.length);
        require(addrs.length == miniQspAmounts.length);
        for(uint i = 0; i < addrs.length; i++){
            ownerAllocateTokens(addrs[i], weiAmounts[i], miniQspAmounts[i]);
        }
    }
     
    function ownerAllocateTokens(address _to, uint amountWei, uint amountMiniQsp)
            onlyOwner nonReentrant
    {
         
         
        amountRaised = amountRaised.add(amountWei);
        require(amountRaised <= fundingCap);
        tokenBalanceOf[_to] = tokenBalanceOf[_to].add(amountMiniQsp);
        balanceOf[_to] = balanceOf[_to].add(amountWei);
        FundTransfer(_to, amountWei, true);
        updateFundingCap();
    }
     
    function ownerSafeWithdrawal() external onlyOwner nonReentrant {
        uint balanceToSend = this.balance;
        beneficiary.transfer(balanceToSend);
        FundTransfer(beneficiary, balanceToSend, false);
    }
     
    function updateFundingCap() internal {
        assert (amountRaised <= fundingCap);
        if (amountRaised == fundingCap) {
             
            fundingCapReached = true;
            saleClosed = true;
            CapReached(beneficiary, amountRaised);
        }
    }
     
    function currentTime() constant returns (uint _currentTime) {
        return now;
    }
}