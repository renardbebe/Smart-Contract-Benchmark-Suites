 

pragma solidity 0.4.23;

 
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


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}


contract ParsecTokenERC20 {
     
    string public constant name = "Parsec Credits";
    string public constant symbol = "PRSC";
    uint8 public decimals = 6;
    uint256 public initialSupply = 30856775800;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function ParsecTokenERC20() public {
         
        totalSupply = initialSupply * 10 ** uint256(decimals);

         
        balanceOf[msg.sender] = totalSupply;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);

         
        require(balanceOf[_from] >= _value);

         
        require(balanceOf[_to] + _value > balanceOf[_to]);

         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

         
        balanceOf[_from] -= _value;

         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(balanceOf[msg.sender] >= _value);

         
        balanceOf[msg.sender] -= _value;

         
        totalSupply -= _value;

         
        Burn(msg.sender, _value);

        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
         
        require(balanceOf[_from] >= _value);

         
        require(_value <= allowance[_from][msg.sender]);

         
        balanceOf[_from] -= _value;

         
        allowance[_from][msg.sender] -= _value;

         
        totalSupply -= _value;

         
        Burn(_from, _value);

        return true;
    }
}


contract ParsecCrowdsale is owned {
     
    using SafeMath for uint256;

     
    enum KycState {
        Undefined,   
        Pending,     
        Accepted,    
        Declined     
    }

     
     
     

     
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT = 0.1 ether;

     
    uint256 public constant PARSECS_PER_ETHER_BASE = 1300000000000;       

     
    uint256 public constant PARSECS_TOTAL_AMOUNT = 16103862002000000;     

     
     
     
    
    uint256 public constant BONUS_TIER_1_LIMIT = 715 ether;      
    uint256 public constant BONUS_TIER_2_LIMIT = 1443 ether;     
    uint256 public constant BONUS_TIER_3_LIMIT = 2434 ether;     
    uint256 public constant BONUS_TIER_4_LIMIT = 3446 ether;     
    uint256 public constant BONUS_TIER_5_LIMIT = 4478 ether;     
    uint256 public constant BONUS_TIER_6_LIMIT = 5532 ether;     
    uint256 public constant BONUS_TIER_7_LIMIT = 6609 ether;     
    uint256 public constant BONUS_TIER_8_LIMIT = 7735 ether;     
    uint256 public constant BONUS_TIER_9_LIMIT = 9210 ether;     

     
     
     

     
    ParsecTokenERC20 private parsecToken;

     
    address public multisigAddress;

     
    address public auditorAddress;

     
     
     

     
    bool public contractPoweredUp = false;

     
    bool public refundPoweredUp = false;

     
     
     

     
    bool public contractStarted = false;

     
    bool public contractFinished = false;

     
    bool public contractPaused = false;

     
    bool public contractFailed = false;

     
    bool public contractRefundStarted = false;

     
    bool public contractRefundFinished = false;

     
     
     

     
    uint256 public raisedFunding;
       
     
    uint256 public pendingFunding;

     
    uint256 public refundedFunding;

     
     
     

     
    uint256 public spentParsecs;
    
     
    uint256 public pendingParsecs;

     
     
     

     
    mapping (address => uint256) public contributionOf;

     
    mapping (address => uint256) public parsecsOf;

     
    mapping (address => uint256) public pendingContributionOf;

     
    mapping (address => uint256) public pendingParsecsOf;

     
    mapping (address => uint256) public refundOf;

     
     
     

     
    mapping (address => KycState) public kycStatus;

     
     
     

     
    event LogKycAccept(address indexed sender, uint256 value, uint256 timestamp);

     
    event LogKycDecline(address indexed sender, uint256 value, uint256 timestamp);

     
    event LogContribution(address indexed sender, uint256 ethValue, uint256 parsecValue, uint256 timestamp);

     
    function ParsecCrowdsale (address _tokenAddress, address _multisigAddress, address _auditorAddress) public {
         
        parsecToken = ParsecTokenERC20(_tokenAddress);

         
        multisigAddress = _multisigAddress;
        auditorAddress = _auditorAddress;
    }

     
    modifier onlyOwnerOrMultisig {
        require(msg.sender == owner || msg.sender == multisigAddress);
        _;
    }

     
    modifier onlyOwnerOrAuditor {
        require(msg.sender == owner || msg.sender == auditorAddress);
        _;
    }

     
     
     
     
     
     
     
     
     
    function () public payable {
         
        require(contractPoweredUp);

         
        require(contractStarted);

         
        require(!contractFinished);

         
        require(!contractPaused);

         
        require(!contractFailed);

         
        require(msg.value >= MINIMUM_PARTICIPATION_AMOUNT);

         
        uint256 parsecValue = calculateReward(msg.value);

         
        uint256 maxAcceptableParsecs = PARSECS_TOTAL_AMOUNT.sub(spentParsecs);
        maxAcceptableParsecs = maxAcceptableParsecs.sub(pendingParsecs);

         
        require(parsecValue <= maxAcceptableParsecs);

         
        if (kycStatus[msg.sender] == KycState.Undefined) {
            kycStatus[msg.sender] = KycState.Pending;
        }

        if (kycStatus[msg.sender] == KycState.Pending) {
             
            addPendingContribution(msg.sender, msg.value, parsecValue);
        } else if (kycStatus[msg.sender] == KycState.Accepted) {
             
            addAcceptedContribution(msg.sender, msg.value, parsecValue);
        } else {
             
            revert();
        }
    }

     
    function emergencyWithdrawParsecs(uint256 value) external onlyOwnerOrMultisig {
         
        require(value > 0);
        require(value <= parsecToken.balanceOf(this));

         
        parsecToken.transfer(msg.sender, value);
    }

     
    function emergencyRefundContract() external payable onlyOwnerOrMultisig {
         
        require(contractFailed);
        
         
        require(msg.value > 0);
    }

     
    function emergencyClawbackEther(uint256 value) external onlyOwnerOrMultisig {
         
        require(contractFailed);

         
        require(contractRefundStarted);
        require(contractRefundFinished);
        
         
        require(value > 0);
        require(value <= address(this).balance);

         
        msg.sender.transfer(value);
    }

     
    function ownerSetAuditor(address _auditorAddress) external onlyOwner {
         
        require(_auditorAddress != 0x0);

         
        auditorAddress = _auditorAddress;
    }

     
    function ownerPowerUpContract() external onlyOwner {
         
        require(!contractPoweredUp);

         
        require(parsecToken.balanceOf(this) >= PARSECS_TOTAL_AMOUNT);

         
        contractPoweredUp = true;
    }

     
    function ownerStartContract() external onlyOwner {
         
        require(contractPoweredUp);

         
        require(!contractStarted);

         
        contractStarted = true;
    }

     
    function ownerFinishContract() external onlyOwner {
         
        require(contractStarted);

         
        require(!contractFinished);

         
        contractFinished = true;
    }

     
    function ownerPauseContract() external onlyOwner {
         
        require(contractStarted);

         
        require(!contractFinished);

         
        require(!contractPaused);

         
        contractPaused = true;
    }

     
    function ownerResumeContract() external onlyOwner {
         
        require(contractPaused);

         
        contractPaused = false;
    }

     
    function ownerDeclareFailure() external onlyOwner {
         
        require(!contractFailed);

         
        contractFailed = true;
    }

     
    function ownerDeclareRefundStart() external onlyOwner {
         
        require(contractFailed);

         
        require(!contractRefundStarted);

         
        require(pendingFunding == 0x0);

         
        require(address(this).balance >= raisedFunding);

         
        contractRefundStarted = true;
    }

     
    function ownerDeclareRefundFinish() external onlyOwner {
         
        require(contractFailed);

         
        require(contractRefundStarted);

         
        require(!contractRefundFinished);

         
        contractRefundFinished = true;
    }

     
    function ownerWithdrawParsecs(uint256 value) external onlyOwner {
         
        require(contractFinished);

         
        uint256 parsecBalance = parsecToken.balanceOf(this);

         
        uint256 maxAmountToWithdraw = parsecBalance.sub(pendingParsecs);

         
        require(maxAmountToWithdraw > 0);
        require(maxAmountToWithdraw <= parsecBalance);

         
        require(value > 0);
        require(value <= maxAmountToWithdraw);

         
        parsecToken.transfer(owner, value);
    }
 
     
    function acceptKyc(address participant) external onlyOwnerOrAuditor {
         
        kycStatus[participant] = KycState.Accepted;

         
        uint256 pendingAmountOfEth = pendingContributionOf[participant];
        uint256 pendingAmountOfParsecs = pendingParsecsOf[participant];

         
        LogKycAccept(participant, pendingAmountOfEth, now);

        if (pendingAmountOfEth > 0 || pendingAmountOfParsecs > 0) {
             
            resetPendingContribution(participant);

             
            addAcceptedContribution(participant, pendingAmountOfEth, pendingAmountOfParsecs);
        }
    }

     
    function declineKyc(address participant) external onlyOwnerOrAuditor {
         
        kycStatus[participant] = KycState.Declined;

         
        LogKycDecline(participant, pendingAmountOfEth, now);

         
        uint256 pendingAmountOfEth = pendingContributionOf[participant];

        if (pendingAmountOfEth > 0) {
             
            resetPendingContribution(participant);

             
            participant.transfer(pendingAmountOfEth);
        }
    }

     
    function participantClawbackEther(uint256 value) external {
         
        require(contractRefundStarted);
        require(!contractRefundFinished);

         
        uint256 totalContribution = contributionOf[msg.sender];

         
        uint256 alreadyRefunded = refundOf[msg.sender];

         
        uint256 maxWithdrawalAmount = totalContribution.sub(alreadyRefunded);

         
        require(maxWithdrawalAmount > 0);

         
        require(value > 0);
        require(value <= maxWithdrawalAmount);

         
        refundOf[msg.sender] = alreadyRefunded.add(value);

         
        refundedFunding = refundedFunding.add(value);

         
        msg.sender.transfer(value);
    }

     
    function addPendingContribution(address participant, uint256 ethValue, uint256 parsecValue) private {
         
        pendingContributionOf[participant] = pendingContributionOf[participant].add(ethValue);

         
        pendingParsecsOf[participant] = pendingParsecsOf[participant].add(parsecValue);

         
        pendingFunding = pendingFunding.add(ethValue);

         
        pendingParsecs = pendingParsecs.add(parsecValue);
    }

     
    function addAcceptedContribution(address participant, uint256 ethValue, uint256 parsecValue) private {
         
        contributionOf[participant] = contributionOf[participant].add(ethValue);

         
        parsecsOf[participant] = parsecsOf[participant].add(parsecValue);

         
        raisedFunding = raisedFunding.add(ethValue);

         
        spentParsecs = spentParsecs.add(parsecValue);

         
        LogContribution(participant, ethValue, parsecValue, now);

         
        multisigAddress.transfer(ethValue);

         
        parsecToken.transfer(participant, parsecValue);
    }

     
    function resetPendingContribution(address participant) private {
         
        uint256 pendingAmountOfEth = pendingContributionOf[participant];
        uint256 pendingAmountOfParsecs = pendingParsecsOf[participant];

         
        pendingContributionOf[participant] = pendingContributionOf[participant].sub(pendingAmountOfEth);

         
        pendingParsecsOf[participant] = pendingParsecsOf[participant].sub(pendingAmountOfParsecs);

         
        pendingFunding = pendingFunding.sub(pendingAmountOfEth);

         
        pendingParsecs = pendingParsecs.sub(pendingAmountOfParsecs);
    }

     
    function calculateReward(uint256 ethValue) private view returns (uint256 amount) {
         
        uint256 baseQuotient = 1000;

         
        uint256 actualQuotient = baseQuotient.add(calculateBonusTierQuotient());

         
        uint256 reward = ethValue.mul(PARSECS_PER_ETHER_BASE);
        reward = reward.mul(actualQuotient);
        reward = reward.div(baseQuotient);
        return reward.div(1 ether);
    }

     
    function calculateBonusTierQuotient() private view returns (uint256 quotient) {
        uint256 funding = raisedFunding.add(pendingFunding);

        if (funding < BONUS_TIER_1_LIMIT) {
            return 300;      
        } else if (funding < BONUS_TIER_2_LIMIT) {
            return 275;      
        } else if (funding < BONUS_TIER_3_LIMIT) {
            return 250;      
        } else if (funding < BONUS_TIER_4_LIMIT) {
            return 225;      
        } else if (funding < BONUS_TIER_5_LIMIT) {
            return 200;      
        } else if (funding < BONUS_TIER_6_LIMIT) {
            return 175;      
        } else if (funding < BONUS_TIER_7_LIMIT) {
            return 150;      
        } else if (funding < BONUS_TIER_8_LIMIT) {
            return 100;      
        } else if (funding < BONUS_TIER_9_LIMIT) {
            return 50;       
        } else {
            return 0;        
        }
    }
}