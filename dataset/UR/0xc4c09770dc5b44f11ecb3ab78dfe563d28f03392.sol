 

pragma solidity 0.4.18;


contract EngravedToken {
    uint256 public totalSupply;
    function issue(address, uint256) public returns (bool) {}
    function balanceOf(address) public constant returns (uint256) {}
    function unlock() public returns (bool) {}
    function startIncentiveDistribution() public returns (bool) {}
    function transferOwnership(address) public {}
    function owner() public returns (address) {}
}


contract EGRCrowdsale {
     
    address public beneficiary;
    address public confirmedBy;  

     
    uint256 public maxSupply = 1000000000;  

     
    uint256 public minAcceptedAmount = 10 finney;  

     
    uint256 public rateAirDrop = 1000;

     
    uint256 public airdropParticipants;

     
    uint256 public maxAirdropParticipants = 500;

     
    mapping (address => bool) public participatedInAirdrop;

     
    uint256 public rateAngelsDay = 100000;
    uint256 public rateFirstWeek = 80000;
    uint256 public rateSecondWeek = 70000;
    uint256 public rateThirdWeek = 60000;
    uint256 public rateLastWeek = 50000;

    uint256 public airdropEnd = 3 days;
    uint256 public airdropCooldownEnd = 7 days;
    uint256 public rateAngelsDayEnd = 8 days;
    uint256 public angelsDayCooldownEnd = 14 days;
    uint256 public rateFirstWeekEnd = 21 days;
    uint256 public rateSecondWeekEnd = 28 days;
    uint256 public rateThirdWeekEnd = 35 days;
    uint256 public rateLastWeekEnd = 42 days;

    enum Stages {
        Airdrop,
        InProgress,
        Ended,
        Withdrawn,
        Proposed,
        Accepted
    }

    Stages public stage = Stages.Airdrop;

     
    uint256 public start;
    uint256 public end;
    uint256 public raised;

     
    EngravedToken public engravedToken;

     
    mapping (address => uint256) internal balances;

    struct Proposal {
        address engravedAddress;
        uint256 deadline;
        uint256 approvedWeight;
        uint256 disapprovedWeight;
        mapping (address => uint256) voted;
    }

     
    Proposal public transferProposal;

     
    uint256 public transferProposalEnd = 7 days;

     
    uint256 public transferProposalCooldown = 1 days;

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

     
    modifier atStages(Stages _stage1, Stages _stage2) {
        require(stage == _stage1 || stage == _stage2);
        _;
    }

     
    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender);
        _;
    }

     
    modifier onlyTokenholders() {
        require(engravedToken.balanceOf(msg.sender) > 0);
        _;
    }

     
    modifier beforeDeadline() {
        require(now < transferProposal.deadline);
        _;
    }

     
    modifier afterDeadline() {
        require(now > transferProposal.deadline);
        _;
    }

     
    function EGRCrowdsale(address _engravedTokenAddress, address _beneficiary, uint256 _start) public {
        engravedToken = EngravedToken(_engravedTokenAddress);
        beneficiary = _beneficiary;
        start = _start;
        end = start + 42 days;
    }

     
    function() public payable atStage(Stages.InProgress) {
         
         
        require(now > start && now < end && msg.value >= minAcceptedAmount);

        uint256 valueInEGR = toEGR(msg.value);

        require((engravedToken.totalSupply() + valueInEGR) <= (maxSupply * 10**3));
        require(engravedToken.issue(msg.sender, valueInEGR));

        uint256 received = msg.value;
        balances[msg.sender] += received;
        raised += received;
    }

     
    function balanceOf(address _investor) public view returns (uint256 balance) {
        return balances[_investor];
    }

     
    function confirmBeneficiary() public onlyBeneficiary {
        confirmedBy = msg.sender;
    }

     
    function toEGR(uint256 _wei) public view returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended && now >= start && now <= end) {
             
            if (now <= start + airdropCooldownEnd) {
                rate = 0;
             
            } else if (now <= start + rateAngelsDayEnd) {
                rate = rateAngelsDay;
             
            } else if (now <= start + angelsDayCooldownEnd) {
                rate = 0;
             
            } else if (now <= start + rateFirstWeekEnd) {
                rate = rateFirstWeek;
             
            } else if (now <= start + rateSecondWeekEnd) {
                rate = rateSecondWeek;
             
            } else if (now <= start + rateThirdWeekEnd) {
                rate = rateThirdWeek;
             
            } else if (now <= start + rateLastWeekEnd) {
                rate = rateLastWeek;
            }
        }
        require(rate != 0);  
        return _wei * rate * 10**3 / 1 ether;  
    }

     
    function claim() public atStage(Stages.Airdrop) {
         
         
        require(airdropParticipants < maxAirdropParticipants
            && now > start && now < start + airdropEnd
            && participatedInAirdrop[msg.sender] == false);

        require(engravedToken.issue(msg.sender, rateAirDrop * 10**3));

        participatedInAirdrop[msg.sender] = true;
        airdropParticipants += 1;
    }

     
    function endAirdrop() public atStage(Stages.Airdrop) {
        require(now > start + airdropEnd);
        stage = Stages.InProgress;
    }

     
    function endCrowdsale() public atStage(Stages.InProgress) {
         
        require(now > end);
        stage = Stages.Ended;
    }

     
    function withdraw() public onlyBeneficiary atStage(Stages.Ended) {
        require(beneficiary.send(raised));
        stage = Stages.Withdrawn;
    }

     
    function withdrawCustom(uint256 amount, address addressee) public onlyBeneficiary atStage(Stages.Ended) {
        require(addressee.send(amount));
        raised = raised - amount;
        if (raised == 0) {
            stage = Stages.Withdrawn;
        }
    }

     
    function moveStageWithdrawn() public onlyBeneficiary atStage(Stages.Ended) {
        stage = Stages.Withdrawn;
    }

     
    function proposeTransfer(address _engravedAddress) public onlyBeneficiary
    atStages(Stages.Withdrawn, Stages.Proposed) {
         
        require(stage != Stages.Proposed || now > transferProposal.deadline + transferProposalCooldown);

        transferProposal = Proposal({
            engravedAddress: _engravedAddress,
            deadline: now + transferProposalEnd,
            approvedWeight: 0,
            disapprovedWeight: 0
        });

        stage = Stages.Proposed;
    }

     
    function vote(bool _approve) public onlyTokenholders beforeDeadline atStage(Stages.Proposed) {
         
        require(transferProposal.voted[msg.sender] < transferProposal.deadline - transferProposalEnd);

        transferProposal.voted[msg.sender] = now;
        uint256 weight = engravedToken.balanceOf(msg.sender);

        if (_approve) {
            transferProposal.approvedWeight += weight;
        } else {
            transferProposal.disapprovedWeight += weight;
        }
    }

     
    function executeTransfer() public afterDeadline atStage(Stages.Proposed) {
         
        require(transferProposal.approvedWeight > transferProposal.disapprovedWeight);
        require(engravedToken.unlock());
        require(engravedToken.startIncentiveDistribution());

        engravedToken.transferOwnership(transferProposal.engravedAddress);

        require(engravedToken.owner() == transferProposal.engravedAddress);

        stage = Stages.Accepted;
    }

}