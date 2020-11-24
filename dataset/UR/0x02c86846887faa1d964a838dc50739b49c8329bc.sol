 

         
 

pragma solidity ^0.4.25;


 
interface IArbitrable {
     
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

     
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

     
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

     
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

     
    function rule(uint _disputeID, uint _ruling) external;
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
        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(_disputeID,_ruling);
    }


     
    function executeRuling(uint _disputeID, uint _ruling) internal;
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


contract Recover is IArbitrable {

     
     
     

     
    uint8 constant AMOUNT_OF_CHOICES = 2;

     
    enum Status {NoDispute, WaitingFinder, WaitingOwner, DisputeCreated, Resolved}
     
    enum Party {Owner, Finder}
     
    enum RulingOptions {NoRuling, OwnerWins, FinderWins}

    struct Item {
        address owner;  
        uint rewardAmount;  
        address addressForEncryption;  
        string descriptionEncryptedLink;  
        uint[] claimIDs;  
        uint timeoutLocked;  
        uint ownerFee;  
        bool exists;  
    }

    struct Owner {
        string description;  
        bytes32[] itemIDs;  
    }

    struct Claim {
        bytes32 itemID;  
        address finder;  
        string descriptionLink;  
        uint amountLocked;  
        uint lastInteraction;  
        uint finderFee;  
        uint disputeID;  
        bool isAccepted;  
        Status status;  
    }

    mapping(address => Owner) public owners;  

    mapping(bytes32 => Item) public items;  

    mapping(uint => uint) public disputeIDtoClaimAcceptedID;  

    Claim[] public claims;  
    Arbitrator public arbitrator;  
    bytes public arbitratorExtraData;  
    uint public feeTimeout;  

     
     
     

     
    event HasToPayFee(uint indexed _claimID, Party _party);
    
     
    event Fund(uint indexed _claimID, Party _party, uint _amount);

     
    event ItemClaimed(bytes32 indexed _itemID, address indexed _finder, uint _claimID);

     
     
     
     

     
    constructor (
        Arbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        uint _feeTimeout
    ) public {
        arbitrator = Arbitrator(_arbitrator);
        arbitratorExtraData = _arbitratorExtraData;
        feeTimeout = _feeTimeout;
        claims.length++;  
    }

     
    function addItem(
        bytes32 _itemID,
        address _addressForEncryption,
        string _descriptionEncryptedLink,
        uint _rewardAmount,
        uint _timeoutLocked
    ) public payable {
        require(items[_itemID].exists == false, "The id must be not registered.");

         
        items[_itemID] = Item({
            owner: msg.sender,  
            rewardAmount: _rewardAmount,  
            addressForEncryption: _addressForEncryption,  
            descriptionEncryptedLink: _descriptionEncryptedLink,  
            claimIDs: new uint[](0),  
            timeoutLocked: _timeoutLocked,  
            ownerFee: 0,  
            exists: true  
        });

         
        owners[msg.sender].itemIDs.push(_itemID);
        
        _addressForEncryption.transfer(msg.value);  

         
        emit MetaEvidence(uint(_itemID), _descriptionEncryptedLink);
    }

     
    function changeDescription(string memory _description) public {
        owners[msg.sender].description = _description;
    }

     
    function changeAddressAndDescriptionEncrypted(
        bytes32 _itemID,
        address _addressForEncryption,
        string memory _descriptionEncryptedLink
    ) public {
        Item storage item = items[_itemID];

        require(msg.sender == item.owner, "Must be the owner of the item.");

        item.addressForEncryption = _addressForEncryption;
        item.descriptionEncryptedLink = _descriptionEncryptedLink;
    }

     
    function changeRewardAmount(bytes32 _itemID, uint _rewardAmount) public {
        Item storage item = items[_itemID];

        require(msg.sender == item.owner, "Must be the owner of the item.");

        item.rewardAmount = _rewardAmount;
    }

     
    function changeTimeoutLocked(bytes32 _itemID, uint _timeoutLocked) public {
        Item storage item = items[_itemID];

        require(msg.sender == item.owner, "Must be the owner of the item.");
        require(item.timeoutLocked < _timeoutLocked, "Must be higher than the actual locked time.");

        item.timeoutLocked = _timeoutLocked;
    }

     
    function claim (
        bytes32 _itemID,
        address _finder,
        string memory _descriptionLink
    ) public {
        Item storage item = items[_itemID];

        require(
            msg.sender == item.addressForEncryption,
            "Must be the same sender of the transaction than the address used to encrypt the message."
        );

        claims.push(Claim({
            itemID: _itemID,  
            finder: _finder,  
            descriptionLink: _descriptionLink,   
            amountLocked: 0,  
            lastInteraction: now,  
            finderFee: 0,  
            disputeID: 0,  
            isAccepted: false,  
            status: Status.NoDispute  
        }));

        uint claimID = claims.length - 1;
        item.claimIDs[item.claimIDs.length++] = claimID;  

        emit ItemClaimed(_itemID, _finder, claimID);
    }

     
    function acceptClaim(uint _claimID) payable public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(item.owner == msg.sender, "The sender of the transaction must be the owner of the item.");
        require(item.rewardAmount <= msg.value, "The ETH amount must be equal or higher than the reward");

        itemClaim.amountLocked += msg.value;  
        itemClaim.isAccepted = true;  
    }

     
    function pay(uint _claimID, uint _amount) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(item.owner == msg.sender, "The caller must be the owner of the item.");
        require(itemClaim.status == Status.NoDispute, "The transaction of the item can't be disputed.");
        require(
            _amount <= itemClaim.amountLocked,
            "The amount paid has to be less than or equal to the amount locked."
        );

        itemClaim.finder.transfer(_amount);  
        itemClaim.amountLocked -= _amount;  
        
        emit Fund(_claimID, Party.Owner, _amount);
    }

     
    function reimburse(uint _claimID, uint _amountReimbursed) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(itemClaim.finder == msg.sender, "The caller must be the finder of the item.");
        require(itemClaim.status == Status.NoDispute, "The transaction item can't be disputed.");
        require(
            _amountReimbursed <= itemClaim.amountLocked,
            "The amount paid has to be less than or equal to the amount locked."
        );

        item.owner.transfer(_amountReimbursed);  

        itemClaim.amountLocked -= _amountReimbursed;  
        
        emit Fund(_claimID, Party.Finder, _amountReimbursed);
    }

     
    function executeTransaction(uint _claimID) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(now - itemClaim.lastInteraction >= item.timeoutLocked, "The timeout has not passed yet.");
        require(itemClaim.status == Status.NoDispute, "The transaction of the claim item can't be disputed.");

        itemClaim.finder.transfer(itemClaim.amountLocked);

        itemClaim.amountLocked = 0;
        itemClaim.status = Status.Resolved;
        
        emit Fund(_claimID, Party.Owner, itemClaim.amountLocked);
    }


     

     
    function payArbitrationFeeByOwner(uint _claimID) public payable {
        Claim storage itemClaim = claims[_claimID];
         Item storage item = items[itemClaim.itemID];

        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(
            itemClaim.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction of the item has been executed."
        );
        require(item.owner == msg.sender, "The caller must be the owner of the item.");
        require(true == itemClaim.isAccepted, "The claim of the item must be accepted.");

        item.ownerFee += msg.value;
         
        require(item.ownerFee >= arbitrationCost, "The owner fee must cover arbitration costs.");

        itemClaim.lastInteraction = now;
         
        if (itemClaim.finderFee < arbitrationCost) {
            itemClaim.status = Status.WaitingFinder;
            emit HasToPayFee(_claimID, Party.Finder);
        } else {  
            raiseDispute(_claimID, arbitrationCost);
        }
    }

     
    function payArbitrationFeeByFinder(uint _claimID) public payable {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(
            itemClaim.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction has been executed."
        );
        require(itemClaim.finder == msg.sender, "The caller must be the sender.");
        require(true == itemClaim.isAccepted, "The claim of the item must be accepted.");

        itemClaim.finderFee += msg.value;
         
        require(itemClaim.finderFee >= arbitrationCost, "The finder fee must cover arbitration costs.");

        itemClaim.lastInteraction = now;

         
        if (item.ownerFee < arbitrationCost) {
            itemClaim.status = Status.WaitingOwner;
            emit HasToPayFee(_claimID, Party.Owner);
        } else {  
            raiseDispute(_claimID, arbitrationCost);
        }
    }

     
    function timeOutByOwner(uint _claimID) public {
        Claim storage itemClaim = claims[_claimID];

        require(
            itemClaim.status == Status.WaitingFinder,
            "The transaction of the item must waiting on the finder."
        );
        require(now - itemClaim.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

        if (itemClaim.finderFee != 0) {
            itemClaim.finder.send(itemClaim.finderFee);
            itemClaim.finderFee = 0;
        }

        executeRuling(_claimID, uint(RulingOptions.OwnerWins));
    }

     
    function timeOutByFinder(uint _claimID) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(
            itemClaim.status == Status.WaitingOwner,
            "The transaction of the item must waiting on the owner of the item."
        );
        require(now - itemClaim.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

        if (item.ownerFee != 0) {
            item.owner.send(item.ownerFee);
            item.ownerFee = 0;
        }

        executeRuling(_claimID, uint(RulingOptions.FinderWins));
    }

     
    function raiseDispute(uint _claimID, uint _arbitrationCost) internal {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        itemClaim.status = Status.DisputeCreated;
        uint disputeID = arbitrator.createDispute.value(_arbitrationCost)(AMOUNT_OF_CHOICES, arbitratorExtraData);
        disputeIDtoClaimAcceptedID[disputeID] = _claimID;
        itemClaim.disputeID = disputeID;
        emit Dispute(arbitrator, itemClaim.disputeID, _claimID, _claimID);

         
        if (itemClaim.finderFee > _arbitrationCost) {
            uint extraFeeFinder = itemClaim.finderFee - _arbitrationCost;
            itemClaim.finderFee = _arbitrationCost;
            itemClaim.finder.send(extraFeeFinder);
        }

         
        if (item.ownerFee > _arbitrationCost) {
            uint extraFeeOwner = item.ownerFee - _arbitrationCost;
            item.ownerFee = _arbitrationCost;
            item.owner.send(extraFeeOwner);
        }
    }

     
    function submitEvidence(uint _claimID, string memory _evidence) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(
            msg.sender == item.owner || msg.sender == itemClaim.finder,
            "The caller must be the owner of the item or the finder."
        );

        require(itemClaim.status >= Status.DisputeCreated, "The dispute has not been created yet.");
        emit Evidence(arbitrator, _claimID, msg.sender, _evidence);
    }

     
    function appeal(uint _claimID) public payable {
        Claim storage itemClaim = claims[_claimID];

        require(
            msg.sender == items[itemClaim.itemID].owner || msg.sender == itemClaim.finder,
            "The caller must be the owner of the item or the finder."
        );

        arbitrator.appeal.value(msg.value)(itemClaim.disputeID, arbitratorExtraData);
    }

     
    function rule(uint _disputeID, uint _ruling) external {
        require(msg.sender == address(arbitrator), "The sender of the transaction must be the arbitrator.");

        Claim storage itemClaim = claims[disputeIDtoClaimAcceptedID[_disputeID]];  

        require(Status.DisputeCreated == itemClaim.status, "The dispute has already been resolved.");

        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(disputeIDtoClaimAcceptedID[_disputeID], _ruling);
    }

     
    function executeRuling(uint _claimID, uint _ruling) internal {
        require(_ruling <= AMOUNT_OF_CHOICES, "Invalid ruling.");
        Claim storage itemClaim = claims[disputeIDtoClaimAcceptedID[_claimID]];
        Item storage item = items[itemClaim.itemID];

         
         
        if (_ruling == uint(RulingOptions.OwnerWins)) {
            item.owner.send(item.ownerFee + itemClaim.amountLocked);
        } else if (_ruling == uint(RulingOptions.FinderWins)) {
            itemClaim.finder.send(itemClaim.finderFee + itemClaim.amountLocked);
        } else {
            uint split_amount = (item.ownerFee + itemClaim.amountLocked) / 2;
            item.owner.send(split_amount);
            itemClaim.finder.send(split_amount);
        }

        itemClaim.amountLocked = 0;
        item.ownerFee = 0;
        itemClaim.finderFee = 0;
        itemClaim.status = Status.Resolved;
    }

     
     
     

     
    function isItemExist(bytes32 _itemID) public view returns (bool) {
        return items[_itemID].exists;
    }
    
     
    function getItemIDsByOwner(address _owner) public view returns (bytes32[]) {
        return owners[_owner].itemIDs;
    }

     
    function getClaimsByItemID(bytes32 _itemID) public view returns(uint[]) {
        return items[_itemID].claimIDs;
    }

     
    function getClaimIDsByAddress(address _finder) public view returns (uint[] claimIDs) {
        uint count = 0;
        for (uint i = 0; i < claims.length; i++) {
            if (claims[i].finder == _finder)
                count++;
        }

        claimIDs = new uint[](count);

        count = 0;

        for (uint j = 0; j < claims.length; j++) {
            if (claims[j].finder == _finder)
                claimIDs[count++] = j;
        }
    }
}