 

pragma solidity ^0.4.15;


contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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



contract AbstractPaymentEscrow is Ownable {

    address public wallet;

    mapping (uint => uint) public deposits;

    event Payment(address indexed _customer, uint indexed _projectId, uint value);
    event Withdraw(address indexed _wallet, uint value);

    function withdrawFunds() public;

     
    function changeWallet(address _wallet)
        public
        onlyOwner()
    {
        wallet = _wallet;
    }

     
    function getDeposit(uint _projectId)
        public
        constant
        returns (uint)
    {
        return deposits[_projectId];
    }
}




contract TokitRegistry is Ownable {

    struct ProjectContracts {
        address token;
        address fund;
        address campaign;
    }

     
    mapping (address => bool) public registrars;

     
    mapping (address => mapping(uint => ProjectContracts)) public registry;
     
    mapping (uint => ProjectContracts) public project_registry;

    event RegisteredToken(address indexed _projectOwner, uint indexed _projectId, address _token, address _fund);
    event RegisteredCampaign(address indexed _projectOwner, uint indexed _projectId, address _campaign);

    modifier onlyRegistrars() {
        require(registrars[msg.sender]);
        _;
    }

    function TokitRegistry(address _owner) {
        setRegistrar(_owner, true);
        transferOwnership(_owner);
    }

    function register(address _customer, uint _projectId, address _token, address _fund)
        onlyRegistrars()
    {
        registry[_customer][_projectId].token = _token;
        registry[_customer][_projectId].fund = _fund;

        project_registry[_projectId].token = _token;
        project_registry[_projectId].fund = _fund;

        RegisteredToken(_customer, _projectId, _token, _fund);
    }

    function register(address _customer, uint _projectId, address _campaign)
        onlyRegistrars()
    {
        registry[_customer][_projectId].campaign = _campaign;

        project_registry[_projectId].campaign = _campaign;

        RegisteredCampaign(_customer, _projectId, _campaign);
    }

    function lookup(address _customer, uint _projectId)
        constant
        returns (address token, address fund, address campaign)
    {
        return (
            registry[_customer][_projectId].token,
            registry[_customer][_projectId].fund,
            registry[_customer][_projectId].campaign
        );
    }

    function lookupByProject(uint _projectId)
        constant
        returns (address token, address fund, address campaign)
    {
        return (
            project_registry[_projectId].token,
            project_registry[_projectId].fund,
            project_registry[_projectId].campaign
        );
    }

    function setRegistrar(address _registrar, bool enabled)
        onlyOwner()
    {
        registrars[_registrar] = enabled;
    }
}





 
 
 
contract SingularDTVFund {
    string public version = "0.1.0";

     
    AbstractSingularDTVToken public singularDTVToken;

     
    address public owner;
    uint public totalReward;

     
    mapping (address => uint) public rewardAtTimeOfWithdraw;

     
    mapping (address => uint) public owed;

    modifier onlyOwner() {
         
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

     
     
    function depositReward()
        public
        payable
        returns (bool)
    {
        totalReward += msg.value;
        return true;
    }

     
     
    function calcReward(address forAddress) private returns (uint) {
        return singularDTVToken.balanceOf(forAddress) * (totalReward - rewardAtTimeOfWithdraw[forAddress]) / singularDTVToken.totalSupply();
    }

     
    function withdrawReward()
        public
        returns (uint)
    {
        uint value = calcReward(msg.sender) + owed[msg.sender];
        rewardAtTimeOfWithdraw[msg.sender] = totalReward;
        owed[msg.sender] = 0;
        if (value > 0 && !msg.sender.send(value)) {
            revert();
        }
        return value;
    }

     
     
    function softWithdrawRewardFor(address forAddress)
        external
        returns (uint)
    {
        uint value = calcReward(forAddress);
        rewardAtTimeOfWithdraw[forAddress] = totalReward;
        owed[forAddress] += value;
        return value;
    }

     
     
    function setup(address singularDTVTokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        if (address(singularDTVToken) == 0) {
            singularDTVToken = AbstractSingularDTVToken(singularDTVTokenAddress);
            return true;
        }
        return false;
    }

     
    function SingularDTVFund() {
         
        owner = msg.sender;
    }

     
    function ()
        public
        payable
    {
        if (msg.value == 0) {
            withdrawReward();
        } else {
            depositReward();
        }
    }
}







contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract AbstractSingularDTVFund {
    function softWithdrawRewardFor(address forAddress) returns (uint);
}

 
 
 
contract SingularDTVToken is StandardToken {
    string public version = "0.1.0";

     
    AbstractSingularDTVFund public singularDTVFund;

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

     
     
     
    function transfer(address to, uint256 value)
        returns (bool)
    {
         
        singularDTVFund.softWithdrawRewardFor(msg.sender);
        singularDTVFund.softWithdrawRewardFor(to);
        return super.transfer(to, value);
    }

     
     
     
     
    function transferFrom(address from, address to, uint256 value)
        returns (bool)
    {
         
        singularDTVFund.softWithdrawRewardFor(from);
        singularDTVFund.softWithdrawRewardFor(to);
        return super.transferFrom(from, to, value);
    }

    function SingularDTVToken(address sDTVFundAddr, address _wallet, string _name, string _symbol, uint _totalSupply) {
        if(sDTVFundAddr == 0 || _wallet == 0) {
             
            revert();
        }

        balances[_wallet] = _totalSupply;
        totalSupply = _totalSupply;

        name = _name;
        symbol = _symbol;

        singularDTVFund = AbstractSingularDTVFund(sDTVFundAddr);

        Transfer(this, _wallet, _totalSupply);
    }
}








contract AbstractSingularDTVToken is Token {

}


 
 
 
 
contract SingularDTVLaunch {
    string public version = "0.1.0";

    event Contributed(address indexed contributor, uint contribution, uint tokens);

     
    AbstractSingularDTVToken public singularDTVToken;
    address public workshop;
    address public SingularDTVWorkshop = 0xc78310231aA53bD3D0FEA2F8c705C67730929D8f;
    uint public SingularDTVWorkshopFee;

     
    uint public CAP;  
    uint public DURATION;  
    uint public TOKEN_TARGET;  

     
    enum Stages {
        Deployed,
        GoingAndGoalNotReached,
        EndedAndGoalNotReached,
        GoingAndGoalReached,
        EndedAndGoalReached
    }

     
    address public owner;
    uint public startDate;
    uint public fundBalance;
    uint public valuePerToken;  
    uint public tokensSent;

     
    mapping (address => uint) public contributions;

     
    mapping (address => uint) public sentTokens;

     
    Stages public stage = Stages.Deployed;

    modifier onlyOwner() {
         
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            revert();
        }
        _;
    }

    modifier atStageOR(Stages _stage1, Stages _stage2) {
        if (stage != _stage1 && stage != _stage2) {
            revert();
        }
        _;
    }

    modifier timedTransitions() {
        uint timeElapsed = now - startDate;

        if (timeElapsed >= DURATION) {
            if (stage == Stages.GoingAndGoalNotReached) {
                stage = Stages.EndedAndGoalNotReached;
            } else if (stage == Stages.GoingAndGoalReached) {
                stage = Stages.EndedAndGoalReached;
            }
        }
        _;
    }

     
     
    function checkInvariants() constant internal {
        if (fundBalance > this.balance) {
            revert();
        }
    }

     
    function emergencyCall()
        public
        returns (bool)
    {
        if (fundBalance > this.balance) {
            if (this.balance > 0 && !SingularDTVWorkshop.send(this.balance)) {
                revert();
            }
            return true;
        }
        return false;
    }

     
    function fund()
        public
        timedTransitions
        atStageOR(Stages.GoingAndGoalNotReached, Stages.GoingAndGoalReached)
        payable
        returns (uint)
    {
        uint tokenCount = (msg.value * (10**18)) / valuePerToken;  
        require(tokenCount > 0);
        if (tokensSent + tokenCount > CAP) {
             
            tokenCount = CAP - tokensSent;
        }
        tokensSent += tokenCount;

        uint contribution = (tokenCount * valuePerToken) / (10**18);  
         
        if (msg.value > contribution && !msg.sender.send(msg.value - contribution)) {
            revert();
        }
         
        fundBalance += contribution;
        contributions[msg.sender] += contribution;
        sentTokens[msg.sender] += tokenCount;
        if (!singularDTVToken.transfer(msg.sender, tokenCount)) {
             
            revert();
        }
         
        if (stage == Stages.GoingAndGoalNotReached) {
            if (tokensSent >= TOKEN_TARGET) {
                stage = Stages.GoingAndGoalReached;
            }
        }
         
        if (stage == Stages.GoingAndGoalReached) {
            if (tokensSent == CAP) {
                stage = Stages.EndedAndGoalReached;
            }
        }
        checkInvariants();

        Contributed(msg.sender, contribution, tokenCount);

        return tokenCount;
    }

     
    function withdrawContribution()
        public
        timedTransitions
        atStage(Stages.EndedAndGoalNotReached)
        returns (uint)
    {
         
        uint tokensReceived = sentTokens[msg.sender];
        sentTokens[msg.sender] = 0;
        if (!singularDTVToken.transferFrom(msg.sender, owner, tokensReceived)) {
            revert();
        }

         
        uint contribution = contributions[msg.sender];
        contributions[msg.sender] = 0;
        fundBalance -= contribution;
         
        if (contribution > 0) {
            msg.sender.transfer(contribution);
        }
        checkInvariants();
        return contribution;
    }

     
    function withdrawForWorkshop()
        public
        timedTransitions
        atStage(Stages.EndedAndGoalReached)
        returns (bool)
    {
        uint value = fundBalance;
        fundBalance = 0;

        require(value > 0);

        uint networkFee = value * SingularDTVWorkshopFee / 100;
        workshop.transfer(value - networkFee);
        SingularDTVWorkshop.transfer(networkFee);

        uint remainingTokens = CAP - tokensSent;
        if (remainingTokens > 0 && !singularDTVToken.transfer(owner, remainingTokens)) {
            revert();
        }

        checkInvariants();
        return true;
    }

     
    function withdrawUnsentTokensForOwner()
        public
        timedTransitions
        atStage(Stages.EndedAndGoalNotReached)
        returns (uint)
    {
        uint remainingTokens = CAP - tokensSent;
        if (remainingTokens > 0 && !singularDTVToken.transfer(owner, remainingTokens)) {
            revert();
        }

        checkInvariants();
        return remainingTokens;
    }

     
     
    function changeValuePerToken(uint valueInWei)
        public
        onlyOwner
        atStage(Stages.Deployed)
        returns (bool)
    {
        valuePerToken = valueInWei;
        return true;
    }

     
     
     
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    function start()
        public
        onlyOwner
        atStage(Stages.Deployed)
        returns (uint)
    {
        if (!singularDTVToken.transferFrom(msg.sender, this, CAP)) {
            revert();
        }

        startDate = now;
        stage = Stages.GoingAndGoalNotReached;

        checkInvariants();
        return startDate;
    }

     
    function SingularDTVLaunch(
        address singularDTVTokenAddress,
        address _workshop,
        address _owner,
        uint _total,
        uint _unit_price,
        uint _duration,
        uint _threshold,
        uint _singulardtvwoskhop_fee
        ) {
        singularDTVToken = AbstractSingularDTVToken(singularDTVTokenAddress);
        workshop = _workshop;
        owner = _owner;
        CAP = _total;  
        valuePerToken = _unit_price;  
        DURATION = _duration;  
        TOKEN_TARGET = _threshold;  
        SingularDTVWorkshopFee = _singulardtvwoskhop_fee;
    }

     
     
     
    function ()
        public
        payable
    {
        if (stage == Stages.GoingAndGoalNotReached || stage == Stages.GoingAndGoalReached)
            fund();
        else if (stage == Stages.EndedAndGoalNotReached)
            withdrawContribution();
        else
            revert();
    }
}







