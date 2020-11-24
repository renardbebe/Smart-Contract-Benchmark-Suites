 

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}






contract BaseLBSCSale {
    using SafeMath for uint256;

    address public owner;
    bool public paused = false;
     
    address public beneficiary;

     
    uint public fundingGoal;
    uint public fundingCap;
    uint public minContribution;
    uint public decimals;
    bool public fundingGoalReached = false;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

     
    uint public startTime;
    uint public endTime;

     
    uint public amountRaised;

     
    uint public refundAmount;

     
    uint public rate = 220;

     
    bool private rentrancy_lock = false;

     
    mapping(address => uint256) public balanceOf;

    address public manager;

     
    event GoalReached(address _beneficiary, uint _amountRaised);
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event Pause();
    event Unpause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner is allowed to call this."); 
        _; 
    }

    modifier onlyOwnerOrManager{
        require(msg.sender == owner || msg.sender == manager, "Only owner or manager is allowed to call this");
        _;
    }

    modifier beforeDeadline(){
        require (currentTime() < endTime, "Validation: Before endtime");
        _;
    }
    modifier afterDeadline(){
        require (currentTime() >= endTime, "Validation: After endtime"); 
        _;
    }
    modifier afterStartTime(){
        require (currentTime() >= startTime, "Validation: After starttime"); 
        _;
    }

    modifier saleNotClosed(){
        require (!saleClosed, "Sale is not yet ended"); 
        _;
    }

    modifier nonReentrant() {
        require(!rentrancy_lock, "Validation: Reentrancy");
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

     
    modifier whenNotPaused() {
        require(!paused, "You are not allowed to access this time.");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "You are not allowed to access this time.");
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

     
    function pause() public onlyOwnerOrManager whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwnerOrManager whenPaused {
        paused = false;
        emit Unpause();
    }

     
    function currentTime() public view returns (uint _currentTime) {
        return block.timestamp;
    }

     
    function terminate() external onlyOwnerOrManager {
        saleClosed = true;
    }

     
    function setRate(uint _rate) public onlyOwnerOrManager {
         
        rate = _rate;
    }

     
    function ownerUnlockFund() external afterDeadline onlyOwner {
        fundingGoalReached = false;
    }

     
    function checkFundingGoal() internal {
        if (!fundingGoalReached) {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                emit GoalReached(beneficiary, amountRaised);
            }
        }
    }

     
    function checkFundingCap() internal {
        if (!fundingCapReached) {
            if (amountRaised >= fundingCap) {
                fundingCapReached = true;
                saleClosed = true;
                emit CapReached(beneficiary, amountRaised);
            }
        }
    }

     
    function changeStartTime(uint256 _startTime) external onlyOwnerOrManager {startTime = _startTime;}
    function changeEndTime(uint256 _endTime) external onlyOwnerOrManager {endTime = _endTime;}
    function changeMinContribution(uint256 _newValue) external onlyOwnerOrManager {minContribution = _newValue * (10 ** decimals);}
}






contract BaseLBSCToken {
    using SafeMath for uint256;

     
    address public owner;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal totalSupply_;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Mint(address indexed to, uint256 amount);

     
    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner is allowed to call this."); 
        _; 
    }

    constructor() public{
        owner = msg.sender;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "You do not have sufficient balance.");
        require(_to != address(0), "You cannot send tokens to 0 address");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_value <= balances[_from], "You do not have sufficient balance.");
        require(_value <= allowed[_from][msg.sender], "You do not have allowance.");
        require(_to != address(0), "You cannot send tokens to 0 address");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool){
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who], "Insufficient balance of tokens");
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance to burn tokens.");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

