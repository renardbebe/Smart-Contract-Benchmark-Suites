 

pragma solidity ^0.4.15;

contract IToken { 
    function issue(address _recipient, uint256 _value) returns (bool);
    function totalSupply() constant returns (uint256);
    function unlock() returns (bool);
}

contract CoinoorCrowdsale {

     
    address public beneficiary;  
    address public creator;  
    address public marketing;  
    address public bounty;  
    address public confirmedBy;  
    uint256 public maxSupply = 65000000 * 10**8;  
    uint256 public minAcceptedAmount = 40 finney;  

     
    uint256 public ratePreICO = 450;  
    uint256 public rateWaiting = 0;
    uint256 public rateAngelDay = 420;  
    uint256 public rateFirstWeek = 390;  
    uint256 public rateSecondWeek = 375;  
    uint256 public rateThirdWeek = 360;  
    uint256 public rateLastWeek = 330;  

    uint256 public ratePreICOEnd = 10 days;
    uint256 public rateWaitingEnd = 20 days;
    uint256 public rateAngelDayEnd = 21 days;
    uint256 public rateFirstWeekEnd = 28 days;
    uint256 public rateSecondWeekEnd = 35 days;
    uint256 public rateThirdWeekEnd = 42 days;
    uint256 public rateLastWeekEnd = 49 days;

    enum Stages {
        Deploying,
        InProgress,
        Ended
    }

    Stages public stage = Stages.Deploying;

     
    uint256 public start;
    uint256 public end;
    uint256 public raised;

     
    IToken public token;


     
    modifier atStage(Stages _stage) {
        require(stage == _stage);

        _;
    }
    

     
    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender);

        _;
    }


     
    function CoinoorCrowdsale(address _tokenAddress, address _beneficiary, address _creator, address _marketing, address _bounty, uint256 _start) {
        token = IToken(_tokenAddress);
        beneficiary = _beneficiary;
        creator = _creator;
        marketing = _marketing;
        bounty = _bounty;
        start = _start;
        end = start + rateLastWeekEnd;
    }


     
    function init() atStage(Stages.Deploying) {
        stage = Stages.InProgress;

         
        if (!token.issue(beneficiary, 4900000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }

        if (!token.issue(creator, 2500000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }

        if (!token.issue(marketing, 2500000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }

        if (!token.issue(bounty, 100000 * 10**8)) {
            stage = Stages.Deploying;
            revert();
        }
    }


     
    function confirmBeneficiary() onlyBeneficiary {
        confirmedBy = msg.sender;
    }


     
    function toTokens(uint256 _wei) returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended && now >= start && now <= end) {

             
            if (now <= start + ratePreICOEnd) {
                rate = ratePreICO;
            }

             
            else if (now <= start + rateWaitingEnd) {
                rate = rateWaiting;
            }

             
            else if (now <= start + rateAngelDayEnd) {
                rate = rateAngelDay;
            }

             
            else if (now <= start + rateFirstWeekEnd) {
                rate = rateFirstWeek;
            }

             
            else if (now <= start + rateSecondWeekEnd) {
                rate = rateSecondWeek;
            }

             
            else if (now <= start + rateThirdWeekEnd) {
                rate = rateThirdWeek;
            }

             
            else if (now <= start + rateLastWeekEnd) {
                rate = rateLastWeek;
            }
        }

        return _wei * rate * 10**8 / 1 ether;  
    }


     
    function endCrowdsale() atStage(Stages.InProgress) {
        require(now > end);

        stage = Stages.Ended;
        if (!token.unlock()) {
            stage = Stages.InProgress;
        }
    }


     
    function withdraw() onlyBeneficiary atStage(Stages.Ended) {
        beneficiary.transfer(this.balance);
    }

    
     
    function () payable atStage(Stages.InProgress) {

         
        require(now >= start);

         
        require(now <= end);

         
        require(msg.value >= minAcceptedAmount);
 
        address sender = msg.sender;
        uint256 received = msg.value;
        uint256 valueInTokens = toTokens(received);

         
        require(valueInTokens > 0);

         
        raised += received;

         
        if (token.totalSupply() + valueInTokens >= maxSupply) {
            stage = Stages.Ended;
        }

         
        if (!token.issue(sender, valueInTokens)) {
            revert();
        }

         
        if (!beneficiary.send(received)) {
            revert();
        }
    }
}