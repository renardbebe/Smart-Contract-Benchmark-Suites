 

pragma solidity ^ 0.4.17;


library SafeMath {

    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal  pure returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract Ownable {

    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
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

   
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

   
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


 
 
contract WhiteList is Ownable {
    
    mapping(address => bool) public whiteList;
    uint public totalWhiteListed;  

    event LogWhiteListed(address indexed user, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);
    event LogRemoveWhiteListed(address indexed user);

     
     
    function isWhiteListed(address _user) external view returns (bool) {

        return whiteList[_user]; 
    }

     
     
    function removeFromWhiteList(address _user) external onlyOwner() returns (bool) {
       
        require(whiteList[_user] == true);
        whiteList[_user] = false;
        totalWhiteListed--;
        LogRemoveWhiteListed(_user);
        return true;
    }

     
     
     
    function addToWhiteList(address _user) external onlyOwner()  returns (bool) {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            LogWhiteListed(_user, totalWhiteListed);            
        }
        return true;
    }

     
     
     
    function addToWhiteListMultiple(address[] _users) external onlyOwner()  returns (bool) {

        for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;                          
            }           
        }
        LogWhiteListedMultiple(totalWhiteListed); 
        return true;
    }
}


 
 
contract TokenVesting is Ownable {
    using SafeMath for uint;

    struct TokenHolder {
        uint weiReceived;  
        uint tokensToSend;  
        bool refunded;  
        uint releasedAmount;  
        bool revoked;  
    }

    event Released(uint256 amount, uint256 tokenDecimals);
    event ContractUpdated(bool done);

    uint256 public cliff;   
    uint256 public startCountDown;   
    uint256 public duration;  
    Token public token;   
    mapping(address => TokenHolder) public tokenHolders;  
    WhiteList public whiteList;  
    uint256 public presaleBonus;
    
     
     
     
     
     
    function initilizeVestingAndTokenAndWhiteList(Token _tokenAddress, 
                                        uint256 _start, 
                                        uint256 _cliff, 
                                        uint256 _duration,
                                        uint256 _presaleBonus, 
                                        WhiteList _whiteList) external onlyOwner() returns(bool res) {
        require(_cliff <= _duration);   
        require(_tokenAddress != address(0));
        duration = _duration;
        cliff = _start.add(_cliff);
        startCountDown = _start;  
        token = _tokenAddress; 
        whiteList = _whiteList;
        presaleBonus = _presaleBonus;
        ContractUpdated(true);
        return true;    
    }

     
     
     
    function initilizeVestingAndToken(Token _tokenAddress, 
                                        uint256 _start, 
                                        uint256 _cliff, 
                                        uint256 _duration,
                                        uint256 _presaleBonus
                                        ) external onlyOwner() returns(bool res) {
        require(_cliff <= _duration);   
        require(_tokenAddress != address(0));
        duration = _duration;
        cliff = _start.add(_cliff);
        startCountDown = _start;  
        token = _tokenAddress;        
        presaleBonus = _presaleBonus;
        ContractUpdated(true);
        return true;    
    }

    function returnVestingSchedule() external view returns (uint, uint, uint) {

        return (duration, cliff, startCountDown);
    }

     
     
    function revoke(address _user) public onlyOwner() {

        TokenHolder storage tokenHolder = tokenHolders[_user];
        tokenHolder.revoked = true; 
    }

    function vestedAmountAvailable() public view returns (uint amount, uint decimals) {

        TokenHolder storage tokenHolder = tokenHolders[msg.sender];
        uint tokensToRelease = vestedAmount(tokenHolder.tokensToSend);

      
       
      
        return (tokensToRelease - tokenHolder.releasedAmount, token.decimals());
    }
    
     
    function release() public {

        TokenHolder storage tokenHolder = tokenHolders[msg.sender];        
         
        require(!tokenHolder.revoked);                                   
        uint tokensToRelease = vestedAmount(tokenHolder.tokensToSend);      
        uint currentTokenToRelease = tokensToRelease - tokenHolder.releasedAmount;
        tokenHolder.releasedAmount += currentTokenToRelease;            
        token.transfer(msg.sender, currentTokenToRelease);

        Released(currentTokenToRelease, token.decimals());
    }
  
     
     
     
    function vestedAmount(uint _totalBalance) public view returns (uint) {

        if (now < cliff) {
            return 0;
        } else if (now >= startCountDown.add(duration)) {
            return _totalBalance;
        } else {
            return _totalBalance.mul(now.sub(startCountDown)) / duration;
        }
    }
}


 
 
