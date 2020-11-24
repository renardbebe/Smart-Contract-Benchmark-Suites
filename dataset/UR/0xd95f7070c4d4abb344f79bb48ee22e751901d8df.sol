 

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