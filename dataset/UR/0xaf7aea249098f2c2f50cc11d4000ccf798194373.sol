 

pragma solidity ^0.4.15;

 

contract Token { 
    function issue(address _recipient, uint256 _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function owner() returns (address _owner);
}

contract ZTCrowdsale {

     
    address public beneficiary;  
    address public creator;  
    address public confirmedBy;  
    uint256 public minAmount = 20000 ether; 
    uint256 public maxAmount = 400000 ether; 
    uint256 public minAcceptedAmount = 40 finney;  

     
    uint256 public ratePreICO = 290;
    uint256 public rateAngelDay = 275;
    uint256 public rateFirstWeek = 250;
    uint256 public rateSecondWeek = 198;
    uint256 public rateThirdWeek = 157;
    uint256 public rateLastWeek = 125;

    uint256 public ratePreICOEnd = 10 days;
    uint256 public rateAngelDayEnd = 11 days;
    uint256 public rateFirstWeekEnd = 18 days;
    uint256 public rateSecondWeekEnd = 25 days;
    uint256 public rateThirdWeekEnd = 32 days;
    uint256 public rateLastWeekEnd = 39 days;

    enum Stages {
        InProgress,
        Ended,
        Withdrawn
    }

    Stages public stage = Stages.InProgress;

     
    uint256 public start;
    uint256 public end;
    uint256 public raised;

     
    Token public ztToken;

     
    mapping (address => uint256) balances;


     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }


     
    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender);
        _;
    }


     
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }


     
    function ZTCrowdsale(address _tokenAddress, address _beneficiary, address _creator, uint256 _start) {
        ztToken = Token(_tokenAddress);
        beneficiary = _beneficiary;
        creator = _creator;
        start = _start;
        end = start + rateLastWeekEnd;
    }


     
    function confirmBeneficiary() onlyBeneficiary {
        confirmedBy = msg.sender;
    }


     
    function toZT(uint256 _wei) returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended && now >= start && now <= end) {

             
            if (now <= start + ratePreICOEnd) {
                rate = ratePreICO;
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

        uint256 ztAmount = _wei * rate * 10**8 / 1 ether;  

         
        if (raised > minAmount) {
            uint256 multiplier = raised / minAmount;  
            for (uint256 i = 0; i < multiplier; i++) {
                ztAmount = ztAmount * 965936329 / 10**9;
            }
        }

        return ztAmount;
    }


     
    function endCrowdsale() atStage(Stages.InProgress) {

         
        require(now >= end);

        stage = Stages.Ended;
    }


     
    function withdraw() atStage(Stages.Ended) {

         
        require(raised >= minAmount);

        uint256 ethBalance = this.balance;
        uint256 ethFees = ethBalance * 5 / 10**3;  
        creator.transfer(ethFees);
        beneficiary.transfer(ethBalance - ethFees);

        stage = Stages.Withdrawn;
    }


     
    function refund() atStage(Stages.Ended) {

         
        require(raised < minAmount);

        uint256 receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }

    
     
    function () payable atStage(Stages.InProgress) {

         
        require(now > start);

         
        require(now < end);

         
        require(msg.value >= minAcceptedAmount);
        
        address sender = msg.sender;
        uint256 received = msg.value;
        uint256 valueInZT = toZT(msg.value);
        if (!ztToken.issue(sender, valueInZT)) {
            revert();
        }

        if (now <= start + ratePreICOEnd) {

             
            uint256 ethFees = received * 5 / 10**3;  

             
            if (!creator.send(ethFees)) {
                revert();
            }

             
            if (!beneficiary.send(received - ethFees)) {
                revert();
            }

        } else {

             
            balances[sender] += received;  
        }

        raised += received;

         
        if (raised >= maxAmount) {
            stage = Stages.Ended;
        }
    }
}