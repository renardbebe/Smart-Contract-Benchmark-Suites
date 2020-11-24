 

pragma solidity 0.4.24;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract QuickxToken is ERC20 {
    using SafeMath for uint;


     
     
     
    event LogBurn(address indexed from, uint256 amount);
    event LogFreezed(address targetAddress, bool frozen);
    event LogEmerygencyFreezed(bool emergencyFreezeStatus);

     
     
     
    string public name = "QuickX Protocol";
    string public symbol = "QCX";
    uint8 public decimals = 8;
    address public owner;
    uint public totalSupply = 500000000 * (10 ** 8);
    uint public currentSupply = 250000000 * (10 ** 8);  
    bool public emergencyFreeze = true;
  
     
     
     
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint) ) private  allowed;
    mapping (address => bool) private frozen;

     
     
     
    constructor () public {
        owner = address(0x2cf93Eed42d4D0C0121F99a4AbBF0d838A004F64);
    }

     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier unfreezed(address _account) { 
        require(!frozen[_account]);
        _;  
    }
    
    modifier noEmergencyFreeze() { 
        require(!emergencyFreeze);
        _; 
    }

     
     
     
    function transfer(address _to, uint _value)
    public
    unfreezed(_to) 
    unfreezed(msg.sender) 
    noEmergencyFreeze()  
    returns (bool success) {
        require(_to != 0x0);
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _value)
        public 
        unfreezed(_spender) 
        unfreezed(msg.sender) 
        noEmergencyFreeze() 
        returns (bool success) {
             
             
             
             
            require((_value == 0) || (allowed[msg.sender][_spender] == 0));
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }

    function increaseApproval(address _spender, uint _addedValue)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success) {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
        }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success) {
            uint oldAllowance = allowed[msg.sender][_spender];
            if (_subtractedValue > oldAllowance) {
                allowed[msg.sender][_spender] = 0;
            } else {
                allowed[msg.sender][_spender] = oldAllowance.sub(_subtractedValue);
            }
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
        }

     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public 
        unfreezed(_to)
        unfreezed(_from) 
        noEmergencyFreeze() 
        returns (bool success) {
            require(_value <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
        }

     
     
     
     
     
     
    function freezeAccount (address _target, bool _freeze) public onlyOwner {
        require(_target != 0x0);
        frozen[_target] = _freeze;
        emit LogFreezed(_target, _freeze);
    }

     
     
     
    function emergencyFreezeAllAccounts (bool _freeze) public onlyOwner {
        emergencyFreeze = _freeze;
        emit LogEmerygencyFreezed(_freeze);
    }

     
     
     
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        currentSupply = currentSupply.sub(_value);
        emit LogBurn(msg.sender, _value);
        return true;
    }

     
     
     
     
     
     
    function balanceOf(address _tokenOwner) public view returns (uint) {
        return balances[_tokenOwner];
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

     
     
     
    function allowance(address _tokenOwner, address _spender) public view returns (uint) {
        return allowed[_tokenOwner][_spender];
    }

     
     
     
    function isFreezed(address _targetAddress) public view returns (bool) {
        return frozen[_targetAddress]; 
    }

    function _transfer(address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        uint balBeforeTransfer = balances[from].add(balances[to]);
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        uint balAfterTransfer = balances[from].add(balances[to]);
        assert(balBeforeTransfer == balAfterTransfer);
        emit Transfer(from, to, amount);
    }
}


