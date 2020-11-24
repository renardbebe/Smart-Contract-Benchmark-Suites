 

 

pragma solidity ^0.4.23;

 
interface PermissionInterface{
     

     
    function isPermitted(bytes32 _value) external view returns (bool allowed);
}

 
contract Arbitrator{

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {require(msg.value>=arbitrationCost(_extraData)); _;}
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {require(msg.value>=appealCost(_disputeID, _extraData)); _;}

     
    event AppealPossible(uint _disputeID);

     
    event DisputeCreation(uint indexed _disputeID, Arbitrable _arbitrable);

     
    event AppealDecision(uint indexed _disputeID, Arbitrable _arbitrable);

     
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID)  {}

     
    function arbitrationCost(bytes _extraData) public constant returns(uint fee);

     
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

     
    function appealCost(uint _disputeID, bytes _extraData) public constant returns(uint fee);

     
    function disputeStatus(uint _disputeID) public constant returns(DisputeStatus status);

     
    function currentRuling(uint _disputeID) public constant returns(uint ruling);

}

 
contract Arbitrable{
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData;  

    modifier onlyArbitrator {require(msg.sender==address(arbitrator)); _;}

     
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

     
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

     
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID);

     
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _disputeID, address _party, string _evidence);

     
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

 
contract ArbitrablePermissionList is PermissionInterface, Arbitrable {
     

    enum ItemStatus {
        Absent,  
        Cleared,  
        Resubmitted,  
        Registered,  
        Submitted,  
        ClearingRequested,  
        PreventiveClearingRequested  
    }

     

    struct Item {
        ItemStatus status;  
        uint lastAction;  
        address submitter;  
        address challenger;  
        uint balance;  
        bool disputed;  
        uint disputeID;  
    }

     

     
    event ItemStatusChange(
        address indexed submitter,
        address indexed challenger,
        bytes32 indexed value,
        ItemStatus status,
        bool disputed
    );

     

     
    bool public blacklist;  
    bool public appendOnly;  
    bool public rechallengePossible;  
    uint public stake;  
    uint public timeToChallenge;  

     
    uint8 constant REGISTER = 1;
    uint8 constant CLEAR = 2;

     
    mapping(bytes32 => Item) public items;
    mapping(uint => bytes32) public disputeIDToItem;
    bytes32[] public itemsList;

     

     
    constructor(
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        string _metaEvidence,
        bool _blacklist,
        bool _appendOnly,
        bool _rechallengePossible,
        uint _stake,
        uint _timeToChallenge) Arbitrable(_arbitrator, _arbitratorExtraData) public {
        emit MetaEvidence(0, _metaEvidence);
        blacklist = _blacklist;
        appendOnly = _appendOnly;
        rechallengePossible = _rechallengePossible;
        stake = _stake;
        timeToChallenge = _timeToChallenge;
    }

     

     
    function requestRegistration(bytes32 _value) public payable {
        Item storage item = items[_value];
        uint arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= stake + arbitratorCost);

        if (item.status == ItemStatus.Absent)
            item.status = ItemStatus.Submitted;
        else if (item.status == ItemStatus.Cleared)
            item.status = ItemStatus.Resubmitted;
        else
            revert();  

        if (item.lastAction == 0) {
            itemsList.push(_value);
        }

        item.submitter = msg.sender;
        item.balance += msg.value;
        item.lastAction = now;

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

     
    function requestClearing(bytes32 _value) public payable {
        Item storage item = items[_value];
        uint arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(!appendOnly);
        require(msg.value >= stake + arbitratorCost);

        if (item.status == ItemStatus.Registered)
            item.status = ItemStatus.ClearingRequested;
        else if (item.status == ItemStatus.Absent)
            item.status = ItemStatus.PreventiveClearingRequested;
        else
            revert();  
        
        if (item.lastAction == 0) {
            itemsList.push(_value);
        }

        item.submitter = msg.sender;
        item.balance += msg.value;
        item.lastAction = now;

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

     
    function challengeRegistration(bytes32 _value) public payable {
        Item storage item = items[_value];
        uint arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= stake + arbitratorCost);
        require(item.status == ItemStatus.Resubmitted || item.status == ItemStatus.Submitted);
        require(!item.disputed);

        if (item.balance >= arbitratorCost) {  
            item.challenger = msg.sender;
            item.balance += msg.value-arbitratorCost;
            item.disputed = true;
            item.disputeID = arbitrator.createDispute.value(arbitratorCost)(2,arbitratorExtraData);
            disputeIDToItem[item.disputeID] = _value;
            emit Dispute(arbitrator, item.disputeID, 0);
        } else {  
            if (item.status == ItemStatus.Resubmitted)
                item.status = ItemStatus.Cleared;
            else
                item.status = ItemStatus.Absent;

            item.submitter.send(item.balance);  
            item.balance = 0;
            msg.sender.transfer(msg.value);
        }

        item.lastAction = now;

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

     
    function challengeClearing(bytes32 _value) public payable {
        Item storage item = items[_value];
        uint arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= stake + arbitratorCost);
        require(item.status == ItemStatus.ClearingRequested || item.status == ItemStatus.PreventiveClearingRequested);
        require(!item.disputed);

        if (item.balance >= arbitratorCost) {  
            item.challenger = msg.sender;
            item.balance += msg.value-arbitratorCost;
            item.disputed = true;
            item.disputeID = arbitrator.createDispute.value(arbitratorCost)(2,arbitratorExtraData);
            disputeIDToItem[item.disputeID] = _value;
            emit Dispute(arbitrator, item.disputeID, 0);
        } else {  
            if (item.status == ItemStatus.ClearingRequested)
                item.status = ItemStatus.Registered;
            else
                item.status = ItemStatus.Absent;

            item.submitter.send(item.balance);  
            item.balance = 0;
            msg.sender.transfer(msg.value);
        }

        item.lastAction = now;

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

     
    function appeal(bytes32 _value) public payable {
        Item storage item = items[_value];
        arbitrator.appeal.value(msg.value)(item.disputeID,arbitratorExtraData);  
    }

     
    function executeRequest(bytes32 _value) public {
        Item storage item = items[_value];
        require(now - item.lastAction >= timeToChallenge);
        require(!item.disputed);

        if (item.status == ItemStatus.Resubmitted || item.status == ItemStatus.Submitted)
            item.status = ItemStatus.Registered;
        else if (item.status == ItemStatus.ClearingRequested || item.status == ItemStatus.PreventiveClearingRequested)
            item.status = ItemStatus.Cleared;
        else
            revert();

        item.submitter.send(item.balance);  

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

     

     
    function isPermitted(bytes32 _value) public view returns (bool allowed) {
        Item storage item = items[_value];
        bool _excluded = item.status <= ItemStatus.Resubmitted ||
            (item.status == ItemStatus.PreventiveClearingRequested && !item.disputed);
        return blacklist ? _excluded : !_excluded;  
    }

     

     
    function executeRuling(uint _disputeID, uint _ruling) internal {
        Item storage item = items[disputeIDToItem[_disputeID]];
        require(item.disputed);

        if (_ruling == REGISTER) {
            if (rechallengePossible && item.status==ItemStatus.Submitted) {
                uint arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
                if (arbitratorCost + stake < item.balance) {  
                    uint toSend = item.balance - (arbitratorCost + stake);
                    item.submitter.send(toSend);  
                    item.balance -= toSend;
                }
            } else {
                if (item.status==ItemStatus.Resubmitted || item.status==ItemStatus.Submitted)
                    item.submitter.send(item.balance);  
                else
                    item.challenger.send(item.balance);
                    
                item.status = ItemStatus.Registered;
            }
        } else if (_ruling == CLEAR) {
            if (item.status == ItemStatus.PreventiveClearingRequested || item.status == ItemStatus.ClearingRequested)
                item.submitter.send(item.balance);
            else
                item.challenger.send(item.balance);

            item.status = ItemStatus.Cleared;
        } else {  
            if (item.status==ItemStatus.Resubmitted)
                item.status = ItemStatus.Cleared;
            else if (item.status==ItemStatus.ClearingRequested)
                item.status = ItemStatus.Registered;
            else
                item.status = ItemStatus.Absent;
            item.submitter.send(item.balance / 2);
            item.challenger.send(item.balance / 2);
        }
        
        item.disputed = false;
        if (rechallengePossible && item.status==ItemStatus.Submitted && _ruling==REGISTER) 
            item.lastAction=now;  
        else
            item.balance = 0;

        emit ItemStatusChange(item.submitter, item.challenger, disputeIDToItem[_disputeID], item.status, item.disputed);
    }

     

     
    function itemsCount() public view returns (uint count) {
        count = itemsList.length;
    }

     
    function itemsCounts() public view returns (uint pending, uint challenged, uint accepted, uint rejected) {
        for (uint i = 0; i < itemsList.length; i++) {
            Item storage item = items[itemsList[i]];
            if (item.disputed) challenged++;
            else if (item.status == ItemStatus.Resubmitted || item.status == ItemStatus.Submitted) pending++;
            else if (item.status == ItemStatus.Registered) accepted++;
            else if (item.status == ItemStatus.Cleared) rejected++;
        }
    }

     
    function queryItems(bytes32 _cursor, uint _count, bool[6] _filter, bool _sort) public view returns (bytes32[] values, bool hasMore) {
        uint _cursorIndex;
        values = new bytes32[](_count);
        uint _index = 0;

        if (_cursor == 0)
            _cursorIndex = 0;
        else {
            for (uint j = 0; j < itemsList.length; j++) {
                if (itemsList[j] == _cursor) {
                    _cursorIndex = j;
                    break;
                }
            }
            require(_cursorIndex != 0);
        }

        for (
                uint i = _cursorIndex == 0 ? (_sort ? 0 : 1) : (_sort ? _cursorIndex + 1 : itemsList.length - _cursorIndex + 1);
                _sort ? i < itemsList.length : i <= itemsList.length;
                i++
            ) {  
            Item storage item = items[itemsList[_sort ? i : itemsList.length - i]];
            if (
                item.status != ItemStatus.Absent && item.status != ItemStatus.PreventiveClearingRequested && (
                    (_filter[0] && (item.status == ItemStatus.Resubmitted || item.status == ItemStatus.Submitted)) ||  
                    (_filter[1] && item.disputed) ||  
                    (_filter[2] && item.status == ItemStatus.Registered) ||  
                    (_filter[3] && item.status == ItemStatus.Cleared) ||  
                    (_filter[4] && item.submitter == msg.sender) ||  
                    (_filter[5] && item.challenger == msg.sender)  
                )
            ) {
                if (_index < _count) {
                    values[_index] = itemsList[_sort ? i : itemsList.length - i];
                    _index++;
                } else {
                    hasMore = true;
                    break;
                }
            }
        }
    }
}