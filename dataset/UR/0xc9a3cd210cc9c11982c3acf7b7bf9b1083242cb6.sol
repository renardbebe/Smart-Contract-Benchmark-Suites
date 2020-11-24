 

 

 

pragma solidity ^0.5;


 
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

     
    function addCap(uint _a, uint _b) internal pure returns (uint) {
        uint c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

     
    function subCap(uint _a, uint _b) internal pure returns (uint) {
        if (_b > _a)
            return 0;
        else
            return _a - _b;
    }

     
    function mulCap(uint _a, uint _b) internal pure returns (uint) {
         
         
         
        if (_a == 0)
            return 0;

        uint c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}

 

pragma solidity ^0.5;


 
interface IEvidence {

     
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

     
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

     
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

}

 

 

pragma solidity ^0.5;


 
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}


     
    event DisputeCreation(uint indexed _disputeID, IArbitrable indexed _arbitrable);

     
    event AppealPossible(uint indexed _disputeID, IArbitrable indexed _arbitrable);

     
    event AppealDecision(uint indexed _disputeID, IArbitrable indexed _arbitrable);

     
    function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID);

     
    function arbitrationCost(bytes memory _extraData) public view returns(uint cost);

     
    function appeal(uint _disputeID, bytes memory _extraData) public payable;

     
    function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint cost);

     
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end);

     
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

     
    function currentRuling(uint _disputeID) public view returns(uint ruling);

}

 

 

pragma solidity ^0.5;


 
interface IArbitrable {

     
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

     
    function rule(uint _disputeID, uint _ruling) external;
}

 