contract LBSCToken is BaseLBSCToken {
    
     
    string  public constant name = "LabelsCoin";
    string  public constant symbol = "LBSC";
    uint8   public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY      =  30000000 * (10 ** uint256(decimals));
     
    uint256 public constant ADMIN_ALLOWANCE     =  30000000 * (10 ** uint256(decimals));
    
     
     
     
    uint256 public adminAllowance;           
     
    address public adminAddr;                
     
    bool    public transferEnabled = true;   

     
    modifier validDestination(address _to) {
        require(_to != address(0x0), "Cannot send to 0 address");
        require(_to != address(this), "Cannot send to contract address");
         
         
         
        _;
    }

    constructor(address _admin) public {
        require(msg.sender != _admin, "Owner and admin cannot be the same");

        totalSupply_ = INITIAL_SUPPLY;
        adminAllowance = ADMIN_ALLOWANCE;

         
         
         

        balances[_admin] = adminAllowance;
        emit Transfer(address(0x0), _admin, adminAllowance);

        adminAddr = _admin;
        approve(adminAddr, adminAllowance);
    }

     
    function transfer(address _to, uint256 _value) public validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public validDestination(_to) returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (result) {
            if (msg.sender == adminAddr)
                adminAllowance = adminAllowance.sub(_value);
        }
        return result;
    }
}

contract LBSCSale is BaseLBSCSale {
    using SafeMath for uint256;

     
    LBSCToken public tokenReward;

    mapping(address => bool) public approvedUsers;

     
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        uint minimumContribution,
        uint start,
        uint end,
        uint rateLBSCToEther,
        address addressOfTokenUsedAsReward,
        address _manager
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this), "Beneficiary cannot be 0 address");
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this), "Token address cannot be 0 address");
        require(fundingGoalInEthers <= fundingCapInEthers, "Funding goal should be less that funding cap.");
        require(end > 0, "Endtime cannot be 0");
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers;
        fundingCap = fundingCapInEthers;
        minContribution = minimumContribution;
        startTime = start;
        endTime = end;  
        rate = rateLBSCToEther;
        tokenReward = LBSCToken(addressOfTokenUsedAsReward);
        manager = _manager;
        decimals = tokenReward.decimals();
    }

     
    function () public payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        require(msg.value >= minContribution, "Value should be greater than minimum contribution");
        require(isApprovedUser(msg.sender), "Only the approved users are allowed to participate in ICO");
        
         
        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        amountRaised = amountRaised.add(amount);

         
         
         
        uint numTokens = amount.mul(rate);

         
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
            emit FundTransfer(msg.sender, amount, true);
             
             
             
             
             
             
             
            checkFundingGoal();
            checkFundingCap();
        }
        else {
            revert("Transaction Failed. Please try again later.");
        }
    }

     
    function ownerAllocateTokens(address _to, uint amountInEth, uint amountLBSC) public
            onlyOwnerOrManager nonReentrant
    {
        if (!tokenReward.transferFrom(tokenReward.owner(), _to, convertToMini(amountLBSC))) {
            revert("Transfer failed. Please check allowance");
        }

        uint amountWei = convertToMini(amountInEth);
        balanceOf[_to] = balanceOf[_to].add(amountWei);
        amountRaised = amountRaised.add(amountWei);
        emit FundTransfer(_to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

     
    function ownerSafeWithdrawal() public onlyOwner nonReentrant {
        require(fundingGoalReached, "Check funding goal");
        uint balanceToSend = address(this).balance;
        beneficiary.transfer(balanceToSend);
        emit FundTransfer(beneficiary, balanceToSend, false);
    }

     
    function safeWithdrawal() public afterDeadline nonReentrant {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                refundAmount = refundAmount.add(amount);
            }
        }
    }
    
    function convertToMini(uint amount) internal view returns (uint) {
        return amount * (10 ** decimals);
    }

    function approveUser(address _address) external onlyOwnerOrManager {
        approvedUsers[_address] = true;
    }

    function disapproveUser(address _address) external onlyOwnerOrManager {
        approvedUsers[_address] = false;
    }

    function changeManager(address _manager) external onlyOwnerOrManager {
        manager = _manager;
    }

    function isApprovedUser(address _address) internal view returns (bool) {
        return approvedUsers[_address];
    }

    function changeTokenAddress(address _address) external onlyOwnerOrManager {
        tokenReward = LBSCToken(_address);
    }
}