contract QuickxProtocol is QuickxToken {
    using SafeMath for uint;
     
     
     
     
    uint public tokenSaleAllocation = 250000000 * (10 ** 8);
     
    uint public bountyAllocation = 10000000 * (10 ** 8); 
     
    uint public founderAllocation =  65000000 * (10 ** 8); 
     
    uint public partnersAllocation = 25000000 * (10 ** 8); 
     
    uint public liquidityReserveAllocation = 75000000 * (10 ** 8); 
     
    uint public advisoryAllocation = 25000000 * (10 ** 8); 
     
    uint public preSeedInvestersAllocation = 50000000 * (10 ** 8); 
    
    uint[] public founderFunds = [
        1300000000000000,
        2600000000000000, 
        3900000000000000, 
        5200000000000000, 
        6500000000000000
    ];  

    uint[] public advisoryFunds = [
        500000000000000, 
        1000000000000000,
        1500000000000000, 
        2000000000000000, 
        2500000000000000
    ];

    uint public founderFundsWithdrawn = 0;
    uint public advisoryFundsWithdrawn = 0;
     
    bool public bountyAllocated;
     
    bool public partnersAllocated;
    bool public liquidityReserveAllocated;
    bool public preSeedInvestersAllocated;
    
    uint public icoSuccessfulTime;
    bool public isIcoSuccessful;

    address public beneficiary;    

     
    uint private totalRaised = 0;      
    uint private totalCoinsSold = 0;    
    uint private softCap;              
    uint private hardCap;              
     
    uint private rateNum;               
    uint private rateDeno;               
    uint public tokenSaleStart;        
    uint public tokenSaleEnds;         
    bool public icoPaused;             

     
     
     
    event LogBontyAllocated(
        address recepient, 
        uint amount);

    event LogPartnersAllocated(
        address recepient, 
        uint amount);

    event LogLiquidityreserveAllocated(
        address recepient, 
        uint amount);

    event LogPreSeedInverstorsAllocated(
        address recepient,
        uint amount);

    event LogAdvisorsAllocated(
        address recepient, 
        uint amount);

    event LogFoundersAllocated(
        address indexed recepient, 
        uint indexed amount);
    
     
    event LogFundingReceived(
        address indexed addr, 
        uint indexed weiRecieved, 
        uint indexed tokenTransferred, 
        uint currentTotal);

    event LogRateUpdated(
        uint rateNum, 
        uint rateDeno); 

    event LogPaidToOwner(
        address indexed beneficiary,
        uint indexed amountPaid);

    event LogWithdrawnRemaining(
        address _owner, 
        uint amountWithdrawan);

    event LogIcoEndDateUpdated(
        uint _oldEndDate, 
        uint _newEndDate);

    event LogIcoSuccessful();
    
     
    mapping (address => uint) public contributedAmount;  

     
     
     
    constructor () public {
        owner = address(0x2cf93Eed42d4D0C0121F99a4AbBF0d838A004F64);
        rateNum = 75;
        rateDeno = 100000000;
        softCap = 4000  ether;
        hardCap = 30005019135500000000000  wei;
        tokenSaleStart = now;
        tokenSaleEnds = now;
        balances[this] = currentSupply;
        isIcoSuccessful = true;
        icoSuccessfulTime = now;
        beneficiary = address(0x2cf93Eed42d4D0C0121F99a4AbBF0d838A004F64);
        emit LogIcoSuccessful();
        emit Transfer(0x0, address(this), currentSupply);
    }

     
    function () public payable {
        require(msg.data.length == 0);
        contribute();
    }

    modifier isFundRaising() { 
        require(
            totalRaised <= hardCap &&
            now >= tokenSaleStart &&
            now < tokenSaleEnds &&
            !icoPaused
            );
        _;
    }

     
     
     
    function allocateBountyTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!bountyAllocated); 
        balances[owner] = balances[owner].add(bountyAllocation);
        currentSupply = currentSupply.add(bountyAllocation);
        bountyAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogBontyAllocated(owner, bountyAllocation);
        emit Transfer(0x0, owner, bountyAllocation);
    }

    function allocatePartnersTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!partnersAllocated);
        balances[owner] = balances[owner].add(partnersAllocation);
        currentSupply = currentSupply.add(partnersAllocation);
        partnersAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogPartnersAllocated(owner, partnersAllocation);
        emit Transfer(0x0, owner, partnersAllocation);
    }

    function allocateLiquidityReserveTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!liquidityReserveAllocated);
        balances[owner] = balances[owner].add(liquidityReserveAllocation);
        currentSupply = currentSupply.add(liquidityReserveAllocation);
        liquidityReserveAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogLiquidityreserveAllocated(owner, liquidityReserveAllocation);
        emit Transfer(0x0, owner, liquidityReserveAllocation);
    }

    function allocatePreSeedInvesterTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!preSeedInvestersAllocated);
        balances[owner] = balances[owner].add(preSeedInvestersAllocation);
        currentSupply = currentSupply.add(preSeedInvestersAllocation);
        preSeedInvestersAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogPreSeedInverstorsAllocated(owner, preSeedInvestersAllocation);
        emit Transfer(0x0, owner, preSeedInvestersAllocation);
    }

    function allocateFounderTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        uint calculatedFunds = calculateFoundersTokens();
        uint eligibleFunds = calculatedFunds.sub(founderFundsWithdrawn);
        require(eligibleFunds > 0);
        balances[owner] = balances[owner].add(eligibleFunds);
        currentSupply = currentSupply.add(eligibleFunds);
        founderFundsWithdrawn = founderFundsWithdrawn.add(eligibleFunds);
        assert(currentSupply <= totalSupply);
        emit LogFoundersAllocated(owner, eligibleFunds);
        emit Transfer(0x0, owner, eligibleFunds);
    }

    function allocateAdvisoryTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        uint calculatedFunds = calculateAdvisoryTokens();
        uint eligibleFunds = calculatedFunds.sub(advisoryFundsWithdrawn);
        require(eligibleFunds > 0);
        balances[owner] = balances[owner].add(eligibleFunds);
        currentSupply = currentSupply.add(eligibleFunds);
        advisoryFundsWithdrawn = advisoryFundsWithdrawn.add(eligibleFunds);
        assert(currentSupply <= totalSupply);
        emit LogAdvisorsAllocated(owner, eligibleFunds);
        emit Transfer(0x0, owner, eligibleFunds);
    }

     
     
    function withdrawEth () public onlyOwner {
        owner.transfer(address(this).balance);
        emit LogPaidToOwner(owner, address(this).balance);
    }

    function updateRate (uint _rateNum, uint _rateDeno) public onlyOwner {
        rateNum = _rateNum;
        rateDeno = _rateDeno;
        emit LogRateUpdated(rateNum, rateDeno);
    }

    function updateIcoEndDate(uint _newDate) public onlyOwner {
        uint oldEndDate = tokenSaleEnds;
        tokenSaleEnds = _newDate;
        emit LogIcoEndDateUpdated (oldEndDate, _newDate);
    }

     
    function withdrawUnsold() public onlyOwner returns (bool) {
        require(now > tokenSaleEnds);
        uint unsold = (tokenSaleAllocation.sub(totalCoinsSold));
        balances[owner] = balances[owner].add(unsold);
        balances[address(this)] = balances[address(this)].sub(unsold);
        emit LogWithdrawnRemaining(owner, unsold);
        emit Transfer(address(this), owner, unsold);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool success) {
         
        if (_tokenAddress == address(this)) {
            require(now > tokenSaleStart + 730 days);  
        }
        return ERC20(_tokenAddress).transfer(owner, _value);
    }

    function pauseICO(bool pauseStatus) public onlyOwner returns (bool status) {
        require(icoPaused != pauseStatus);
        icoPaused = pauseStatus;
        return true;
    }

     
     
     
    function contribute () public payable isFundRaising returns(bool) {
        uint calculatedTokens =  calculateTokens(msg.value);
        require(calculatedTokens > 0);
        require(totalCoinsSold.add(calculatedTokens) <= tokenSaleAllocation);
        contributedAmount[msg.sender] = contributedAmount[msg.sender].add(msg.value);
        totalRaised = totalRaised.add(msg.value);
        totalCoinsSold = totalCoinsSold.add(calculatedTokens);
        _transfer(address(this), msg.sender, calculatedTokens);
        beneficiary.transfer(msg.value);
        checkIfSoftCapReached();
        emit LogFundingReceived(msg.sender, msg.value, calculatedTokens, totalRaised);
        emit LogPaidToOwner(beneficiary, msg.value);
        return true;
    }

     
     
     
    function calculateTokens(uint weisToTransfer) public view returns(uint) {
        uint discount = calculateDiscount();
        uint coins = weisToTransfer.mul(rateNum).mul(discount).div(100 * rateDeno);
        return coins;
    }

    function getTotalWeiRaised () public view returns(uint totalEthRaised) {
        return totalRaised;
    }

    function getTotalCoinsSold() public view returns(uint _coinsSold) {
        return totalCoinsSold;
    }
      
    function getSoftCap () public view returns(uint _softCap) {
        return softCap;
    }

    function getHardCap () public view returns(uint _hardCap) {
        return hardCap;
    }

    function getContractOwner () public view returns(address contractOwner) {
        return owner;
    }

    function isContractAcceptingPayment() public view returns (bool) {
        if (totalRaised < hardCap && 
            now >= tokenSaleStart && 
            now < tokenSaleEnds && 
            totalCoinsSold < tokenSaleAllocation)
            return true;
        else
            return false;
    }

     
     
     
    function calculateFoundersTokens() internal view returns(uint) {
        uint timeAferIcoSuceess = now.sub(icoSuccessfulTime);
        uint timeSpendInMonths = timeAferIcoSuceess.div(30 days);
        if (timeSpendInMonths >= 3 && timeSpendInMonths < 6) {
            return founderFunds[0];
        } else  if (timeSpendInMonths >= 6 && timeSpendInMonths < 9) {
            return founderFunds[1];
        } else if (timeSpendInMonths >= 9 && timeSpendInMonths < 12) {
            return founderFunds[2];
        } else if (timeSpendInMonths >= 12 && timeSpendInMonths < 18) {
            return founderFunds[3];
        } else if (timeSpendInMonths >= 18) {
            return founderFunds[4];
        } else {
            revert();
        }
    } 

    function calculateAdvisoryTokens()internal view returns(uint) {
        uint timeSpentAfterIcoEnd = now.sub(icoSuccessfulTime);
        uint timeSpendInMonths = timeSpentAfterIcoEnd.div(30 days);
        if (timeSpendInMonths >= 0 && timeSpendInMonths < 3)
            return advisoryFunds[0];
        if (timeSpendInMonths < 6)
            return advisoryFunds[1];
        if (timeSpendInMonths < 9)
            return advisoryFunds[2];
        if (timeSpendInMonths < 12)
            return advisoryFunds[3];
        if (timeSpendInMonths >= 12)
            return advisoryFunds[4];
        revert();
    }

    function checkIfSoftCapReached() internal returns (bool) {
        if (totalRaised >= softCap && !isIcoSuccessful) {
            isIcoSuccessful = true;
            icoSuccessfulTime = now;
            emit LogIcoSuccessful();
        }
        return;
    }

    function calculateDiscount() internal view returns(uint) {
        if (totalCoinsSold < 12500000000000000) {
            return 115;    
        } else if (totalCoinsSold < 18750000000000000) {
            return 110;    
        } else if (totalCoinsSold < 25000000000000000) {
            return 105;    
        } else {   
            return 100;    
        }
    }

}