contract TokitDeployer is Ownable {

    TokitRegistry public registry;

     
    mapping (uint8 => AbstractPaymentEscrow) public paymentContracts;

    event DeployedToken(address indexed _customer, uint indexed _projectId, address _token, address _fund);
    event DeployedCampaign(address indexed _customer, uint indexed _projectId, address _campaign);


    function TokitDeployer(address _owner, address _registry) {
        transferOwnership(_owner);
        registry = TokitRegistry(_registry);
    }

    function deployToken(
        address _customer, uint _projectId, uint8 _payedWith, uint _amountNeeded,
         
        address _wallet, string _name, string _symbol, uint _totalSupply
    )
        onlyOwner()
    {
         
        require(AbstractPaymentEscrow(paymentContracts[_payedWith]).getDeposit(_projectId) >= _amountNeeded);

        var (t,,) = registry.lookup(_customer, _projectId);
         
        require(t == address(0));


        SingularDTVFund fund = new SingularDTVFund();
        SingularDTVToken token = new SingularDTVToken(fund, _wallet, _name, _symbol, _totalSupply);
        fund.setup(token);

        registry.register(_customer, _projectId, token, fund);

        DeployedToken(_customer, _projectId, token, fund);
    }

    function deployCampaign(
        address _customer, uint _projectId,
         
        address _workshop, uint _total, uint _unitPrice, uint _duration, uint _threshold, uint _networkFee
    )
        onlyOwner()
    {
        var (t,f,c) = registry.lookup(_customer, _projectId);
         
        require(c == address(0));

         
        require(t != address(0) && f != address(0));

        SingularDTVLaunch campaign = new SingularDTVLaunch(t, _workshop, _customer, _total, _unitPrice, _duration, _threshold, _networkFee);

        registry.register(_customer, _projectId, campaign);

        DeployedCampaign(_customer, _projectId, campaign);
    }

    function setRegistryContract(address _registry)
        onlyOwner()
    {
        registry = TokitRegistry(_registry);
    }

    function setPaymentContract(uint8 _paymentType, address _paymentContract)
        onlyOwner()
    {
        paymentContracts[_paymentType] = AbstractPaymentEscrow(_paymentContract);
    }

    function deletePaymentContract(uint8 _paymentType)
        onlyOwner()
    {
        delete paymentContracts[_paymentType];
    }
}