 

 
 
 pragma solidity ^0.4.10;

 

 

 

 


contract Owned {
    address public owner;        

    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        owner = _newOwner;
    }
}
 

 
 
contract Manageable is Owned {

    event ManagerSet(address manager, bool state);

    mapping (address => bool) public managers;

    function Manageable() Owned() {
        managers[owner] = true;
    }

     
    modifier managerOnly {
        assert(managers[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        super.transferOwnership(_newOwner);

        managers[_newOwner] = true;
        managers[msg.sender] = false;
    }

    function setManager(address manager, bool state) ownerOnly {
        managers[manager] = state;
        ManagerSet(manager, state);
    }
} 

 
contract IInvestRestrictions is Manageable {
     
    function canInvest(address investor, uint amount, uint tokensLeft) constant returns (bool result) {
        investor; amount; result; tokensLeft;
    }

     
    function investHappened(address investor, uint amount) managerOnly {}    
} 

 
contract FloorInvestRestrictions is IInvestRestrictions {

     
    uint256 public floor;

     
    mapping (address => bool) public investors;


    function FloorInvestRestrictions(uint256 _floor) {
        floor = _floor;
    }

     
    function canInvest(address investor, uint amount, uint tokensLeft) constant returns (bool result) {
        
         
        if (investors[investor]) {
            result = true;
        } else {
             
            result = (amount >= floor);
        }
    }

     
    function investHappened(address investor, uint amount) managerOnly {
        investors[investor] = true;
    }

     
    function changeFloor(uint256 newFloor) managerOnly {
        floor = newFloor;
    }
} 
 

 
contract ICrowdsaleFormula {

     
    function howManyTokensForEther(uint256 weiAmount) constant returns(uint256 tokens, uint256 excess) {
        weiAmount; tokens; excess;
    }

     
    function tokensLeft() constant returns(uint256 _left) { _left;}    
} 

 
contract ParticipantInvestRestrictions is FloorInvestRestrictions {

    struct ReservedInvestor {
        bool reserved;        
        uint256 tokens;
    }

    event ReserveKnown(bool state, address investor, uint256 weiAmount, uint256 tokens);
    event ReserveUnknown(bool state, uint32 index, uint256 weiAmount, uint256 tokens);

     
    ReservedInvestor[] public unknownInvestors;

     
    ICrowdsaleFormula public formula;

     
    uint32 public maxInvestors;    

     
    uint32 public investorsCount;

     
    uint32 public knownReserved;

     
    uint32 public unknownReserved;

     
    mapping (address => uint256) public reservedInvestors;

     
    uint256 public tokensReserved;

    function ParticipantInvestRestrictions(uint256 _floor, uint32 _maxTotalInvestors)
        FloorInvestRestrictions(_floor)
    {
        maxInvestors = _maxTotalInvestors;
    }

     
    function setFormula(ICrowdsaleFormula _formula) managerOnly {
        formula = _formula;        
    }

     
    function hasFreePlaces() constant returns (bool) {
        return getInvestorCount() < maxInvestors;
    }

     
    function getInvestorCount() constant returns(uint32) {
        return investorsCount + knownReserved + unknownReserved;
    }

     
    function canInvest(address investor, uint amount, uint tokensLeft) constant returns (bool result) {
         
         
        if (super.canInvest(investor, amount, tokensLeft)) {
            if (reservedInvestors[investor] > 0) {
                return true;
            } else {
                var (tokens, excess) = formula.howManyTokensForEther(amount);
                if (tokensLeft >= tokensReserved + tokens) {
                    return investors[investor] || hasFreePlaces();
                }
            }
        }

        return false;
    }
 
     
    function investHappened(address investor, uint amount) managerOnly {
        if (!investors[investor]) {
            investors[investor] = true;
            investorsCount++;
            
             
            if (reservedInvestors[investor] > 0) {
                unreserveFor(investor);
            }
        }
    }

     
    function reserveFor(address investor, uint256 weiAmount) managerOnly {
        require(!investors[investor] && hasFreePlaces());

        if(reservedInvestors[investor] == 0) {
            knownReserved++;
        }

        reservedInvestors[investor] += reserveTokens(weiAmount);
        ReserveKnown(true, investor, weiAmount, reservedInvestors[investor]);
    }

     
    function unreserveFor(address investor) managerOnly {
        require(reservedInvestors[investor] != 0);

        knownReserved--;
        unreserveTokens(reservedInvestors[investor]);
        reservedInvestors[investor] = 0;

        ReserveKnown(false, investor, 0, 0);
    }

     
    function reserve(uint256 weiAmount) managerOnly {
        require(hasFreePlaces());
        unknownReserved++;
        uint32 id = uint32(unknownInvestors.length++);
        unknownInvestors[id].reserved = true;        
        unknownInvestors[id].tokens = reserveTokens(weiAmount);

        ReserveUnknown(true, id, weiAmount, unknownInvestors[id].tokens);
    }

     
    function unreserve(uint32 index) managerOnly {
        require(index < unknownInvestors.length && unknownInvestors[index].reserved);
        
        assert(unknownReserved > 0);
        unknownReserved--;
        unreserveTokens(unknownInvestors[index].tokens);        
        unknownInvestors[index].reserved = false;

        ReserveUnknown(false, index, 0, 0);
    }

     
    function reserveTokens(uint256 weiAmount) 
        internal 
        managerOnly 
        returns(uint256) 
    {
        uint256 tokens;
        uint256 excess;
        (tokens, excess) = formula.howManyTokensForEther(weiAmount);
        
        if (tokensReserved + tokens > formula.tokensLeft()) {
            tokens = formula.tokensLeft() - tokensReserved;
        }
        tokensReserved += tokens;

        return tokens;
    }

     
    function unreserveTokens(uint256 tokenAmount) 
        internal 
        managerOnly 
    {
        if (tokenAmount > tokensReserved) {
            tokensReserved = 0;
        } else {
            tokensReserved = tokensReserved - tokenAmount;
        }
    }
}