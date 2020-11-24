 

pragma solidity ^0.4.23;


 
contract Ownable {
    address public owner;

     
    mapping(address => uint) public allOwnersMap;


     
    constructor () public {
        owner = msg.sender;
        allOwnersMap[msg.sender] = 1;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner!");
        _;
    }


     
    modifier onlyAnyOwners() {
        require(allOwnersMap[msg.sender] == 1, "You're not the owner or never were the owner!");
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

         
        allOwnersMap[newOwner] = 1;
    }


     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}









 
contract Suicidable is Ownable {
    bool public hasSuicided = false;


     
    modifier hasNotSuicided() {
        require(hasSuicided == false, "Contract has suicided!");
        _;
    }


     
    function suicideContract() public onlyAnyOwners {
        hasSuicided = true;
        emit SuicideContract(msg.sender);
    }


     
    event SuicideContract(address indexed owner);
}



 
contract Migratable is Suicidable {
    bool public hasRequestedForMigration = false;
    uint public requestedForMigrationAt = 0;
    address public migrationDestination;

    function() public payable {

    }

     
    function requestForMigration(address destination) public onlyOwner {
        hasRequestedForMigration = true;
        requestedForMigrationAt = now;
        migrationDestination = destination;

        emit MigrateFundsRequested(msg.sender, destination);
    }

     
    function cancelMigration() public onlyOwner hasNotSuicided {
        hasRequestedForMigration = false;
        requestedForMigrationAt = 0;

        emit MigrateFundsCancelled(msg.sender);
    }

     
    function approveMigration(uint gasCostInGwei) public onlyOwner hasNotSuicided {
        require(hasRequestedForMigration, "please make a migration request");
        require(requestedForMigrationAt + 604800 < now, "migration is timelocked for 7 days");
        require(gasCostInGwei > 0, "gas cost must be more than 0");
        require(gasCostInGwei < 20, "gas cost can't be more than 20");

         
        uint gasLimit = 21000;
        uint gasPrice = gasCostInGwei * 1000000000;
        uint gasCost = gasLimit * gasPrice;
        uint etherToSend = address(this).balance - gasCost;

        require(etherToSend > 0, "not enough balance in smart contract");

         
        emit MigrateFundsApproved(msg.sender, etherToSend);
        migrationDestination.transfer(etherToSend);

         
        suicideContract();
    }

     
    event MigrateFundsCancelled(address indexed by);
    event MigrateFundsRequested(address indexed by, address indexed newSmartContract);
    event MigrateFundsApproved(address indexed by, uint amount);
}



 
contract Bitwords is Migratable {
    mapping(address => uint) public advertiserBalances;

     
    mapping(address => uint) public bitwordsCutOverride;

     
    address public bitwordsWithdrawlAddress;

     
    uint public bitwordsCutOutof100 = 10;

     
     
    struct advertiserChargeRequest {
        address advertiser;
        address publisher;
        uint amount;
        uint requestedAt;
        uint processAfter;
    }

     
    uint public refundRequestTimelock = 7 days;

     
    struct refundRequest {
        address advertiser;
        uint amount;
        uint requestedAt;
        uint processAfter;
    }

     
    refundRequest[] public refundQueue;

     
    mapping(address => uint) private advertiserRefundRequestsIndex;
    uint private lastProccessedIndex = 0;


     
    constructor () public {
        bitwordsWithdrawlAddress = msg.sender;
    }

     
    function() public payable {
        advertiserBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, advertiserBalances[msg.sender]);
    }

     
    function setBitwordsWithdrawlAddress (address newAddress) hasNotSuicided onlyOwner public {
        bitwordsWithdrawlAddress = newAddress;

        emit BitwordsWithdrawlAddressChanged(msg.sender, newAddress);
    }

     
    function setBitwordsCut (uint cut) hasNotSuicided onlyOwner public {
        require(cut <= 30, "cut cannot be more than 30%");
        require(cut >= 0, "cut should be greater than 0%");
        bitwordsCutOutof100 = cut;

        emit BitwordsCutChanged(msg.sender, cut);
    }

     
    function setRefundTimelock (uint newTimelock) hasNotSuicided onlyOwner public {
        require(newTimelock >= 0, "timelock has to be greater than 0");
        refundRequestTimelock = newTimelock;

        emit TimelockChanged(msg.sender, newTimelock);
    }

     
    bool private inProcessRefunds = false;
    function processRefunds () onlyAnyOwners public {
         
        require(!inProcessRefunds, "prevent reentry bug");
        inProcessRefunds = true;

        for (uint j = lastProccessedIndex; j < refundQueue.length; j++) {
             
             
             
            if (refundQueue[j].processAfter > now) break;

             
             
             
             
            uint cappedAmount = refundQueue[j].amount;
            if (advertiserBalances[refundQueue[j].advertiser] < cappedAmount)
                cappedAmount = advertiserBalances[refundQueue[j].advertiser];

             
            if (cappedAmount <= 0) {
                lastProccessedIndex++;
                continue;
            }

             
            advertiserBalances[refundQueue[j].advertiser] -= cappedAmount;
            refundQueue[j].advertiser.transfer(cappedAmount);
            refundQueue[j].amount = 0;

             
            emit RefundAdvertiserProcessed(refundQueue[j].advertiser, cappedAmount, advertiserBalances[refundQueue[j].advertiser]);

             
             
            lastProccessedIndex++;
        }

        inProcessRefunds = false;
    }

     
    function creditAdvertiser (address advertiser) hasNotSuicided public payable {
        advertiserBalances[advertiser] += msg.value;
        emit Deposit(advertiser, msg.value, advertiserBalances[msg.sender]);
    }

     
    function setPublisherCut (address publisher, uint cut) hasNotSuicided onlyOwner public {
        require(cut <= 30, "cut cannot be more than 30%");
        require(cut >= 0, "cut should be greater than 0%");

        bitwordsCutOverride[publisher] = cut;
        emit SetPublisherCut(publisher, cut);
    }

     
    bool private inChargeAdvertisers = false;
    function chargeAdvertisers (address[] advertisers, uint[] costs, address[] publishers, uint[] publishersToCredit) hasNotSuicided onlyOwner public {
         
        require(!inChargeAdvertisers, "avoid rentry bug");
        inChargeAdvertisers = true;

        uint creditArrayIndex = 0;

        for (uint i = 0; i < advertisers.length; i++) {
            uint toWithdraw = costs[i];

             
            if (advertiserBalances[advertisers[i]] <= 0) {
                emit InsufficientBalance(advertisers[i], advertiserBalances[advertisers[i]], costs[i]);
                continue;
            }
            if (advertiserBalances[advertisers[i]] < toWithdraw) toWithdraw = advertiserBalances[advertisers[i]];

             
            advertiserBalances[advertisers[i]] -= toWithdraw;
            emit DeductFromAdvertiser(advertisers[i], toWithdraw, advertiserBalances[advertisers[i]]);

             
            uint bitwordsCut = bitwordsCutOutof100;
            if (bitwordsCutOverride[publishers[i]] > 0 && bitwordsCutOverride[publishers[i]] <= 30) {
                bitwordsCut = bitwordsCutOverride[publishers[i]];
            }

             
            uint publisherNetCut = toWithdraw * (100 - bitwordsCut) / 100;
            uint bitwordsNetCut = toWithdraw - publisherNetCut;

             
             
            if (publishersToCredit.length > creditArrayIndex && publishersToCredit[creditArrayIndex] == i) {
                creditArrayIndex++;
                advertiserBalances[publishers[i]] += publisherNetCut;
                emit CreditPublisher(publishers[i], publisherNetCut, advertisers[i], advertiserBalances[publishers[i]]);
            } else {  
                publishers[i].transfer(publisherNetCut);
                emit PayoutToPublisher(publishers[i], publisherNetCut, advertisers[i]);
            }

             
            bitwordsWithdrawlAddress.transfer(bitwordsNetCut);
            emit PayoutToBitwords(bitwordsWithdrawlAddress, bitwordsNetCut, advertisers[i]);
        }

        inChargeAdvertisers = false;
    }

     
    bool private inRefundAdvertiser = false;
    function refundAdvertiser (address advertiser, uint amount) onlyAnyOwners public {
         
         
        require(amount > 0, "Amount should be greater than 0");
        require(advertiserBalances[advertiser] > 0, "Advertiser has no balance");
        require(advertiserBalances[advertiser] >= amount, "Insufficient balance to refund");

         
        require(!inRefundAdvertiser, "avoid rentry bug");
        inRefundAdvertiser = true;

         
        advertiserBalances[advertiser] -= amount;
        advertiser.transfer(amount);

         
        emit RefundAdvertiserProcessed(advertiser, amount, advertiserBalances[advertiser]);

        inRefundAdvertiser = false;
    }

     
    function invalidateAdvertiserRefund (uint refundIndex) hasNotSuicided onlyOwner public {
        require(refundIndex >= 0, "index should be greater than 0");
        require(refundQueue.length >=  refundIndex, "index is out of bounds");
        refundQueue[refundIndex].amount = 0;

        emit RefundAdvertiserCancelled(refundQueue[refundIndex].advertiser);
    }

     
    function requestForRefund (uint amount) public {
         
         
        require(amount > 0, "Amount should be greater than 0");
        require(advertiserBalances[msg.sender] > 0, "You have no balance");
        require(advertiserBalances[msg.sender] >= amount, "Insufficient balance to refund");

         
         
        refundQueue.push(refundRequest(msg.sender, amount, now, now + refundRequestTimelock));

         
        advertiserRefundRequestsIndex[msg.sender] = refundQueue.length - 1;

         
        emit RefundAdvertiserRequested(msg.sender, amount, refundQueue.length - 1);
    }

     
    mapping(address => bool) private inProcessMyRefund;
    function processMyRefund () public {
         
        require(advertiserRefundRequestsIndex[msg.sender] >= 0, "no refund request found");

         
        uint refundRequestIndex = advertiserRefundRequestsIndex[msg.sender];

         
        require(refundQueue[refundRequestIndex].amount > 0, "refund already proccessed");

         
        require(
            advertiserBalances[msg.sender] >= refundQueue[refundRequestIndex].amount,
            "advertiser balance is low; refund amount is invalid."
        );

         
        require(
            now > refundQueue[refundRequestIndex].processAfter,
            "timelock for this request has not passed"
        );

         
        require(!inProcessMyRefund[msg.sender], "prevent re-entry bug");
        inProcessMyRefund[msg.sender] = true;

         
        uint amount = refundQueue[refundRequestIndex].amount;
        msg.sender.transfer(amount);

         
        refundQueue[refundRequestIndex].amount = 0;
        advertiserBalances[msg.sender] -= amount;

         
        inProcessMyRefund[msg.sender] = false;

         
        emit SelfRefundAdvertiser(msg.sender, amount, advertiserBalances[msg.sender]);
        emit RefundAdvertiserProcessed(msg.sender, amount, advertiserBalances[msg.sender]);
    }

     
    event BitwordsCutChanged(address indexed _to, uint _value);
    event BitwordsWithdrawlAddressChanged(address indexed _to, address indexed _from);
    event CreditPublisher(address indexed _to, uint _value, address indexed _from, uint _newBalance);
    event DeductFromAdvertiser(address indexed _to, uint _value, uint _newBalance);
    event Deposit(address indexed _to, uint _value, uint _newBalance);
    event InsufficientBalance(address indexed _to, uint _balance, uint _valueToDeduct);
    event PayoutToBitwords(address indexed _to, uint _value, address indexed _from);
    event PayoutToPublisher(address indexed _to, uint _value, address indexed _from);
    event RefundAdvertiserCancelled(address indexed _to);
    event RefundAdvertiserProcessed(address indexed _to, uint _value, uint _newBalance);
    event RefundAdvertiserRequested(address indexed _to, uint _value, uint requestIndex);
    event SelfRefundAdvertiser(address indexed _to, uint _value, uint _newBalance);
    event SetPublisherCut(address indexed _to, uint _value);
    event TimelockChanged(address indexed _to, uint _value);
}