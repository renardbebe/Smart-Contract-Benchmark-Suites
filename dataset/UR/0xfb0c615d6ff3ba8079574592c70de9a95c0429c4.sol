 

pragma solidity 0.4.25;

 
 
 
 
 
 
 
 

contract SamuraiQuest {

    using SafeMath for uint256;
    using LinkedListLib for LinkedListLib.LinkedList;

     
    event NewSamuraiIncoming(uint256 id, bytes32 name);
    event TheLastSamuraiBorn(uint256 id, bytes32 name, uint256 winning);
    event Retreat(uint256 id, bytes32 name, uint256 balance);

    address public owner;

    uint256 public currentSamuraiId;
    uint256 public totalProcessingFee;
    uint256 public theLastSamuraiPot;
    uint256 public theLastSamuraiEndTime;

     
    uint256 private constant MAX_LEVEL = 8;
    uint256 private constant JOINING_FEE = 0.03 ether;
    uint256 private constant PROCESSING_FEE = 0.001 ether;
    uint256 private constant REFERRAL_FEE = 0.002 ether;
    uint256 private constant THE_LAST_SAMURAI_FEE = 0.002 ether;
    uint256 private constant THE_LAST_SAMURAI_COOLDOWN = 1 days;

    struct Samurai {
        uint256 level;
        uint256 supporterWallet;
        uint256 referralWallet;
        uint256 theLastSamuraiWallet;
        bytes32 name;
        address addr;
        bool isRetreat;
        bool autoLevelUp;
    }

    mapping (address => uint256) public addressToId;
    mapping (uint256 => Samurai) public idToSamurai;
    mapping (uint256 => uint256) public idToSamuraiHeadId;
    mapping (uint256 => uint256) public idToAffiliateId;
    mapping (uint256 => uint256) public supporterCount;
    mapping (uint256 => uint256) public referralCount;
    
    mapping (uint256 => LinkedListLib.LinkedList) private levelChain;  
    uint256[9] public levelUpFee;  

     
    constructor() public {
         
        owner = msg.sender;

        totalProcessingFee = 0;
        theLastSamuraiPot = 0;
        currentSamuraiId = 1;
        
         
        levelUpFee[1] = 0.02 ether;  
        levelUpFee[2] = 0.04 ether;  
        levelUpFee[3] = 0.08 ether;  
        levelUpFee[4] = 0.16 ether;  
        levelUpFee[5] = 0.32 ether;  
        levelUpFee[6] = 0.64 ether;  
        levelUpFee[7] = 1.28 ether;  
        levelUpFee[8] = 2.56 ether;  
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner method called by non owner");
        _;
    }

     
    function withdrawProcessingFee() public onlyOwner {
        require(totalProcessingFee <= address(this).balance, "not enough fund");
    
        uint256 amount = totalProcessingFee;

        totalProcessingFee = 0;

        owner.transfer(amount);
    }

     
    function () public payable { }

     

     
     
     
     
     
    function join(bytes32 _name, uint256 _affiliateId, bool _autoLevelUp) public payable {
        require(msg.value == JOINING_FEE, "you have no enough courage");
        require(addressToId[msg.sender] == 0, "you're already in");
        require(_affiliateId >= 0 && _affiliateId < currentSamuraiId, "invalid affiliate");

        Samurai storage samurai = idToSamurai[currentSamuraiId];
        
        samurai.level = 0;
        samurai.addr = msg.sender;
        samurai.referralWallet = 0;
        samurai.theLastSamuraiWallet = 0;
        samurai.name = _name;
        samurai.isRetreat = false;
        samurai.autoLevelUp = _autoLevelUp;
        samurai.supporterWallet = JOINING_FEE;

        addressToId[msg.sender] = currentSamuraiId;

        if (_affiliateId > 0) {
            idToAffiliateId[currentSamuraiId] = _affiliateId;
            referralCount[_affiliateId] = referralCount[_affiliateId].add(1);
        }

        levelUp(currentSamuraiId);

        emit NewSamuraiIncoming(currentSamuraiId, samurai.name);

         
        currentSamuraiId = currentSamuraiId.add(1);
        theLastSamuraiEndTime = now.add(THE_LAST_SAMURAI_COOLDOWN);
    }

     

     
     
     
     
     
    function levelUp(uint256 _samuraiId) public {
        bool exist;
        uint256 samuraiHeadId;
        Samurai storage samurai = idToSamurai[_samuraiId];
        
        require(canLevelUp(_samuraiId), "cannot level up");

        uint256 balance = samurai.supporterWallet.add(samurai.referralWallet).add(samurai.theLastSamuraiWallet);

        require(
            balance >= levelUpFee[samurai.level.add(1)].add(PROCESSING_FEE).add(THE_LAST_SAMURAI_FEE).add(REFERRAL_FEE),
            "not enough fund to level up"
        );

         
        samurai.level = samurai.level.add(1);

         
        distributeTheLastSamuraiPot();

         
        push(levelChain[samurai.level], _samuraiId);
        supporterCount[_samuraiId] = 0;

         
        (exist, samuraiHeadId) = levelChain[samurai.level].getAdjacent(0, true);
        
         
        samurai.supporterWallet = samurai.supporterWallet.sub(PROCESSING_FEE);
        totalProcessingFee = totalProcessingFee.add(PROCESSING_FEE);

         
        samurai.supporterWallet = samurai.supporterWallet.sub(THE_LAST_SAMURAI_FEE);
        theLastSamuraiPot = theLastSamuraiPot.add(THE_LAST_SAMURAI_FEE);
        
         
        uint256 affiliateId = idToAffiliateId[_samuraiId];

        samurai.supporterWallet = samurai.supporterWallet.sub(REFERRAL_FEE);
        if (affiliateId == 0) {
            theLastSamuraiPot = theLastSamuraiPot.add(REFERRAL_FEE);
        } else {
            Samurai storage affiliate = idToSamurai[affiliateId];
            affiliate.referralWallet = affiliate.referralWallet.add(REFERRAL_FEE);
        }

         
        if (exist && samuraiHeadId != _samuraiId) {
            Samurai storage samuraiHead = idToSamurai[samuraiHeadId];

             
            samurai.supporterWallet = samurai.supporterWallet.sub(levelUpFee[samurai.level]);
            samuraiHead.supporterWallet = samuraiHead.supporterWallet.add(levelUpFee[samurai.level]);

             
            idToSamuraiHeadId[_samuraiId] = samuraiHeadId;

             
            supporterCount[samuraiHeadId] = supporterCount[samuraiHeadId].add(1);

             
            if(canLevelUp(samuraiHeadId)) {
                 
                pop(levelChain[samuraiHead.level]);
                
                if(samuraiHead.autoLevelUp) {
                    levelUp(samuraiHeadId);
                } else {
                    return;
                }
            } else {
                return;
            }
        }
    }
    
     
    
     
     
     
     
    function retreat(uint256 _samuraiId) public {
        Samurai storage samurai = idToSamurai[_samuraiId];

        require(!samurai.isRetreat, "you've already quit!");
        require(samurai.addr == msg.sender, "you must be a yokai spy!");

        uint256 balance = samurai.supporterWallet.add(samurai.referralWallet).add(samurai.theLastSamuraiWallet);

        require(balance >= 0.005 ether, "fee is required, even when retreating");

         
        samurai.supporterWallet = 0;
        samurai.theLastSamuraiWallet = 0;
        samurai.referralWallet = 0;

         
        remove(levelChain[samurai.level], _samuraiId);
        samurai.isRetreat = true;
        
         
        balance = balance.sub(PROCESSING_FEE);
        totalProcessingFee = totalProcessingFee.add(PROCESSING_FEE);

        balance = balance.sub(THE_LAST_SAMURAI_FEE);
        theLastSamuraiPot = theLastSamuraiPot.add(THE_LAST_SAMURAI_FEE);

        balance = balance.sub(REFERRAL_FEE);

        uint256 affiliateId = idToAffiliateId[_samuraiId];

         
        if (affiliateId == 0) {
            theLastSamuraiPot = theLastSamuraiPot.add(REFERRAL_FEE);
        } else {
            Samurai storage affiliate = idToSamurai[affiliateId];
            affiliate.referralWallet = affiliate.referralWallet.add(REFERRAL_FEE);
        }

         
        samurai.addr.transfer(balance);

         
        distributeTheLastSamuraiPot();

        emit Retreat(_samuraiId, samurai.name, balance);
    }

     
    
     
     
    function withdraw(uint256 _samuraiId) public {
        Samurai storage samurai = idToSamurai[_samuraiId];

        require(samurai.addr == msg.sender, "you must be a yokai spy!");

        uint256 balance = samurai.supporterWallet.add(samurai.referralWallet).add(samurai.theLastSamuraiWallet);

        require(balance <= address(this).balance, "not enough fund");

         
        samurai.supporterWallet = 0;
        samurai.theLastSamuraiWallet = 0;
        samurai.referralWallet = 0;

         
        samurai.addr.transfer(balance);
    }

     
    
     
     
     
    function distributeTheLastSamuraiPot() public {
        require(theLastSamuraiPot <= address(this).balance, "not enough fund");

         
        if (theLastSamuraiEndTime <= now) {
            uint256 samuraiId = currentSamuraiId.sub(1);
            Samurai storage samurai = idToSamurai[samuraiId];

            uint256 total = theLastSamuraiPot;
            
             
            theLastSamuraiPot = 0;
            samurai.theLastSamuraiWallet = samurai.theLastSamuraiWallet.add(total);

            emit TheLastSamuraiBorn(samuraiId, samurai.name, total);
        }
    }

     
    
     
     
     
    function toggleAutoLevelUp(uint256 _samuraiId) public {
        Samurai storage samurai = idToSamurai[_samuraiId];

        require(!samurai.isRetreat, "you've already quit!");
        require(msg.sender == samurai.addr, "you must be a yokai spy");

        samurai.autoLevelUp = !samurai.autoLevelUp;
    }

     

     
    function getSamuraiId() public view returns(uint256) {
        return addressToId[msg.sender];
    }

     
    function getSamuraiInfo(uint256 _samuraiId) public view
        returns(uint256, uint256, bytes32, bool, bool, bool)
    {
        Samurai memory samurai = idToSamurai[_samuraiId];
        bool isHead = isHeadOfSamurai(_samuraiId);
        
        return (_samuraiId, samurai.level, samurai.name, samurai.isRetreat, samurai.autoLevelUp, isHead);
    }

     
    function getSamuraiWallet(uint256 _samuraiId) public view
        returns(uint256, uint256, uint256)
    {
        Samurai memory samurai = idToSamurai[_samuraiId];

        return (samurai.supporterWallet, samurai.theLastSamuraiWallet, samurai.referralWallet);
    }
    
     
    function getAffiliateInfo(uint256 _samuraiId) public view returns(uint256, bytes32) {
        uint256 affiliateId = idToAffiliateId[_samuraiId];
        Samurai memory affiliate = idToSamurai[affiliateId];

        return (affiliateId, affiliate.name);
    }

     
    function contributeTo(uint256 _samuraiId) public view returns(uint256, bytes32) {
        uint256 samuraiHeadId = idToSamuraiHeadId[_samuraiId];
        Samurai memory samuraiHead = idToSamurai[samuraiHeadId];

        return (samuraiHeadId, samuraiHead.name);
    }

     
    function getTheLastSamuraiInfo() public view returns(uint256, uint256, uint256, bytes32) {
        uint256 lastSamuraiId = currentSamuraiId.sub(1);

        return (theLastSamuraiEndTime, theLastSamuraiPot, lastSamuraiId, idToSamurai[lastSamuraiId].name);
    }
    
     
    function canLevelUp(uint256 _id) public view returns(bool) {
        Samurai memory samurai = idToSamurai[_id];
        
        return !samurai.isRetreat && (samurai.level == 0 || (supporterCount[_id] == 2 ** samurai.level && samurai.level <= MAX_LEVEL));
    }

     
    function canRetreat(uint256 _id) public view returns(bool) {
        Samurai memory samurai = idToSamurai[_id];
        uint256 balance = samurai.supporterWallet.add(samurai.referralWallet).add(samurai.theLastSamuraiWallet);

        return !samurai.isRetreat && (balance >= 0.005 ether);
    }

     
    function canWithdraw(uint256 _id) public view returns(bool) {
        Samurai memory samurai = idToSamurai[_id];
        uint256 balance = samurai.supporterWallet.add(samurai.referralWallet).add(samurai.theLastSamuraiWallet);

        return samurai.isRetreat && (balance > 0);
    }

     
    function isHeadOfSamurai(uint256 _id) public view returns(bool) {
        Samurai memory samurai = idToSamurai[_id];
        bool exist;
        uint256 samuraiHeadId;

        (exist, samuraiHeadId) = levelChain[samurai.level].getAdjacent(0, true);

        return (exist && samuraiHeadId == _id);
    }
    
     
    function push(LinkedListLib.LinkedList storage _levelChain, uint256 _samuraiId) private {
        _levelChain.push(_samuraiId, false);
    }
    
    function pop(LinkedListLib.LinkedList storage _levelChain) private {
        _levelChain.pop(true);
    }
    
    function remove(LinkedListLib.LinkedList storage _levelChain, uint256 _samuraiId) private {
        _levelChain.remove(_samuraiId);
    }
}

 

