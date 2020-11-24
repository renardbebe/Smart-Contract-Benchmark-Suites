 

pragma solidity ^0.4.15;

 
contract IOwned {
     
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract Utils {
     
    function Utils() {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract TokenHolder is ITokenHolder, Owned, Utils {
     
    function TokenHolder() {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

 
contract ERC20Token is IERC20Token, Utils {
    string public standard = "Token 0.1";
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract ENJToken is ERC20Token, TokenHolder {

 

    uint256 constant public ENJ_UNIT = 10 ** 18;
    uint256 public totalSupply = 1 * (10**9) * ENJ_UNIT;

     
    uint256 constant public maxPresaleSupply = 600 * 10**6 * ENJ_UNIT;            
    uint256 constant public minCrowdsaleAllocation = 200 * 10**6 * ENJ_UNIT;      
    uint256 constant public incentivisationAllocation = 100 * 10**6 * ENJ_UNIT;   
    uint256 constant public advisorsAllocation = 26 * 10**6 * ENJ_UNIT;           
    uint256 constant public enjinTeamAllocation = 74 * 10**6 * ENJ_UNIT;          

    address public crowdFundAddress;                                              
    address public advisorAddress;                                                
    address public incentivisationFundAddress;                                    
    address public enjinTeamAddress;                                              

     

    uint256 public totalAllocatedToAdvisors = 0;                                  
    uint256 public totalAllocatedToTeam = 0;                                      
    uint256 public totalAllocated = 0;                                            
    uint256 constant public endTime = 1509494340;                                 

    bool internal isReleasedToPublic = false;                          

    uint256 internal teamTranchesReleased = 0;                           
    uint256 internal maxTeamTranches = 8;                                

 

     
    modifier safeTimelock() {
        require(now >= endTime + 6 * 4 weeks);
        _;
    }

     
    modifier advisorTimelock() {
        require(now >= endTime + 2 * 4 weeks);
        _;
    }

     
    modifier crowdfundOnly() {
        require(msg.sender == crowdFundAddress);
        _;
    }

     

     
    function ENJToken(address _crowdFundAddress, address _advisorAddress, address _incentivisationFundAddress, address _enjinTeamAddress)
    ERC20Token("Enjin Coin", "ENJ", 18)
     {
        crowdFundAddress = _crowdFundAddress;
        advisorAddress = _advisorAddress;
        enjinTeamAddress = _enjinTeamAddress;
        incentivisationFundAddress = _incentivisationFundAddress;
        balanceOf[_crowdFundAddress] = minCrowdsaleAllocation + maxPresaleSupply;  
        balanceOf[_incentivisationFundAddress] = incentivisationAllocation;        
        totalAllocated += incentivisationAllocation;                               
    }

 

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (isTransferAllowed() == true || msg.sender == crowdFundAddress || msg.sender == incentivisationFundAddress) {
            assert(super.transfer(_to, _value));
            return true;
        }
        revert();        
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (isTransferAllowed() == true || msg.sender == crowdFundAddress || msg.sender == incentivisationFundAddress) {        
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }

 

     
    function releaseEnjinTeamTokens() safeTimelock ownerOnly returns(bool success) {
        require(totalAllocatedToTeam < enjinTeamAllocation);

        uint256 enjinTeamAlloc = enjinTeamAllocation / 1000;
        uint256 currentTranche = uint256(now - endTime) / 12 weeks;      

        if(teamTranchesReleased < maxTeamTranches && currentTranche > teamTranchesReleased) {
            teamTranchesReleased++;

            uint256 amount = safeMul(enjinTeamAlloc, 125);
            balanceOf[enjinTeamAddress] = safeAdd(balanceOf[enjinTeamAddress], amount);
            Transfer(0x0, enjinTeamAddress, amount);
            totalAllocated = safeAdd(totalAllocated, amount);
            totalAllocatedToTeam = safeAdd(totalAllocatedToTeam, amount);
            return true;
        }
        revert();
    }

     
    function releaseAdvisorTokens() advisorTimelock ownerOnly returns(bool success) {
        require(totalAllocatedToAdvisors == 0);
        balanceOf[advisorAddress] = safeAdd(balanceOf[advisorAddress], advisorsAllocation);
        totalAllocated = safeAdd(totalAllocated, advisorsAllocation);
        totalAllocatedToAdvisors = advisorsAllocation;
        Transfer(0x0, advisorAddress, advisorsAllocation);
        return true;
    }

     
    function retrieveUnsoldTokens() safeTimelock ownerOnly returns(bool success) {
        uint256 amountOfTokens = balanceOf[crowdFundAddress];
        balanceOf[crowdFundAddress] = 0;
        balanceOf[incentivisationFundAddress] = safeAdd(balanceOf[incentivisationFundAddress], amountOfTokens);
        totalAllocated = safeAdd(totalAllocated, amountOfTokens);
        Transfer(crowdFundAddress, incentivisationFundAddress, amountOfTokens);
        return true;
    }

     
    function addToAllocation(uint256 _amount) crowdfundOnly {
        totalAllocated = safeAdd(totalAllocated, _amount);
    }

     
    function allowTransfers() ownerOnly {
        isReleasedToPublic = true;
    } 

     
    function isTransferAllowed() internal constant returns(bool) {
        if (now > endTime || isReleasedToPublic == true) {
            return true;
        }
        return false;
    }
}

contract ENJCrowdfund is TokenHolder {

 

    uint256 constant public startTime = 1507032000;                 
    uint256 constant public endTime = 1509494340;                   
    uint256 constant internal week2Start = startTime + (7 days);    
    uint256 constant internal week3Start = week2Start + (7 days);   
    uint256 constant internal week4Start = week3Start + (7 days);   

    uint256 public totalPresaleTokensYetToAllocate;      
    address public beneficiary = 0x0;                    
    address public tokenAddress = 0x0;                   

    ENJToken token;                                      

 

    event CrowdsaleContribution(address indexed _contributor, uint256 _amount, uint256 _return);
    event PresaleContribution(address indexed _contributor, uint256 _amountOfTokens);

 

     
    function ENJCrowdfund(uint256 _totalPresaleTokensYetToAllocate, address _beneficiary) 
    validAddress(_beneficiary) 
    {
        totalPresaleTokensYetToAllocate = _totalPresaleTokensYetToAllocate;
        beneficiary = _beneficiary;
    }

 

     
    modifier between() {
        assert(now >= startTime && now < endTime);
        _;
    }

     
    modifier tokenIsSet() {
        require(tokenAddress != 0x0);
        _;
    }

 

     
    function setToken(address _tokenAddress) validAddress(_tokenAddress) ownerOnly {
        require(tokenAddress == 0x0);
        tokenAddress = _tokenAddress;
        token = ENJToken(_tokenAddress);
    }

     
    function changeBeneficiary(address _newBeneficiary) validAddress(_newBeneficiary) ownerOnly {
        beneficiary = _newBeneficiary;
    }

     
    function deliverPresaleTokens(address[] _batchOfAddresses, uint256[] _amountofENJ) external tokenIsSet ownerOnly returns (bool success) {
        require(now < startTime);
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverPresaleTokenToClient(_batchOfAddresses[i], _amountofENJ[i]);            
        }
        return true;
    }

     
    function deliverPresaleTokenToClient(address _accountHolder, uint256 _amountofENJ) internal ownerOnly {
        require(totalPresaleTokensYetToAllocate > 0);
        token.transfer(_accountHolder, _amountofENJ);
        token.addToAllocation(_amountofENJ);
        totalPresaleTokensYetToAllocate = safeSub(totalPresaleTokensYetToAllocate, _amountofENJ);
        PresaleContribution(_accountHolder, _amountofENJ);
    }

 
     
    function contributeETH(address _to) public validAddress(_to) between tokenIsSet payable returns (uint256 amount) {
        return processContribution(_to);
    }

     
    function processContribution(address _to) private returns (uint256 amount) {

        uint256 tokenAmount = getTotalAmountOfTokens(msg.value);
        beneficiary.transfer(msg.value);
        token.transfer(_to, tokenAmount);
        token.addToAllocation(tokenAmount);
        CrowdsaleContribution(_to, msg.value, tokenAmount);
        return tokenAmount;
    }



 
    
     
    function totalEnjSold() public constant returns(uint256 total) {
        return token.totalAllocated();
    }
    
     
    function getTotalAmountOfTokens(uint256 _contribution) public constant returns (uint256 amountOfTokens) {
        uint256 currentTokenRate = 0;
        if (now < week2Start) {
            return currentTokenRate = safeMul(_contribution, 6000);
        } else if (now < week3Start) {
            return currentTokenRate = safeMul(_contribution, 5000);
        } else if (now < week4Start) {
            return currentTokenRate = safeMul(_contribution, 4000);
        } else {
            return currentTokenRate = safeMul(_contribution, 3000);
        }
        
    }

     
    function() payable {
        contributeETH(msg.sender);
    }
}