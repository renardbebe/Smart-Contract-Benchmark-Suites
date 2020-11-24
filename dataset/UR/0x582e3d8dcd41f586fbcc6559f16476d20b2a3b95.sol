 

contract Token { 
    function issue(address _recipient, uint256 _value) returns (bool success) {} 
    function totalSupply() constant returns (uint256 supply) {}
    function unlock() returns (bool success) {}
}

contract SCLCrowdsale {

     
    address public beneficiary;  
    address public creator;  
    address public confirmedBy;  
    uint256 public minAmount = 294 ether;  
    uint256 public maxAmount = 100000 ether;  
    uint256 public maxSupply = 50000000 * 10**8;  
    uint256 public minAcceptedAmount = 40 finney;  

     
    uint256 public ratePreICO = 850;
    uint256 public rateWaiting = 0;
    uint256 public rateAngelDay = 750;
    uint256 public rateFirstWeek = 700;
    uint256 public rateSecondWeek = 650;
    uint256 public rateThirdWeek = 600;
    uint256 public rateLastWeek = 550;

    uint256 public ratePreICOEnd = 10 days;
    uint256 public rateWaitingEnd = 20 days;
    uint256 public rateAngelDayEnd = 21 days;
    uint256 public rateFirstWeekEnd = 28 days;
    uint256 public rateSecondWeekEnd = 35 days;
    uint256 public rateThirdWeekEnd = 42 days;
    uint256 public rateLastWeekEnd = 49 days;

    enum Stages {
        InProgress,
        Ended,
        Withdrawn
    }

    Stages public stage = Stages.InProgress;

     
    uint256 public start;
    uint256 public end;
    uint256 public raised;

     
    Token public sclToken;

     
    mapping (address => uint256) balances;


     
    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            throw;
        }
        _;
    }
    

     
    modifier onlyBeneficiary() {
        if (beneficiary != msg.sender) {
            throw;
        }
        _;
    }


     
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }


     
    function SCLCrowdsale(address _tokenAddress, address _beneficiary, address _creator, uint256 _start) {
        sclToken = Token(_tokenAddress);
        beneficiary = _beneficiary;
        creator = _creator;
        start = _start;
        end = start + rateLastWeekEnd;
    }


     
    function confirmBeneficiary() onlyBeneficiary {
        confirmedBy = msg.sender;
    }


     
    function toSCL(uint256 _wei) returns (uint256 amount) {
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

         
        if (now < end) {
            throw;
        }

        stage = Stages.Ended;
    }


     
    function withdraw() onlyBeneficiary atStage(Stages.Ended) {

         
        if (raised < minAmount) {
            throw;
        }

        if (!sclToken.unlock()) {
            throw;
        }

        uint256 ethBalance = this.balance;

         
        uint256 ethFees = ethBalance * 5 / 10**2;
        if (!creator.send(ethFees)) {
            throw;
        }

         
        if (!beneficiary.send(ethBalance - ethFees)) {
            throw;
        }

        stage = Stages.Withdrawn;
    }


     
    function refund() atStage(Stages.Ended) {

         
        if (raised >= minAmount) {
            throw;
        }

        uint256 receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }

    
     
    function () payable atStage(Stages.InProgress) {

         
        if (now < start) {
            throw;
        }

         
        if (now > end) {
            throw;
        }

         
        if (msg.value < minAcceptedAmount) {
            throw;
        }
 
        uint256 received = msg.value;
        uint256 valueInSCL = toSCL(msg.value);

         
        if (valueInSCL == 0) {
            throw;
        }

        if (!sclToken.issue(msg.sender, valueInSCL)) {
            throw;
        }

         
        uint256 sclFees = valueInSCL * 5 / 10**2;

         
        if (!sclToken.issue(creator, sclFees)) {
            throw;
        }

        if (now <= start + ratePreICOEnd) {

             
            uint256 ethFees = received * 5 / 10**2;

             
            if (!creator.send(ethFees)) {
                throw;
            }

             
            if (!beneficiary.send(received - ethFees)) {
                throw;
            }

        } else {

             
            balances[msg.sender] += received;  
        }

        raised += received;

         
        if (raised >= maxAmount || sclToken.totalSupply() >= maxSupply) {
            stage = Stages.Ended;
        }
    }
}