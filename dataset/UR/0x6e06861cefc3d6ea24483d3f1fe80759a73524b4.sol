 

 
 
pragma solidity 0.4.25;


 
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

 
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

     
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

     
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

     
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

     
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

     
    function arbitrationCost(bytes _extraData) public view returns(uint fee);

     
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

     
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee);

     
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

     
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

     
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}

 
interface IArbitrable {
     
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

     
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

     
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

     
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

     
    function rule(uint _disputeID, uint _ruling) public;
}

 
contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData;  

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

     
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

     
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


     
    function executeRuling(uint _disputeID, uint _ruling) internal;
}

 
interface PermissionInterface{
     

     
    function isPermitted(bytes32 _value) external view returns (bool allowed);
}

 
contract ArbitrableAddressList is PermissionInterface, Arbitrable {
    using CappedMath for uint;  

     

    enum AddressStatus {
        Absent,  
        Registered,  
        RegistrationRequested,  
        ClearingRequested  
    }

    enum Party {
        None,       
        Requester,  
        Challenger  
    }

     
     
     
     
     
     
     
     
     
     
     

     

    struct Address {
        AddressStatus status;  
        Request[] requests;  
    }

     
     
     
     
    struct Request {
        bool disputed;  
        uint disputeID;  
        uint submissionTime;  
        bool resolved;  
        address[3] parties;  
        Round[] rounds;  
        Party ruling;  
        Arbitrator arbitrator;  
        bytes arbitratorExtraData;  
    }

    struct Round {
        uint[3] paidFees;  
        bool[3] hasPaid;  
        uint feeRewards;  
        mapping(address => uint[3]) contributions;  
    }

     

     

    uint RULING_OPTIONS = 2;  

     
    address public governor;  
    uint public requesterBaseDeposit;  
    uint public challengerBaseDeposit;  
    uint public challengePeriodDuration;  
    uint public metaEvidenceUpdates;  

     
     
    uint public winnerStakeMultiplier;  
    uint public loserStakeMultiplier;  
    uint public sharedStakeMultiplier;  
    uint public constant MULTIPLIER_DIVISOR = 10000;  

     
    mapping(address => Address) public addresses;  
    mapping(address => mapping(uint => address)) public arbitratorDisputeIDToAddress;  
    address[] public addressList;  

     

    modifier onlyGovernor {require(msg.sender == governor, "The caller must be the governor."); _;}

     

     
    event AddressSubmitted(address indexed _address, address indexed _requester);

     
    event RequestSubmitted(address indexed _address, bool _registrationRequest);

     
    event AddressStatusChange(
        address indexed _requester,
        address indexed _challenger,
        address indexed _address,
        AddressStatus _status,
        bool _disputed,
        bool _appealed
    );

     
    event RewardWithdrawal(address indexed _address, address indexed _contributor, uint indexed _request, uint _round, uint _value);


     

     
    constructor(
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        string _registrationMetaEvidence,
        string _clearingMetaEvidence,
        address _governor,
        uint _requesterBaseDeposit,
        uint _challengerBaseDeposit,
        uint _challengePeriodDuration,
        uint _sharedStakeMultiplier,
        uint _winnerStakeMultiplier,
        uint _loserStakeMultiplier
    ) Arbitrable(_arbitrator, _arbitratorExtraData) public {
        emit MetaEvidence(0, _registrationMetaEvidence);
        emit MetaEvidence(1, _clearingMetaEvidence);

        governor = _governor;
        requesterBaseDeposit = _requesterBaseDeposit;
        challengerBaseDeposit = _challengerBaseDeposit;
        challengePeriodDuration = _challengePeriodDuration;
        sharedStakeMultiplier = _sharedStakeMultiplier;
        winnerStakeMultiplier = _winnerStakeMultiplier;
        loserStakeMultiplier = _loserStakeMultiplier;
    }


     

     
     
     

     
    function requestStatusChange(address _address)
        external
        payable
    {
        Address storage addr = addresses[_address];
        if (addr.requests.length == 0) {
             
            addressList.push(_address);
            emit AddressSubmitted(_address, msg.sender);
        }

         
        if (addr.status == AddressStatus.Absent)
            addr.status = AddressStatus.RegistrationRequested;
        else if (addr.status == AddressStatus.Registered)
            addr.status = AddressStatus.ClearingRequested;
        else
            revert("Address already has a pending request.");

         
        Request storage request = addr.requests[addr.requests.length++];
        request.parties[uint(Party.Requester)] = msg.sender;
        request.submissionTime = now;
        request.arbitrator = arbitrator;
        request.arbitratorExtraData = arbitratorExtraData;
        Round storage round = request.rounds[request.rounds.length++];

        emit RequestSubmitted(_address, addr.status == AddressStatus.RegistrationRequested);

         
        uint arbitrationCost = request.arbitrator.arbitrationCost(request.arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap((arbitrationCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_DIVISOR).addCap(requesterBaseDeposit);
        contribute(round, Party.Requester, msg.sender, msg.value, totalCost);
        require(round.paidFees[uint(Party.Requester)] >= totalCost, "You must fully fund your side.");
        round.hasPaid[uint(Party.Requester)] = true;

        emit AddressStatusChange(
            request.parties[uint(Party.Requester)],
            address(0x0),
            _address,
            addr.status,
            false,
            false
        );
    }

     
    function challengeRequest(address _address, string _evidence) external payable {
        Address storage addr = addresses[_address];
        require(
            addr.status == AddressStatus.RegistrationRequested || addr.status == AddressStatus.ClearingRequested,
            "The address must have a pending request."
        );
        Request storage request = addr.requests[addr.requests.length - 1];
        require(now - request.submissionTime <= challengePeriodDuration, "Challenges must occur during the challenge period.");
        require(!request.disputed, "The request should not have already been disputed.");

         
        request.parties[uint(Party.Challenger)] = msg.sender;

        Round storage round = request.rounds[request.rounds.length - 1];
        uint arbitrationCost = request.arbitrator.arbitrationCost(request.arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap((arbitrationCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_DIVISOR).addCap(challengerBaseDeposit);
        contribute(round, Party.Challenger, msg.sender, msg.value, totalCost);
        require(round.paidFees[uint(Party.Challenger)] >= totalCost, "You must fully fund your side.");
        round.hasPaid[uint(Party.Challenger)] = true;

         
        request.disputeID = request.arbitrator.createDispute.value(arbitrationCost)(RULING_OPTIONS, request.arbitratorExtraData);
        arbitratorDisputeIDToAddress[request.arbitrator][request.disputeID] = _address;
        request.disputed = true;
        request.rounds.length++;
        round.feeRewards = round.feeRewards.subCap(arbitrationCost);

        emit Dispute(
            request.arbitrator,
            request.disputeID,
            addr.status == AddressStatus.RegistrationRequested
                ? 2 * metaEvidenceUpdates
                : 2 * metaEvidenceUpdates + 1,
            uint(keccak256(abi.encodePacked(_address,addr.requests.length - 1)))
        );
        emit AddressStatusChange(
            request.parties[uint(Party.Requester)],
            request.parties[uint(Party.Challenger)],
            _address,
            addr.status,
            true,
            false
        );
        if (bytes(_evidence).length > 0)
            emit Evidence(request.arbitrator, uint(keccak256(abi.encodePacked(_address,addr.requests.length - 1))), msg.sender, _evidence);
    }

     
    function fundAppeal(address _address, Party _side) external payable {
         
        require(_side == Party.Requester || _side == Party.Challenger);  
        Address storage addr = addresses[_address];
        require(
            addr.status == AddressStatus.RegistrationRequested || addr.status == AddressStatus.ClearingRequested,
            "The address must have a pending request."
        );
        Request storage request = addr.requests[addr.requests.length - 1];
        require(request.disputed, "A dispute must have been raised to fund an appeal.");
        (uint appealPeriodStart, uint appealPeriodEnd) = request.arbitrator.appealPeriod(request.disputeID);
        require(
            now >= appealPeriodStart && now < appealPeriodEnd,
            "Contributions must be made within the appeal period."
        );


         
        Round storage round = request.rounds[request.rounds.length - 1];
        Party winner = Party(request.arbitrator.currentRuling(request.disputeID));
        Party loser;
        if (winner == Party.Requester)
            loser = Party.Challenger;
        else if (winner == Party.Challenger)
            loser = Party.Requester;
        require(!(_side==loser) || (now-appealPeriodStart < (appealPeriodEnd-appealPeriodStart)/2), "The loser must contribute during the first half of the appeal period.");

        uint multiplier;
        if (_side == winner)
            multiplier = winnerStakeMultiplier;
        else if (_side == loser)
            multiplier = loserStakeMultiplier;
        else
            multiplier = sharedStakeMultiplier;
        uint appealCost = request.arbitrator.appealCost(request.disputeID, request.arbitratorExtraData);
        uint totalCost = appealCost.addCap((appealCost.mulCap(multiplier)) / MULTIPLIER_DIVISOR);
        contribute(round, _side, msg.sender, msg.value, totalCost);
        if (round.paidFees[uint(_side)] >= totalCost)
            round.hasPaid[uint(_side)] = true;

         
        if (round.hasPaid[uint(Party.Challenger)] && round.hasPaid[uint(Party.Requester)]) {
            request.arbitrator.appeal.value(appealCost)(request.disputeID, request.arbitratorExtraData);
            request.rounds.length++;
            round.feeRewards = round.feeRewards.subCap(appealCost);
            emit AddressStatusChange(
                request.parties[uint(Party.Requester)],
                request.parties[uint(Party.Challenger)],
                _address,
                addr.status,
                true,
                true
            );
        }
    }

     
    function withdrawFeesAndRewards(address _beneficiary, address _address, uint _request, uint _round) public {
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[_request];
        Round storage round = request.rounds[_round];
         
        require(request.resolved);  

        uint reward;
        if (!request.disputed || request.ruling == Party.None) {
             
            uint rewardRequester = round.paidFees[uint(Party.Requester)] > 0
                ? (round.contributions[_beneficiary][uint(Party.Requester)] * round.feeRewards) / (round.paidFees[uint(Party.Challenger)] + round.paidFees[uint(Party.Requester)])
                : 0;
            uint rewardChallenger = round.paidFees[uint(Party.Challenger)] > 0
                ? (round.contributions[_beneficiary][uint(Party.Challenger)] * round.feeRewards) / (round.paidFees[uint(Party.Challenger)] + round.paidFees[uint(Party.Requester)])
                : 0;

            reward = rewardRequester + rewardChallenger;
            round.contributions[_beneficiary][uint(Party.Requester)] = 0;
            round.contributions[_beneficiary][uint(Party.Challenger)] = 0;
        } else {
             
            reward = round.paidFees[uint(request.ruling)] > 0
                ? (round.contributions[_beneficiary][uint(request.ruling)] * round.feeRewards) / round.paidFees[uint(request.ruling)]
                : 0;

            round.contributions[_beneficiary][uint(request.ruling)] = 0;
        }

        emit RewardWithdrawal(_address, _beneficiary, _request, _round,  reward);
        _beneficiary.send(reward);  
    }

     
    function batchRoundWithdraw(address _beneficiary, address _address, uint _request, uint _cursor, uint _count) public {
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[_request];
        for (uint i = _cursor; i<request.rounds.length && (_count==0 || i<_count); i++)
            withdrawFeesAndRewards(_beneficiary, _address, _request, i);
    }

     
    function batchRequestWithdraw(
        address _beneficiary,
        address _address,
        uint _cursor,
        uint _count,
        uint _roundCursor,
        uint _roundCount
    ) external {
        Address storage addr = addresses[_address];
        for (uint i = _cursor; i<addr.requests.length && (_count==0 || i<_count); i++)
            batchRoundWithdraw(_beneficiary, _address, i, _roundCursor, _roundCount);
    }

     
    function executeRequest(address _address) external {
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[addr.requests.length - 1];
        require(
            now - request.submissionTime > challengePeriodDuration,
            "Time to challenge the request must have passed."
        );
        require(!request.disputed, "The request should not be disputed.");

        if (addr.status == AddressStatus.RegistrationRequested)
            addr.status = AddressStatus.Registered;
        else if (addr.status == AddressStatus.ClearingRequested)
            addr.status = AddressStatus.Absent;
        else
            revert("There must be a request.");

        request.resolved = true;
        withdrawFeesAndRewards(request.parties[uint(Party.Requester)], _address, addr.requests.length - 1, 0);  

        emit AddressStatusChange(
            request.parties[uint(Party.Requester)],
            address(0x0),
            _address,
            addr.status,
            false,
            false
        );
    }

     
    function rule(uint _disputeID, uint _ruling) public {
        Party resultRuling = Party(_ruling);
        address _address = arbitratorDisputeIDToAddress[msg.sender][_disputeID];
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[addr.requests.length - 1];
        Round storage round = request.rounds[request.rounds.length - 1];
        require(_ruling <= RULING_OPTIONS);  
        require(request.arbitrator == msg.sender);  
        require(!request.resolved);  

         
        if (round.hasPaid[uint(Party.Requester)] == true)  
            resultRuling = Party.Requester;
        else if (round.hasPaid[uint(Party.Challenger)] == true)
            resultRuling = Party.Challenger;

        emit Ruling(Arbitrator(msg.sender), _disputeID, uint(resultRuling));
        executeRuling(_disputeID, uint(resultRuling));
    }

     
    function submitEvidence(address _address, string _evidence) external {
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[addr.requests.length - 1];
        require(!request.resolved, "The dispute must not already be resolved.");

        emit Evidence(request.arbitrator, uint(keccak256(abi.encodePacked(_address,addr.requests.length - 1))), msg.sender, _evidence);
    }

     
     
     

     
    function changeTimeToChallenge(uint _challengePeriodDuration) external onlyGovernor {
        challengePeriodDuration = _challengePeriodDuration;
    }

     
    function changeRequesterBaseDeposit(uint _requesterBaseDeposit) external onlyGovernor {
        requesterBaseDeposit = _requesterBaseDeposit;
    }

     
    function changeChallengerBaseDeposit(uint _challengerBaseDeposit) external onlyGovernor {
        challengerBaseDeposit = _challengerBaseDeposit;
    }

     
    function changeGovernor(address _governor) external onlyGovernor {
        governor = _governor;
    }

     
    function changeSharedStakeMultiplier(uint _sharedStakeMultiplier) external onlyGovernor {
        sharedStakeMultiplier = _sharedStakeMultiplier;
    }

     
    function changeWinnerStakeMultiplier(uint _winnerStakeMultiplier) external onlyGovernor {
        winnerStakeMultiplier = _winnerStakeMultiplier;
    }

     
    function changeLoserStakeMultiplier(uint _loserStakeMultiplier) external onlyGovernor {
        loserStakeMultiplier = _loserStakeMultiplier;
    }

     
    function changeArbitrator(Arbitrator _arbitrator, bytes _arbitratorExtraData) external onlyGovernor {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

     
    function changeMetaEvidence(string _registrationMetaEvidence, string _clearingMetaEvidence) external onlyGovernor {
        metaEvidenceUpdates++;
        emit MetaEvidence(2 * metaEvidenceUpdates, _registrationMetaEvidence);
        emit MetaEvidence(2 * metaEvidenceUpdates + 1, _clearingMetaEvidence);
    }


     

     
    function calculateContribution(uint _available, uint _requiredAmount)
        internal
        pure
        returns(uint taken, uint remainder)
    {
        if (_requiredAmount > _available)
            return (_available, 0);  

        remainder = _available - _requiredAmount;
        return (_requiredAmount, remainder);
    }

     
    function contribute(Round storage _round, Party _side, address _contributor, uint _amount, uint _totalRequired) internal {
         
        uint contribution;  
        uint remainingETH;  
        (contribution, remainingETH) = calculateContribution(_amount, _totalRequired.subCap(_round.paidFees[uint(_side)]));
        _round.contributions[_contributor][uint(_side)] += contribution;
        _round.paidFees[uint(_side)] += contribution;
        _round.feeRewards += contribution;

         
        _contributor.send(remainingETH);  
    }

     
    function executeRuling(uint _disputeID, uint _ruling) internal {
        address _address = arbitratorDisputeIDToAddress[msg.sender][_disputeID];
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[addr.requests.length - 1];

        Party winner = Party(_ruling);

         
        if (winner == Party.Requester) {  
            if (addr.status == AddressStatus.RegistrationRequested)
                addr.status = AddressStatus.Registered;
            else
                addr.status = AddressStatus.Absent;
        } else {  
            if (addr.status == AddressStatus.RegistrationRequested)
                addr.status = AddressStatus.Absent;
            else if (addr.status == AddressStatus.ClearingRequested)
                addr.status = AddressStatus.Registered;
        }

        request.resolved = true;
        request.ruling = Party(_ruling);
         
        if (winner == Party.None) {
            withdrawFeesAndRewards(request.parties[uint(Party.Requester)], _address, addr.requests.length-1, 0);
            withdrawFeesAndRewards(request.parties[uint(Party.Challenger)], _address, addr.requests.length-1, 0);
        } else {
            withdrawFeesAndRewards(request.parties[uint(winner)], _address, addr.requests.length-1, 0);
        }

        emit AddressStatusChange(
            request.parties[uint(Party.Requester)],
            request.parties[uint(Party.Challenger)],
            _address,
            addr.status,
            request.disputed,
            false
        );
    }


     

     
    function isPermitted(bytes32 _address) external view returns (bool allowed) {
        Address storage addr = addresses[address(_address)];
        return addr.status == AddressStatus.Registered || addr.status == AddressStatus.ClearingRequested;
    }


     

     
    function amountWithdrawable(address _address, address _beneficiary, uint _request) external view returns (uint total){
        Request storage request = addresses[_address].requests[_request];
        if (!request.resolved) return total;

        for (uint i = 0; i < request.rounds.length; i++) {
            Round storage round = request.rounds[i];
            if (!request.disputed || request.ruling == Party.None) {
                uint rewardRequester = round.paidFees[uint(Party.Requester)] > 0
                    ? (round.contributions[_beneficiary][uint(Party.Requester)] * round.feeRewards) / (round.paidFees[uint(Party.Requester)] + round.paidFees[uint(Party.Challenger)])
                    : 0;
                uint rewardChallenger = round.paidFees[uint(Party.Challenger)] > 0
                    ? (round.contributions[_beneficiary][uint(Party.Challenger)] * round.feeRewards) / (round.paidFees[uint(Party.Requester)] + round.paidFees[uint(Party.Challenger)])
                    : 0;

                total += rewardRequester + rewardChallenger;
            } else {
                total += round.paidFees[uint(request.ruling)] > 0
                    ? (round.contributions[_beneficiary][uint(request.ruling)] * round.feeRewards) / round.paidFees[uint(request.ruling)]
                    : 0;
            }
        }

        return total;
    }

     
    function addressCount() external view returns (uint count) {
        return addressList.length;
    }

     
    function countByStatus()
        external
        view
        returns (
            uint absent,
            uint registered,
            uint registrationRequest,
            uint clearingRequest,
            uint challengedRegistrationRequest,
            uint challengedClearingRequest
        )
    {
        for (uint i = 0; i < addressList.length; i++) {
            Address storage addr = addresses[addressList[i]];
            Request storage request = addr.requests[addr.requests.length - 1];

            if (addr.status == AddressStatus.Absent) absent++;
            else if (addr.status == AddressStatus.Registered) registered++;
            else if (addr.status == AddressStatus.RegistrationRequested && !request.disputed) registrationRequest++;
            else if (addr.status == AddressStatus.ClearingRequested && !request.disputed) clearingRequest++;
            else if (addr.status == AddressStatus.RegistrationRequested && request.disputed) challengedRegistrationRequest++;
            else if (addr.status == AddressStatus.ClearingRequested && request.disputed) challengedClearingRequest++;
        }
    }

     
    function queryAddresses(address _cursor, uint _count, bool[8] _filter, bool _oldestFirst)
        external
        view
        returns (address[] values, bool hasMore)
    {
        uint cursorIndex;
        values = new address[](_count);
        uint index = 0;

        if (_cursor == 0)
            cursorIndex = 0;
        else {
            for (uint j = 0; j < addressList.length; j++) {
                if (addressList[j] == _cursor) {
                    cursorIndex = j;
                    break;
                }
            }
            require(cursorIndex != 0, "The cursor is invalid.");
        }

        for (
                uint i = cursorIndex == 0 ? (_oldestFirst ? 0 : 1) : (_oldestFirst ? cursorIndex + 1 : addressList.length - cursorIndex + 1);
                _oldestFirst ? i < addressList.length : i <= addressList.length;
                i++
            ) {  
            Address storage addr = addresses[addressList[_oldestFirst ? i : addressList.length - i]];
            Request storage request = addr.requests[addr.requests.length - 1];
            if (
                 
                (_filter[0] && addr.status == AddressStatus.Absent) ||
                (_filter[1] && addr.status == AddressStatus.Registered) ||
                (_filter[2] && addr.status == AddressStatus.RegistrationRequested && !request.disputed) ||
                (_filter[3] && addr.status == AddressStatus.ClearingRequested && !request.disputed) ||
                (_filter[4] && addr.status == AddressStatus.RegistrationRequested && request.disputed) ||
                (_filter[5] && addr.status == AddressStatus.ClearingRequested && request.disputed) ||
                (_filter[6] && request.parties[uint(Party.Requester)] == msg.sender) ||  
                (_filter[7] && request.parties[uint(Party.Challenger)] == msg.sender)  
                 
            ) {
                if (index < _count) {
                    values[index] = addressList[_oldestFirst ? i : addressList.length - i];
                    index++;
                } else {
                    hasMore = true;
                    break;
                }
            }
        }
    }

     
    function getContributions(
        address _address,
        uint _request,
        uint _round,
        address _contributor
    ) external view returns(uint[3] contributions) {
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[_request];
        Round storage round = request.rounds[_round];
        contributions = round.contributions[_contributor];
    }

     
    function getAddressInfo(address _address)
        external
        view
        returns (
            AddressStatus status,
            uint numberOfRequests
        )
    {
        Address storage addr = addresses[_address];
        return (
            addr.status,
            addr.requests.length
        );
    }

     
    function getRequestInfo(address _address, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address[3] parties,
            uint numberOfRounds,
            Party ruling,
            Arbitrator arbitrator,
            bytes arbitratorExtraData
        )
    {
        Request storage request = addresses[_address].requests[_request];
        return (
            request.disputed,
            request.disputeID,
            request.submissionTime,
            request.resolved,
            request.parties,
            request.rounds.length,
            request.ruling,
            request.arbitrator,
            request.arbitratorExtraData
        );
    }

     
    function getRoundInfo(address _address, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] paidFees,
            bool[3] hasPaid,
            uint feeRewards
        )
    {
        Address storage addr = addresses[_address];
        Request storage request = addr.requests[_request];
        Round storage round = request.rounds[_round];
        return (
            _round != (request.rounds.length-1),
            round.paidFees,
            round.hasPaid,
            round.feeRewards
        );
    }
}