library LinkedListLib {


    uint256 private constant NULL = 0;
    uint256 private constant HEAD = 0;
    bool private constant PREV = false;
    bool private constant NEXT = true;
    
    struct LinkedList {
        mapping (uint256 => mapping (bool => uint256)) list;
    }

   
   
    function listExists(LinkedList storage self)
        internal
        view returns (bool)
    {
         
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function nodeExists(LinkedList storage self, uint256 _node) 
        internal
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
  
     
     
    function sizeOf(LinkedList storage self) internal view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists, i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists, i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

     
     
     
    function getNode(LinkedList storage self, uint256 _node)
        internal view returns (bool, uint256, uint256)
    {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

     
     
     
     
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        internal view returns (bool, uint256)
    {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }
  
     
     
     
     
     
     
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        internal view returns (uint256)
    {
        if (sizeOf(self) == 0) {
            return 0;
        }

        require((_node == 0) || nodeExists(self, _node));

        bool exists;
        uint256 next;

        (exists, next) = getAdjacent(self, _node, _direction);

        while ((next != 0) && (_value != next) && ((_value < next) != _direction)) {
            next = self.list[next][_direction];
        }

        return next;
    }

     
     
     
     
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction)
        internal
    {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

     
     
     
     
     
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);

            return true;
        } else {
            return false;
        }
    }
    
     
     
     
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self, _node))) {
            return 0;
        }

        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];

        return _node;
    }

     
     
     
     
    function push(LinkedList storage self, uint256 _node, bool _direction)    
        internal returns (bool)
    {
        return insert(self, HEAD, _node, _direction);
    }
    
     
     
     
    function pop(LinkedList storage self, bool _direction) 
        internal returns (uint256)
    {
        bool exists;
        uint256 adj;

        (exists, adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        
        return a % b;
    }
}