 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
 
 
 
 
 
 
 

contract C4FEscrow {

    using SafeMath for uint;
    
    address public owner;
    address public requester;
    address public provider;

    uint256 public startTime;
    uint256 public closeTime;
    uint256 public deadline;
    
    uint256 public C4FID;
    uint8   public status;
    bool    public requesterLocked;
    bool    public providerLocked;
    bool    public providerCompleted;
    bool    public requesterDisputed;
    bool    public providerDisputed;
    uint8   public arbitrationCosts;

    event ownerChanged(address oldOwner, address newOwner);   
    event deadlineChanged(uint256 oldDeadline, uint256 newDeadline);
    event favorDisputed(address disputer);
    event favorUndisputed(address undisputer);
    event providerSet(address provider);
    event providerLockSet(bool lockstat);
    event providerCompletedSet(bool completed_status);
    event requesterLockSet(bool lockstat);
    event favorCompleted(address provider, uint256 tokenspaid);
    event favorCancelled(uint256 tokensreturned);
    event tokenOfferChanged(uint256 oldValue, uint256 newValue);
    event escrowArbitrated(address provider, uint256 coinsreturned, uint256 fee);

 
 
 

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }   

    modifier onlyRequester {
        require(msg.sender == requester);
        _;
    }   
    
    modifier onlyProvider {
        require(msg.sender == provider);
        _;
    }   

    modifier onlyOwnerOrRequester {
        require((msg.sender == owner) || (msg.sender == requester)) ;
        _;
    }   
    
    modifier onlyOwnerOrProvider {
        require((msg.sender == owner) || (msg.sender == provider)) ;
        _;        
    }
    
    modifier onlyProviderOrRequester {
        require((msg.sender == requester) || (msg.sender == provider)) ;
        _;        
    }

     
     
     
    function C4FEscrow(address newOwner, uint256 ID, address req, uint256 deadl, uint8 arbCostPercent) public {
        owner       = newOwner;  
        C4FID       = ID;
        requester   = req;
        provider    = address(0);
        startTime   = now;
        deadline    = deadl;
        status      = 1;         
        arbitrationCosts    = arbCostPercent;
        requesterLocked     = false;
        providerLocked      = false;
        providerCompleted   = false;
        requesterDisputed   = false;
        providerDisputed    = false;
    }
    
     
     
     
    function getOwner() public view returns (address ownner) {
        return owner;
    } 
    
    function setOwner(address newOwner) public onlyOwner returns (bool success) {
        require(newOwner != address(0));
        ownerChanged(owner,newOwner);
        owner = newOwner;
        return true;
    }
     
     
     
    function getRequester() public view returns (address req) {
        return requester;
    }

     
     
     
    function getProvider() public view returns (address prov) {
        return provider;
    }

     
     
     
    function getStartTime() public view returns (uint256 st) {
        return startTime;
    }    

     
     
     
     
     
    function getDeadline() public view returns (uint256 actDeadline) {
        actDeadline = deadline;
        return actDeadline;
    }
    
     
     
     
     
    function changeDeadline(uint newDeadline) public onlyRequester returns (bool success) {
         
        require ((!providerLocked) && (!providerDisputed) && (!providerCompleted) && (status==1));
        deadlineChanged(newDeadline, deadline);
        deadline = newDeadline;
        return true;
    }

     
     
     
    function getStatus() public view returns (uint8 s) {
        return status;
    }

     
     
     
     
     
    function disputeFavor() public onlyProviderOrRequester returns (bool success) {
        if(msg.sender == requester) {
            requesterDisputed = true;
        }
        if(msg.sender == provider) {
            providerDisputed = true;
            providerLocked = true;
        }
        favorDisputed(msg.sender);
        return true;
    }
     
     
     
    function undisputeFavor() public onlyProviderOrRequester returns (bool success) {
        if(msg.sender == requester) {
            requesterDisputed = false;
        }
        if(msg.sender == provider) {
            providerDisputed = false;
        }
        favorUndisputed(msg.sender);
        return true;
    }
    
     
     
     
     
     
    function setProvider(address newProvider) public onlyOwnerOrRequester returns (bool success) {
         
        require(!providerLocked);
        require(!requesterLocked);
        provider = newProvider;
        providerSet(provider);
        return true;
    }
    
     
     
     
     
     
    function setProviderLock(bool lock) public onlyOwnerOrProvider returns (bool res) {
        providerLocked = lock;
        providerLockSet(lock);
        return providerLocked;
    }

     
     
     
     
    function setProviderCompleted(bool c) public onlyOwnerOrProvider returns (bool res) {
        providerCompleted = c;
        providerCompletedSet(c);
        return c;
    }
    
     
     
     
    function setRequesterLock(bool lock) public onlyOwnerOrRequester returns (bool res) {
        requesterLocked = lock;
        requesterLockSet(lock);
        return requesterLocked;
    }
    

    function getRequesterLock() public onlyOwnerOrRequester view returns (bool res) {
        res = requesterLocked;
        return res;
    }


     
     
     
    function setStatus(uint8 newStatus) public onlyOwner returns (uint8 stat) {
        status = newStatus;    
        stat = status;
        return stat;
    }

     
     
     
     
    function getTokenValue() public view returns (uint256 tokens) {
        C4FToken C4F = C4FToken(owner);
        return C4F.balanceOf(address(this));
    }

     
     
     
    function completeFavor() public onlyRequester returns (bool success) {
         
        require(provider != address(0));
        
         
        uint256 actTokenvalue = getTokenValue();
        C4FToken C4F = C4FToken(owner);
        if(!C4F.transferWithCommission(provider, actTokenvalue)) revert();
        closeTime = now;
        status = 3;
        favorCompleted(provider,actTokenvalue);
        return true;
    }

     
     
     
     
     
    function cancelFavor() public onlyRequester returns (bool success) {
         
        require((!providerLocked) || ((now > deadline.add(12*3600)) && (!providerCompleted) && (!providerDisputed)));
         
        require(status==1);
         
        uint256 actTokenvalue = getTokenValue();
        C4FToken C4F = C4FToken(owner);
        if(!C4F.transfer(requester,actTokenvalue)) revert();
        closeTime = now;
        status = 2;
        favorCancelled(actTokenvalue);
        return true;
    }
    
     
     
     
     
    function changeTokenOffer(uint256 newOffer) public onlyRequester returns (bool success) {
         
        require((!providerLocked) && (!providerDisputed) && (!providerCompleted));
         
        require(status==1);
         
        uint256 actTokenvalue = getTokenValue();
        require(newOffer < actTokenvalue);
         
        require(newOffer > 0);
         
        C4FToken C4F = C4FToken(owner);
        if(!C4F.transfer(requester, actTokenvalue.sub(newOffer))) revert();
        tokenOfferChanged(actTokenvalue,newOffer);
        return true;
    }
    
     
     
     
     
     
     
     
    function arbitrateC4FContract(uint8 percentReturned) public onlyOwner returns (bool success) {
         
        require((providerDisputed) || (requesterDisputed));
         
        uint256 actTokens = getTokenValue();
        
         
        uint256 arbitrationTokens = actTokens.mul(arbitrationCosts);
        arbitrationTokens = arbitrationTokens.div(100);
         
        actTokens = actTokens.sub(arbitrationTokens);
        
         
        uint256 requesterTokens = actTokens.mul(percentReturned);
        requesterTokens = requesterTokens.div(100);
         
        actTokens = actTokens.sub(requesterTokens);
        
         
        C4FToken C4F = C4FToken(owner);
         
        address commissionTarget = C4F.getCommissionTarget();
         
        if(!C4F.transfer(requester, requesterTokens)) revert();
         
        if(!C4F.transfer(provider, actTokens)) revert();
         
        if(!C4F.transfer(commissionTarget, arbitrationTokens)) revert();
        
         
        status = 4;
        closeTime = now;
        success = true;
        escrowArbitrated(provider,requesterTokens,arbitrationTokens);
        return success;
    }

}

 
 
 
 
 
 
 
 
 
 
 
 
 