contract Crowdsale is Pausable, TokenVesting {

    using SafeMath for uint;

    address public multisigETH;  
    address public commissionAddress;   
    uint public tokensForTeam;  
    uint public ethReceivedPresale;  
    uint public ethReceivedMain;  
    uint public totalTokensSent;  
    uint public tokensSentMain;
    uint public tokensSentPresale;       
    uint public tokensSentDev;         
    uint public startBlock;  
    uint public endBlock;  
    uint public maxCap;  
    uint public minCap;  
    uint public minContributionMainSale;  
    uint public minContributionPresale;  
    uint public maxContribution;
    bool public crowdsaleClosed;  
    uint public tokenPriceWei;
    uint public refundCount;
    uint public totalRefunded;
    uint public campaignDurationDays;  
    uint public firstPeriod; 
    uint public secondPeriod; 
    uint public thirdPeriod; 
    uint public firstBonus; 
    uint public secondBonus;
    uint public thirdBonus;
    uint public multiplier;
    uint public status;    
    Step public currentStep;   
   
     
     
    address[] public holdersIndex;    
    address[] public devIndex;    

     
    enum Step {      
        FundingPreSale,      
        FundingMainSale,   
        Refunding   
    }

     
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    modifier minCapNotReached() {
        if (totalTokensSent >= minCap) 
            revert();
        _;
    }

     
    event LogReceivedETH(address indexed backer, uint amount, uint tokenAmount);
    event LogStarted(uint startBlockLog, uint endBlockLog);
    event LogFinalized(bool success);  
    event LogRefundETH(address indexed backer, uint amount);
    event LogStepAdvanced();
    event LogDevTokensAllocated(address indexed dev, uint amount);
    event LogNonVestedTokensSent(address indexed user, uint amount);

     
     
    function Crowdsale(uint _decimalPoints,
                        address _multisigETH,
                        uint _toekensForTeam, 
                        uint _minContributionPresale,
                        uint _minContributionMainSale,
                        uint _maxContribution,                        
                        uint _maxCap, 
                        uint _minCap, 
                        uint _tokenPriceWei, 
                        uint _campaignDurationDays,
                        uint _firstPeriod, 
                        uint _secondPeriod, 
                        uint _thirdPeriod, 
                        uint _firstBonus, 
                        uint _secondBonus,
                        uint _thirdBonus) public {
        multiplier = 10**_decimalPoints;
        multisigETH = _multisigETH; 
        tokensForTeam = _toekensForTeam * multiplier; 
        minContributionPresale = _minContributionPresale; 
        minContributionMainSale = _minContributionMainSale;
        maxContribution = _maxContribution;       
        maxCap = _maxCap * multiplier;       
        minCap = _minCap * multiplier;
        tokenPriceWei = _tokenPriceWei;
        campaignDurationDays = _campaignDurationDays;
        firstPeriod = _firstPeriod; 
        secondPeriod = _secondPeriod; 
        thirdPeriod = _thirdPeriod;
        firstBonus = _firstBonus;
        secondBonus = _secondBonus;
        thirdBonus = _thirdBonus;       
         
        commissionAddress = 0x326B5E9b8B2ebf415F9e91b42c7911279d296ea1;
         
        currentStep = Step.FundingPreSale; 
    }

     
    function returnWebsiteData() external view returns(uint, 
        uint, uint, uint, uint, uint, uint, uint, uint, uint, bool, bool, uint, Step) {
    
        return (startBlock, endBlock, numberOfBackers(), ethReceivedPresale + ethReceivedMain, maxCap, minCap, 
                totalTokensSent, tokenPriceWei, minContributionPresale, minContributionMainSale, 
                paused, crowdsaleClosed, token.decimals(), currentStep);
    }
    
     
    function determineStatus() external view returns (uint) {
       
        if (crowdsaleClosed)             
            return 1;   

        if (block.number < endBlock && totalTokensSent < maxCap - 100)    
            return 2;            
    
        if (totalTokensSent < minCap && block.number > endBlock)       
            return 3;            
    
        if (endBlock == 0)            
            return 4;            
    
        return 0;         
    } 

     
     
    function () public payable {    
             
        contribute(msg.sender);
    }

     
    function contributePublic() external payable {
        contribute(msg.sender);
    }

     
     
     
    function advanceStep() external onlyOwner() {
        currentStep = Step.FundingMainSale;
        LogStepAdvanced();
    }

     
    function start() external onlyOwner() {
        startBlock = block.number;
        endBlock = startBlock + (4*60*24*campaignDurationDays);  
        crowdsaleClosed = false;
        LogStarted(startBlock, endBlock);
    }

     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);                       
        require(block.number >= endBlock || totalTokensSent > maxCap - 1000);
                     
                     
                     

        require(totalTokensSent >= minCap);
        crowdsaleClosed = true;
        
         
        commissionAddress.transfer(determineCommissions());         
        
         
        multisigETH.transfer(this.balance);
        
         
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}