pragma solidity >=0.5 <0.6.0;





 
contract BinaryArbitrableProxy is IArbitrable, IEvidence {

    using CappedMath for uint;

    uint constant NUMBER_OF_CHOICES = 2;
    enum Party {RefuseToArbitrate, Requester, Respondent}
    uint8 requester = uint8(Party.Requester);
    uint8 respondent = uint8(Party.Respondent);

    struct Round {
      uint[3] paidFees;  
      bool[3] hasPaid;  
      uint totalAppealFeesCollected;  
      mapping(address => uint[3]) contributions;  
    }

    struct DisputeStruct {
        Arbitrator arbitrator;
        bytes arbitratorExtraData;
        bool isRuled;
        Party judgment;
        uint disputeIDOnArbitratorSide;
        Round[] rounds;
    }

    DisputeStruct[] public disputes;
    mapping(address => mapping(uint => uint)) public arbitratorExternalIDtoLocalID;


     
    function createDispute(Arbitrator _arbitrator, bytes calldata _arbitratorExtraData, string calldata _metaevidenceURI) external payable {
        uint arbitrationCost = _arbitrator.arbitrationCost(_arbitratorExtraData);
        require(msg.value >= arbitrationCost, "Insufficient message value.");
        uint disputeID = _arbitrator.createDispute.value(arbitrationCost)(NUMBER_OF_CHOICES, _arbitratorExtraData);

        uint localDisputeID = disputes.length++;
        DisputeStruct storage dispute = disputes[localDisputeID];
        dispute.arbitrator = _arbitrator;
        dispute.arbitratorExtraData = _arbitratorExtraData;
        dispute.disputeIDOnArbitratorSide = disputeID;
        dispute.rounds.length++;

        arbitratorExternalIDtoLocalID[address(_arbitrator)][disputeID] = localDisputeID;

        emit MetaEvidence(localDisputeID, _metaevidenceURI);
        emit Dispute(_arbitrator, disputeID, localDisputeID, localDisputeID);

        msg.sender.send(msg.value-arbitrationCost);
    }

     
    function appeal(uint _localDisputeID, Party _party) external payable {
        require(_party != Party.RefuseToArbitrate, "You can't fund an appeal in favor of refusing to arbitrate.");
        uint8 side = uint8(_party);
        DisputeStruct storage dispute = disputes[_localDisputeID];

        (uint appealPeriodStart, uint appealPeriodEnd) = dispute.arbitrator.appealPeriod(dispute.disputeIDOnArbitratorSide);
        require(now >= appealPeriodStart && now < appealPeriodEnd, "Funding must be made within the appeal period.");

        Round storage round = dispute.rounds[dispute.rounds.length-1];

        require(!round.hasPaid[side], "Appeal fee has already been paid");
        round.hasPaid[side] = true;  

        uint appealCost = dispute.arbitrator.appealCost(dispute.disputeIDOnArbitratorSide, dispute.arbitratorExtraData);

        uint contribution;

        if(round.paidFees[side] + msg.value >= appealCost){
          contribution = appealCost - round.paidFees[side];
        }
        else{
            contribution = msg.value;
            round.hasPaid[side] = false;  
        }
        msg.sender.send(msg.value - contribution);
        round.contributions[msg.sender][side] += contribution;
        round.paidFees[side] += contribution;
        round.totalAppealFeesCollected += contribution;

        if(round.hasPaid[requester] && round.hasPaid[respondent]){
            dispute.arbitrator.appeal.value(appealCost)(dispute.disputeIDOnArbitratorSide, dispute.arbitratorExtraData);
            dispute.rounds.length++;
            round.totalAppealFeesCollected = round.totalAppealFeesCollected.subCap(appealCost);
        }
    }

     
    function withdrawFeesAndRewards(uint _localDisputeID, address payable _contributor, uint _roundNumber) external {
        DisputeStruct storage dispute = disputes[_localDisputeID];
        Round storage round = dispute.rounds[_roundNumber];
        uint8 judgment = uint8(dispute.judgment);

        require(dispute.isRuled, "The dispute should be solved");
        uint reward;
        if (!round.hasPaid[requester] || !round.hasPaid[respondent]) {
             
            reward = round.contributions[_contributor][requester] + round.contributions[_contributor][respondent];
            round.contributions[_contributor][requester] = 0;
            round.contributions[_contributor][respondent] = 0;
        } else if (judgment == 0) {
             
            uint rewardParty1 = round.paidFees[requester] > 0
                ? (round.contributions[_contributor][requester] * round.totalAppealFeesCollected) / (round.paidFees[requester] + round.paidFees[respondent])
                : 0;
            uint rewardParty2 = round.paidFees[respondent] > 0
                ? (round.contributions[_contributor][respondent] * round.totalAppealFeesCollected) / (round.paidFees[requester] + round.paidFees[respondent])
                : 0;

            reward = rewardParty1 + rewardParty2;
            round.contributions[_contributor][requester] = 0;
            round.contributions[_contributor][respondent] = 0;
        } else {
               
            reward = round.paidFees[judgment] > 0
                ? (round.contributions[_contributor][judgment] * round.totalAppealFeesCollected) / round.paidFees[judgment]
                : 0;
            round.contributions[_contributor][judgment] = 0;
          }

        _contributor.send(reward);  
    }

     
    function rule(uint _externalDisputeID, uint _ruling) external {
        uint _localDisputeID = arbitratorExternalIDtoLocalID[msg.sender][_externalDisputeID];
        DisputeStruct storage dispute = disputes[_localDisputeID];
        require(msg.sender == address(dispute.arbitrator), "Unauthorized call.");
        require(_ruling <= NUMBER_OF_CHOICES, "Invalid ruling.");
        require(dispute.isRuled == false, "Is ruled already.");

        dispute.isRuled = true;
        dispute.judgment = Party(_ruling);

        Round storage round = dispute.rounds[dispute.rounds.length-1];

        uint resultRuling = _ruling;
        if (round.hasPaid[requester] == true)  
            resultRuling = 1;
        else if (round.hasPaid[respondent] == true)
            resultRuling = 2;

        emit Ruling(Arbitrator(msg.sender), dispute.disputeIDOnArbitratorSide, resultRuling);
    }

     
    function submitEvidence(uint _localDisputeID, string memory _evidenceURI) public {
        DisputeStruct storage dispute = disputes[_localDisputeID];

        require(dispute.isRuled == false, "Cannot submit evidence to a resolved dispute.");

        emit Evidence(dispute.arbitrator, _localDisputeID, msg.sender, _evidenceURI);
    }
    
    function crowdfundingStatus(uint _localDisputeID) external view returns (uint[3] memory, bool[3] memory, uint, uint[3] memory){
    DisputeStruct storage dispute = disputes[_localDisputeID];

    Round memory lastRound = dispute.rounds[dispute.rounds.length - 1];

    return (lastRound.paidFees, lastRound.hasPaid, lastRound.totalAppealFeesCollected, dispute.rounds[dispute.rounds.length - 1].contributions[msg.sender]);
    
    }
}