contract C4FToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint8 public _crowdsalePaused;
    uint public _totalSupply;
    uint public _salesprice;
    uint public _endOfICO;
    uint public _endOfPreICO;
    uint public _beginOfICO;
    uint public _bonusTime1;
    uint public _bonusTime2;
    uint public _bonusRatio1;
    uint public _bonusRatio2;
    uint public _percentSoldInPreICO;
    uint public _maxTokenSoldPreICO;
    uint public _percentSoldInICO;
    uint public _maxTokenSoldICO;
    uint public _total_sold;
    uint public _commission;
    uint8 public _arbitrationPercent;
    address public _commissionTarget;
    uint public _minimumContribution;
    address[]   EscrowAddresses;
    uint public _escrowIndex;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) whitelisted_amount;
    mapping(address => bool) C4FEscrowContracts;
    
    
    event newEscrowCreated(uint ID, address contractAddress, address requester);   
    event ICOStartSet(uint256 starttime);
    event ICOEndSet(uint256 endtime);
    event PreICOEndSet(uint256 endtime);
    event BonusTime1Set(uint256 bonustime);
    event BonusTime2Set(uint256 bonustime);
    event accountWhitelisted(address account, uint256 limit);
    event crowdsalePaused(bool paused);
    event crowdsaleResumed(bool resumed);
    event commissionSet(uint256 commission);
    event commissionTargetSet(address target);
    event arbitrationPctSet(uint8 arbpercent);
    event contractOwnerChanged(address escrowcontract, address newOwner);
    event contractProviderChanged(address C4Fcontract, address provider);
    event contractArbitrated(address C4Fcontract, uint8 percentSplit);
    
     
     
     
    function C4FToken() public {
        symbol          = "C4F";
        name            = "C4F FavorCoins";
        decimals        = 18;
        
        _totalSupply    = 100000000000 * 10**uint(decimals);

        _salesprice     = 2000000;       
        _minimumContribution = 0.05 * 10**18;     
        
        _endOfICO       = 1532908800;    
        _beginOfICO     = 1526342400;    
        _bonusRatio1    = 110;           
        _bonusRatio2    = 125;           
        _bonusTime1     = 1527638400;    
        _bonusTime2     = 1526947200;    
        _endOfPreICO    = 1527811200;    
        
        _percentSoldInPreICO = 10;       
        _maxTokenSoldPreICO = _totalSupply.mul(_percentSoldInPreICO);
        _maxTokenSoldPreICO = _maxTokenSoldPreICO.div(100);
        
        _percentSoldInICO   = 60;       
        _maxTokenSoldICO    = _totalSupply.mul(_percentSoldInPreICO.add(_percentSoldInICO));
        _maxTokenSoldICO    = _maxTokenSoldICO.div(100);
        
        _total_sold         = 0;             
        
        _commission         = 0;             
        _commissionTarget   = owner;         
        _arbitrationPercent = 10;            
                                             
        
        _crowdsalePaused    = 0;

        balances[owner]     = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

     
     
     
    
    modifier notLocked {
        require((msg.sender == owner) || (now >= _endOfICO));
        _;
    }
    
     
     
     
    
    modifier onlyDuringICO {
        require((now >= _beginOfICO) && (now <= _endOfICO));
        _;
    }
    
     
     
     
    
    modifier notPaused {
        require(_crowdsalePaused == 0);
        _;
    }
    
     
     
     

    function setICOStart(uint ICOdate) public onlyOwner returns (bool success) {
        _beginOfICO  = ICOdate;
        ICOStartSet(_beginOfICO);
        return true;
    }
    
    function setICOEnd(uint ICOdate) public onlyOwner returns (bool success) {
        _endOfICO  = ICOdate;
        ICOEndSet(_endOfICO);
        return true;
    }
    
    function setPreICOEnd(uint ICOdate) public onlyOwner returns (bool success) {
        _endOfPreICO = ICOdate;
        PreICOEndSet(_endOfPreICO);
        return true;
    }
    
    function setBonusDate1(uint ICOdate) public onlyOwner returns (bool success) {
        _bonusTime1 = ICOdate;
        BonusTime1Set(_bonusTime1);
        return true;
    }

    function setBonusDate2(uint ICOdate) public onlyOwner returns (bool success) {
        _bonusTime2 = ICOdate;
        BonusTime2Set(_bonusTime2);
        return true;
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
    function whitelistAccount(address account, uint limit) public onlyOwner {
        whitelisted_amount[account] = limit*10**18;
        accountWhitelisted(account,limit);
    }
    
     
     
     
    function getWhitelistLimit(address account) public constant returns (uint limit) {
        return whitelisted_amount[account];
    }

     
     
     
    function pauseCrowdsale() public onlyOwner returns (bool success) {
        _crowdsalePaused = 1;
        crowdsalePaused(true);
        return true;
    }

    function resumeCrowdsale() public onlyOwner returns (bool success) {
        _crowdsalePaused = 0;
        crowdsaleResumed(true);
        return true;
    }
    
    
     
     
     
     
    function setCommission(uint comm) public onlyOwner returns (bool success) {
        require(comm < 200);  
        _commission = comm;
        commissionSet(comm);
        return true;
    }

    function setArbitrationPercentage(uint8 arbitPct) public onlyOwner returns (bool success) {
        require(arbitPct <= 15);  
        _arbitrationPercent = arbitPct;
        arbitrationPctSet(_arbitrationPercent);
        return true;
    }

    function setCommissionTarget(address ct) public onlyOwner returns (bool success) {
        _commissionTarget = ct;
        commissionTargetSet(_commissionTarget);
        return true;
    }
    
    function getCommissionTarget() public view returns (address ct) {
        ct = _commissionTarget;
        return ct;
    }

     
     
     
     
     
     
     
    function transfer(address to, uint tokens) public notLocked notPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
     
     
     
     
    function transferWithCommission(address to, uint tokens) public notLocked notPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
         
        uint comTokens = tokens.mul(_commission);
        comTokens = comTokens.div(10000);
         
        balances[to] = balances[to].add(tokens.sub(comTokens));
        balances[_commissionTarget] = balances[_commissionTarget].add(comTokens);
         
        Transfer(msg.sender, to, tokens.sub(comTokens));
        Transfer(msg.sender, _commissionTarget, comTokens);
        return true;
    }

    
     
     
     
    function transferInternal(address to, uint tokens) private returns (bool success) {
        balances[owner] = balances[owner].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public notLocked notPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public notLocked notPaused returns (bool success) {
         
        require(allowed[from][msg.sender] >= tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
    
    function startFavorEscrow(uint256 ID, uint256 deadl, uint tokens) public notLocked returns (address C4FFavorContractAddr) {
         
        require(balanceOf(msg.sender) >= tokens);
         
        address newFavor = new C4FEscrow(address(this), ID, msg.sender, deadl, _arbitrationPercent);
         
        EscrowAddresses.push(newFavor);
        C4FEscrowContracts[newFavor] = true;
         
        if(!transfer(newFavor, tokens)) revert();
        C4FFavorContractAddr = newFavor;
        newEscrowCreated(ID, newFavor, msg.sender);
        return C4FFavorContractAddr;
    }

    function isFavorEscrow(uint id, address c4fes) public view returns (bool res) {
        if(EscrowAddresses[id] == c4fes) {
                res = true;
            } else {
                res = false;
            }
        return res;
    }
    
    function getEscrowCount() public view returns (uint) {
        return EscrowAddresses.length;
    }
    
    function getEscrowAddress(uint ind) public view returns(address esa) {
        require (ind <= EscrowAddresses.length);
        esa = EscrowAddresses[ind];
        return esa;
    }
    
    
     
    function setC4FContractOwner(address C4Fcontract, address newOwner) public onlyOwner returns (bool success) {
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        if(!c4fec.setOwner(newOwner)) revert();
        contractOwnerChanged(C4Fcontract,newOwner);
        return true;
    }
    
     
    function setC4FContractProvider(address C4Fcontract, address provider) public onlyOwner returns (bool success) {
         
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        if(!c4fec.setProvider(provider)) revert();
        contractProviderChanged(C4Fcontract, provider);
        return true;
    }
    
     
    function setC4FContractProviderLock(address C4Fcontract, bool lock) public onlyOwner returns (bool res) {
         
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        res = c4fec.setProviderLock(lock);
        return res;
    }
    
     
    function setC4FContractProviderCompleted(address C4Fcontract, bool completed) public onlyOwner returns (bool res) {
         
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        res = c4fec.setProviderCompleted(completed);
        return res;
    }
    
         
    function setC4FContractRequesterLock(address C4Fcontract, bool lock) public onlyOwner returns (bool res) {
         
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        res = c4fec.setRequesterLock(lock);
        return res;
    }

    function setC4FContractStatus(address C4Fcontract, uint8 newStatus) public onlyOwner returns (uint8 s) {
         
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        s = c4fec.setStatus(newStatus);
        return s;
    }
    
    function arbitrateC4FContract(address C4Fcontract, uint8 percentSplit) public onlyOwner returns (bool success) {
         
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
         
        if(!c4fec.arbitrateC4FContract(percentSplit)) revert();
        contractArbitrated(C4Fcontract, percentSplit);
        return true;
    }

    
     
     
     
    function () public onlyDuringICO notPaused payable  {
         
        uint bonusratio = 100;
         
        if(now <= _bonusTime1) {
            bonusratio = _bonusRatio1;    
        }
         
        if(now <= _bonusTime2) {
            bonusratio = _bonusRatio2;    
        }
        
         
        require (msg.value >= _minimumContribution);
        
         
        if (msg.value > 0) {
            
             
            if(!(whitelisted_amount[msg.sender] >= msg.value)) revert();
             
            whitelisted_amount[msg.sender] = whitelisted_amount[msg.sender].sub(msg.value);
            
             
            uint256 token_amount = msg.value.mul(_salesprice);
            token_amount = token_amount.mul(bonusratio);
            token_amount = token_amount.div(100);
            
            uint256 new_total = _total_sold.add(token_amount);
             
            if(now <= _endOfPreICO){
                 
                if(new_total > _maxTokenSoldPreICO) revert();
            }
            
             
            if(new_total > _maxTokenSoldICO) revert();
            
             
            if(!transferInternal(msg.sender, token_amount)) revert();
            _total_sold = new_total;
             
            if (!owner.send(msg.value)) revert();  
        }
    }
}