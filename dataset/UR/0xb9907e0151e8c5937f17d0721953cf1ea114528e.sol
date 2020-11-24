 

pragma solidity ^0.4.21;

 


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct LinkedList{
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
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

     
     
     
    function getNode(LinkedList storage self, uint256 _node)
        internal view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

     
     
     
     
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        internal view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }
    
     
     
     
     
     
     
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        internal view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }
    
     
     
     
     
     
     
    function getSortedSpotByFunction(LinkedList storage self, uint256 _node, uint256 _value, bool _direction, function (uint, uint) view returns (bool) smallerComparator, int256 searchLimit)
        internal view returns (uint256 nextNodeIndex, bool found, uint256 sizeEnd)
    {
        if ((sizeEnd=sizeOf(self)) == 0) { return (0, true, sizeEnd); }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((--searchLimit >= 0) && (next != 0) && (_value != next) && (smallerComparator(_value, next) != _direction)) next = self.list[next][_direction];
        if(searchLimit >= 0)
            return (next, true, sizeEnd + 1);
        else return (0, false, sizeEnd);  
    }

     
     
     
     
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) internal  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

     
     
     
     
     
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }
    
     
     
     
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

     
     
     
     
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }
    
     
     
     
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

 
 
 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}

contract Mutex {
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
 
contract Recoverable is Owned {
     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
     
     
    function recoverLostEth(address toAddress, uint value) public onlyOwner returns (bool success) {
        toAddress.transfer(value);
        return true;
    }
}

 
contract EmergencyProtectedMode is Owned {
  event EmergencyProtectedModeActivated();
  event EmergencyProtectedModeDeactivated();

  bool public emergencyProtectedMode = false;

   
  modifier whenNotInEmergencyProtectedMode() {
    require(!emergencyProtectedMode);
    _;
  }

   
  modifier whenInEmergencyProtectedMode() {
    require(emergencyProtectedMode);
    _;
  }

   
  function activateEmergencyProtectedMode() onlyOwner whenNotInEmergencyProtectedMode public {
    emergencyProtectedMode = true;
    emit EmergencyProtectedModeActivated();
  }

   
  function deactivateEmergencyProtectedMode() onlyOwner whenInEmergencyProtectedMode public {
    emergencyProtectedMode = false;
    emit EmergencyProtectedModeDeactivated();
  }
}

 
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract Migratable is Owned {
    address public sucessor;  
    function setSucessor(address _sucessor) onlyOwner public {
      sucessor=_sucessor;
    }
}

 
 
 
 
 
contract DirectlyExchangeable {
    bool public isRatio;  

    function sellToConsumer(address consumer, uint quantity, uint price) public returns (bool success);
    function buyFromTrusterDealer(address dealer, uint quantity, uint price) public payable returns (bool success);
    function cancelSellToConsumer(address consumer) public returns (bool success);
    function checkMySellerOffer(address consumer) public view returns (uint quantity, uint price, uint totalWeiCost);
    function checkSellerOffer(address seller) public view returns (uint quantity, uint price, uint totalWeiCost);

     
    event DirectOfferAvailable(address indexed seller, address indexed buyer, uint quantity, uint price);
    event DirectOfferCancelled(address indexed seller, address indexed consumer, uint quantity, uint price);
    event OrderQuantityMismatch(address indexed addr, uint expectedInRegistry, uint buyerValue);
    event OrderPriceMismatch(address indexed addr, uint expectedInRegistry, uint buyerValue);
}

 
 
 
 
 
contract BlackMarketSellable {
    bool public isRatio;  

    function sellToBlackMarket(uint quantity, uint price) public returns (bool success, uint numOrderCreated);
    function cancelSellToBlackMarket(uint quantity, uint price, bool continueAfterFirstMatch) public returns (bool success, uint numOrdersCanceled);
    function buyFromBlackMarket(uint quantity, uint priceLimit) public payable returns (bool success, bool partial, uint numOrdersCleared);
    function getSellOrdersBlackMarket() public view returns (uint[] memory r);
    function getSellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices);
    function getMySellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices);

     
    event BlackMarketOfferAvailable(uint quantity, uint price);
    event BlackMarketOfferBought(uint quantity, uint price, uint leftOver);
    event BlackMarketNoOfferForPrice(uint price);
    event BlackMarketOfferCancelled(uint quantity, uint price);
    event OrderInsufficientPayment(address indexed addr, uint expectedValue, uint valueReceived);
    event OrderInsufficientBalance(address indexed addr, uint expectedBalance, uint actualBalance);
}

 
 
 
 
contract Coke is ERC20Interface, Owned, Pausable, EmergencyProtectedMode, Recoverable, Mutex, Migratable, DirectlyExchangeable, BlackMarketSellable, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
    using LinkedListLib for LinkedListLib.LinkedList;
    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

     

    uint16 public constant yearOfProduction = 1997;
    string public constant protectedDenominationOfOrigin = "Colombia";
    string public constant targetDemographics = "The jet set / Top of the tops";
    string public constant securityAudit = "ExtremeAssets Team Ref: XN872 Approved";
    uint buyRatio;  
    uint sellRatio;  
    uint private _factorDecimalsEthToToken;
    uint constant undergroundBunkerReserves = 2500000000000;
    mapping(address => uint) changeToReturn;  
    mapping(address => uint) gainsToReceive;  
    mapping(address => uint) tastersReceived;  
    mapping(address => uint) toFlush;  

    event Flushed(address indexed addr);
    event ChangeToReceiveGotten(address indexed addr, uint weiToReceive, uint totalWeiToReceive);
    event GainsGotten(address indexed addr, uint weiToReceive, uint totalWeiToReceive);
    
    struct SellOffer {
        uint price;
        uint quantity;
    }
    struct SellOfferComplete {
        uint price;
        uint quantity;
        address seller;
    }
    mapping(address => mapping(address => SellOffer)) directOffers;  
    LinkedListLib.LinkedList blackMarketOffersSorted;
    mapping(uint => SellOfferComplete) public blackMarketOffersMap;
    uint marketOfferCounter = 0;  

    uint directOffersComissionRatio = 100;  
    uint marketComissionRatio = 50;  
    int32 maxMarketOffers = 100;  

     
    struct Message {
        uint valuePayed;
        string msg;
        address from;
    }
    LinkedListLib.LinkedList topMessagesSorted;
    mapping(uint => Message) public topMessagesMap;
    uint topMessagesCounter = 0;  
    int32 maxMessagesTop = 20;  
    Message[] messages;
    int32 maxMessagesGlobal = 100;  
    int32 firstMsgGlobal = 0;  
    int32 lastMsgGlobal = -1;
    uint maxCharactersMessage = 750;  

    event NewMessageAvailable(address indexed from, string message);
    event ExceededMaximumMessageSize(uint messageSize, uint maximumMessageSize);  

     
    address[] lastAddresses;
    int32 maxAddresses = 100;  
    int32 firstAddress = 0;  
    int32 lastAddress = -1;
    
    event NoAddressesAvailable();
    
     
     
     
    modifier whenNotFlushing() {
        require(toFlush[msg.sender] == 0);
        _;
    }

     
     
     
    function Coke() public {
        symbol = "Coke";
        name = "100 % Pure Cocaine";
        decimals = 6;  
        _totalSupply = 875000000 * (uint(10)**decimals);
        _factorDecimalsEthToToken = uint(10)**(18);
        buyRatio = 10 * (uint(10)**decimals);  
        sellRatio = 20 * (uint(10)**decimals);  
        isRatio = true;  
        balances[0] = _totalSupply - undergroundBunkerReserves;
        balances[msg.sender] = undergroundBunkerReserves;
         
         
        emit Transfer(address(0), msg.sender, undergroundBunkerReserves);
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  ;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transferInt(address from, address to, uint tokens, bool updateTasters) internal returns (bool success) {
        if(updateTasters) {
             
            if(tastersReceived[from] > 0) {
                uint tasterTokens = min(tokens, tastersReceived[from]);
                tastersReceived[from] = safeSub(tastersReceived[from], tasterTokens);
                if(to != address(0)) {
                    tastersReceived[to] = safeAdd(tastersReceived[to], tasterTokens);
                }
            }
        }
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        return transferInt(msg.sender, to, tokens, true);
    }
    
     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
         
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        return transferInt(from, to, tokens, true);
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant whenNotPaused returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function calculateTokensFromWei(uint weiValue, uint ratio) public view returns (uint numTokens) {
        uint calc1 = safeMul(weiValue, ratio);
        uint ethValue = calc1 / _factorDecimalsEthToToken;
        return ethValue;
    }

     
     
     
    function calculateEthValueFromTokens(uint numTokens, uint ratio) public view returns (uint weiValue) {
        uint calc1 = safeMul(numTokens, _factorDecimalsEthToToken);
        uint retValue = calc1 / ratio;
        return retValue;
    }
    
     
     
     
     
    function buyCoke() public payable returns (bool success) {
         
        uint numTokensToBuy = calculateTokensFromWei(msg.value, buyRatio);
        uint finalNumTokensToBuy = numTokensToBuy;
        if(numTokensToBuy > balances[0]) {
             
            finalNumTokensToBuy = balances[0];
             
             
            uint ethValueFromTokens = calculateEthValueFromTokens(numTokensToBuy - finalNumTokensToBuy, buyRatio);  
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], ethValueFromTokens );
            emit ChangeToReceiveGotten(msg.sender, ethValueFromTokens, changeToReturn[msg.sender]);
        }
        if(finalNumTokensToBuy <= balances[0]) {
             
            transferInt(address(0), msg.sender, finalNumTokensToBuy, false);
            return true;
        }
        else return false;
    }
    
     
     
     
    function checkChangeToReceive() public view returns (uint changeInWei) {
        return changeToReturn[msg.sender];
    }

     
     
     
    function checkGainsToReceive() public view returns (uint gainsInWei) {
        return gainsToReceive[msg.sender];
    }

     
     
     
     
    function retrieveChange() public noReentrancy whenNotInEmergencyProtectedMode returns (bool success) {
        uint change = changeToReturn[msg.sender];
        if(change > 0) {
             
            changeToReturn[msg.sender] = 0;
             
            msg.sender.transfer(change);
            return true;
        }
        else return false;
    }

     
     
     
     
    function retrieveGains() public noReentrancy whenNotInEmergencyProtectedMode returns (bool success) {
        uint gains = gainsToReceive[msg.sender];
        if(gains > 0) {
             
            gainsToReceive[msg.sender] = 0;
             
            msg.sender.transfer(gains);
            return true;
        }
        else return false;
    }

     
     
     
     
    function returnCoke(uint ugToReturn) public noReentrancy whenNotPaused whenNotFlushing returns (bool success) {
         
         
         
         
        uint finalUgToReturnForEth = min(ugToReturn, safeSub(balances[msg.sender], tastersReceived[msg.sender]));  
         
         
        uint ethToReturn = calculateEthValueFromTokens(finalUgToReturnForEth, sellRatio);  
        
        if(ethToReturn > 0) {
             
             
            transfer(address(0), finalUgToReturnForEth);
             
            
             
            msg.sender.transfer(ethToReturn);
            return true;
        }
        else return false;
    }

     
     
     
    function returnAllCoke() public returns (bool success) {
        return returnCoke(safeSub(balances[msg.sender], tastersReceived[msg.sender]));
    }

     
     
     
     
    function sendSpecialTasterPackage(address addr, uint ugToTaste) public whenNotPaused onlyOwner returns (bool success) {
        tastersReceived[addr] = safeAdd(tastersReceived[addr], ugToTaste);
        transfer(addr, ugToTaste);
        return true;
    }

     
     
     
     
    function sendShipmentTo(address to, uint tokens) public returns (bool success) {
        return transfer(to, tokens);
    }

     
     
     
     
    function sendTaster(address to) public returns (bool success) {
         
        return transfer(to, 2);
    }

    function lengthAddresses() internal view returns (uint) {
        return (firstAddress > 0) ? lastAddresses.length : uint(lastAddress + 1);
    }

     
     
     
     
     
    function letItRain(uint8 range, uint quantity) public returns (bool success) {
        require(quantity <= balances[msg.sender]);
        if(lengthAddresses() == 0) {
            emit NoAddressesAvailable();
            return false;
        }
        bytes32 hashBlock100 = block.blockhash(100);  
        bytes32 randomHash = keccak256(keccak256(hashBlock100));  
        byte posAddr = randomHash[1];  
        byte howMany = randomHash[30];  
        
        uint8 posInt = (uint8(posAddr) + range * 2) % uint8(lengthAddresses());  
        uint8 howManyInt = uint8(howMany) % uint8(lengthAddresses());  
        howManyInt = howManyInt > 10 ? 10 : howManyInt;  
        howManyInt = howManyInt < 2 ? 2 : howManyInt;  
        
        address addr;
        
        uint8 counter = 0;
        uint quant = quantity / howManyInt;
        
        do {
            
             
            addr = lastAddresses[posInt];
            transfer(addr, quant);
            
            posInt = (uint8(randomHash[1 + counter]) + range * 2) % uint8(lengthAddresses());
            
            counter++;
            
             
             
        }
        while(quantity > 0 && counter < howManyInt);
        
        return true;
    }

     
     
     
     
    function setAddressesForRain(address[] memory addresses) public onlyOwner returns (bool success) {
        require(addresses.length <= uint(maxAddresses) && addresses.length > 0);
        lastAddresses = addresses;
        firstAddress = 0;
        lastAddress = int32(addresses.length) - 1;
        return true;
    }

     
     
     
    function getMaxAddresses() public view returns (int32) {
        return maxAddresses;
    }

     
     
     
    function setMaxAddresses(int32 _maxAddresses) public onlyOwner returns (bool success) {
        require(_maxAddresses > 0 && _maxAddresses < 256);
        maxAddresses = _maxAddresses;
        return true;
    }

     
     
     
    function getBuyRatio() public view returns (uint) {
        return buyRatio;
    }

     
     
     
    function setBuyRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        buyRatio = ratio;
        return true;
    }

     
     
     
    function getSellRatio() public view returns (uint) {
        return sellRatio;
    }

     
     
     
    function setSellRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        sellRatio = ratio;
        return true;
    }

     
     
     
    function setDirectOffersComissionRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        directOffersComissionRatio = ratio;
        return true;
    }

     
     
     
    function getDirectOffersComissionRatio() public view returns (uint) {
        return directOffersComissionRatio;
    }

     
     
     
    function setMarketComissionRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        marketComissionRatio = ratio;
        return true;
    }

     
     
     
    function getMarketComissionRatio() public view returns (uint) {
        return marketComissionRatio;
    }

     
     
     
    function setMaxMarketOffers(int32 _maxMarketOffers) public onlyOwner returns (bool success) {
        uint blackMarketOffersSortedSize = blackMarketOffersSorted.sizeOf();
        if(blackMarketOffersSortedSize > uint(_maxMarketOffers)) {
            int32 diff = int32(blackMarketOffersSortedSize - uint(_maxMarketOffers));
             
            require(diff <= int32(blackMarketOffersSortedSize));  
             
            while  (diff > 0) {
                uint lastOrder = blackMarketOffersSorted.pop(PREV);  
                delete blackMarketOffersMap[lastOrder];
                diff--;
            }
        }
        
        maxMarketOffers = _maxMarketOffers;
         
        return true;
    }

     
     
     
    function calculateFactorFlushDifficulty(uint stash) internal pure returns (uint extraBlocks) {
        uint numBlocksToFlush = 10;
        uint16 factor;
        if(stash < 1000) {
            factor = 1;
        }
        else if(stash < 5000) {
            factor = 2;
        }
        else if(stash < 10000) {
            factor = 3;
        }
        else if(stash < 100000) {
            factor = 4;
        }
        else if(stash < 1000000) {
            factor = 5;
        }
        else if(stash < 10000000) {
            factor = 10;
        }
        else if(stash < 100000000) {
            factor = 50;
        }
        else if(stash < 1000000000) {
            factor = 500;
        }
        else {
            factor = 5000;
        }
        return numBlocksToFlush * factor;
    }

     
     
     
    function downTheDrainImmediate() internal returns (bool success) {
             
            toFlush[msg.sender] = 0;
             
            transfer(address(0), balances[msg.sender]);
            tastersReceived[msg.sender] = 0;
            emit Flushed(msg.sender);
            return true;
    }
    
     
     
     
    function downTheDrain() public whenNotPaused payable returns (bool success) {
        if(msg.value < 0.01 ether) {
             
            toFlush[msg.sender] = block.number + calculateFactorFlushDifficulty(balances[msg.sender]);
            return true;
        }
        else return downTheDrainImmediate();
    }

     
     
     
    function flush() public whenNotPaused returns (bool success) {
         
        if(block.number >= toFlush[msg.sender]) {
            return downTheDrainImmediate();
        }
        else return false;
    }
    
    
     
     
     
    function smallerPriceComparator(uint priceNew, uint nodeNext) internal view returns (bool success) {
         
         
        return priceNew > blackMarketOffersMap[nodeNext].price;  
    }
    
     
     
     
     
     
     
    function sellToBlackMarket(uint quantity, uint priceRatio) public whenNotPaused whenNotFlushing returns (bool success, uint numOrderCreated) {
         
         
        if(quantity > balances[msg.sender]) {
             
            emit OrderInsufficientBalance(msg.sender, quantity, balances[msg.sender]);
            return (false, 0);
        }

         

         
         
        uint nextSpot;
        bool foundPosition;
        uint sizeNow;
        (nextSpot, foundPosition, sizeNow) = blackMarketOffersSorted.getSortedSpotByFunction(HEAD, priceRatio, NEXT, smallerPriceComparator, maxMarketOffers);
        if(foundPosition) {
             
            uint newNodeNum = ++marketOfferCounter;  
            blackMarketOffersMap[newNodeNum].quantity = quantity;
            blackMarketOffersMap[newNodeNum].price = priceRatio;
            blackMarketOffersMap[newNodeNum].seller = msg.sender;
            
             
            blackMarketOffersSorted.insert(nextSpot, newNodeNum, PREV);
    
            if(int32(sizeNow) > maxMarketOffers) {
                 
                uint lastIndex = blackMarketOffersSorted.pop(PREV);  
                delete blackMarketOffersMap[lastIndex];
            }
            
            emit BlackMarketOfferAvailable(quantity, priceRatio);
            return (true, newNodeNum);
        }
        else {
            return (false, 0);
        }
    }
    
     
     
     
     
     
    function cancelSellToBlackMarket(uint quantity, uint priceRatio, bool continueAfterFirstMatch) public whenNotPaused returns (bool success, uint numOrdersCanceled) {
         
        bool exists;
        bool matchFound = false;
        uint offerNodeIndex;
        uint offerNodeIndexToProcess;
        (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(HEAD, NEXT);
        if(!exists)
            return (false, 0);  

        do {

            offerNodeIndexToProcess = offerNodeIndex;  
            (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(offerNodeIndex, NEXT);  
             
            if(   blackMarketOffersMap[offerNodeIndexToProcess].seller == msg.sender 
               && blackMarketOffersMap[offerNodeIndexToProcess].quantity == quantity
               && blackMarketOffersMap[offerNodeIndexToProcess].price == priceRatio) {
                    
                   blackMarketOffersSorted.remove(offerNodeIndexToProcess);
                   delete blackMarketOffersMap[offerNodeIndexToProcess];
                   matchFound = true;
                   numOrdersCanceled++;
                   success = true;
                    emit BlackMarketOfferCancelled(quantity, priceRatio);
            }
            else {
                matchFound = false;
            }
            
        }
        while(offerNodeIndex != NULL && exists && (!matchFound || continueAfterFirstMatch));
        
        return (success, numOrdersCanceled);
    }
    
    function calculateAndUpdateGains(SellOfferComplete offerThisRound) internal returns (uint) {
         
        uint weiToBePayed = calculateEthValueFromTokens(offerThisRound.quantity, offerThisRound.price);

         
        uint fee = safeDiv(weiToBePayed, marketComissionRatio);
        uint valueForSeller = safeSub(weiToBePayed, fee);

         
        gainsToReceive[offerThisRound.seller] = safeAdd(gainsToReceive[offerThisRound.seller], valueForSeller);
        emit GainsGotten(offerThisRound.seller, valueForSeller, gainsToReceive[offerThisRound.seller]);

        return weiToBePayed;
    }

    function matchOffer(uint quantity, uint nodeIndex, SellOfferComplete storage offer) internal returns (bool exists, uint offerNodeIndex, uint quantityRound, uint weiToBePayed, bool cleared) {
        uint quantityToCheck = min(quantity, offer.quantity);  
        SellOfferComplete memory offerThisRound = offer;
        bool forceRemovalOffer = false;

         
        if(balances[offerThisRound.seller] < quantityToCheck) {
             
            quantityToCheck = balances[offerThisRound.seller];

             
            forceRemovalOffer = true;
        }

        offerThisRound.quantity = quantityToCheck;

        if(offerThisRound.quantity > 0) {
             

             
            weiToBePayed = calculateAndUpdateGains(offerThisRound);

             
            offer.quantity = safeSub(offer.quantity, offerThisRound.quantity);
            
             
            emit BlackMarketOfferBought(offerThisRound.quantity, offerThisRound.price, offer.quantity);
            
             
             
            transferInt(offer.seller, msg.sender  , offerThisRound.quantity, true);
        }
        
         
        (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(nodeIndex, NEXT);
        
         
        if(forceRemovalOffer || offer.quantity == 0) {
             
             
            
             
            uint firstIndex = blackMarketOffersSorted.pop(NEXT);  
            delete blackMarketOffersMap[firstIndex];
            
            cleared = true;
        }
        
        quantityRound = offerThisRound.quantity;

        return (exists, offerNodeIndex, quantityRound, weiToBePayed, cleared);
    }

     
     
     
     
     
     
     
     
    function buyFromBlackMarket(uint quantity, uint priceRatioLimit) public payable whenNotPaused whenNotFlushing noReentrancy returns (bool success, bool partial, uint numOrdersCleared) {
        numOrdersCleared = 0;
        partial = false;

         
        bool exists;
        bool cleared = false;
        uint offerNodeIndex;
        (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(HEAD, NEXT);
        if(!exists) {
             
            revert();  
             
             
        }
        SellOfferComplete storage offer = blackMarketOffersMap[offerNodeIndex];
        
        uint totalToBePayedWei = 0;
        uint weiToBePayedRound = 0;
        uint quantityRound = 0;

         
         
        if(offer.price < priceRatioLimit) {
             
             
             
            revert();  
             
             
        }
        
        bool abort = false;
         
        do {
        
            (exists  , 
             offerNodeIndex,  
             quantityRound,  
             weiToBePayedRound,  
             cleared  
             ) = matchOffer(quantity, offerNodeIndex, offer);
            
            if(cleared) {
                numOrdersCleared++;
            }
    
             
            totalToBePayedWei = safeAdd(totalToBePayedWei, weiToBePayedRound);
    
             
            quantity = safeSub(quantity, quantityRound);
    
             
            if(totalToBePayedWei > msg.value) {
                emit OrderInsufficientPayment(msg.sender, totalToBePayedWei, msg.value);
                 
                revert();  
                 
                 
            }

             
            if(offerNodeIndex != NULL) {
    
                 
                offer = blackMarketOffersMap[offerNodeIndex];
    
                 
                 
                 
                if(offer.price < priceRatioLimit) {
                     
                    abort = true;
                    partial = true;  
                     
                     
                }
            }
            else {
                 
                abort = true;
            }
        }
        while (exists && quantity > 0 && !abort);
         

         
        if(totalToBePayedWei < msg.value) {
             
             
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value - totalToBePayedWei);  
            emit ChangeToReceiveGotten(msg.sender, msg.value - totalToBePayedWei, changeToReturn[msg.sender]);
        }

        return (true, partial, numOrdersCleared);
    }
    
     
     
     
    function getSellOrdersBlackMarket() public view returns (uint[] memory r) {
        r = new uint[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            uint size = blackMarketOffersSorted.sizeOf();
            for (uint i = 0; i < size; i++) {
              r[i] = elem;
              (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
    }
    
     
     
     
     
     
    function getSellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices) {
        quantities = new uint[](blackMarketOffersSorted.sizeOf());
        prices = new uint[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            uint size = blackMarketOffersSorted.sizeOf();
            for (uint i = 0; i < size; i++) {
                SellOfferComplete storage offer = blackMarketOffersMap[elem];
                quantities[i] = offer.quantity;
                prices[i] = offer.price;
                 
                (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
    }

    function getMySellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices) {
        quantities = new uint[](blackMarketOffersSorted.sizeOf());
        prices = new uint[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            uint size = blackMarketOffersSorted.sizeOf();
            uint j = 0;
            for (uint i = 0; i < size; i++) {
                SellOfferComplete storage offer = blackMarketOffersMap[elem];
                if(offer.seller == msg.sender) {
                    quantities[j] = offer.quantity;
                    prices[j] = offer.price;
                    j++;
                }
                 
                (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
         
         
    }

     
     
     
     
    function sellToConsumer(address consumer, uint quantity, uint priceRatio) public whenNotPaused whenNotFlushing returns (bool success) {
        require(consumer != address(0) && quantity > 0 && priceRatio > 0);
         
        SellOffer storage offer = directOffers[msg.sender][consumer];
        offer.quantity = quantity;
        offer.price = priceRatio;
        emit DirectOfferAvailable(msg.sender, consumer, offer.quantity, offer.price);
        return true;
    }
    
     
     
     
     
    function cancelSellToConsumer(address consumer) public whenNotPaused returns (bool success) {
         
        SellOffer memory sellOffer = directOffers[msg.sender][consumer];
        if(sellOffer.quantity > 0 || sellOffer.price > 0) {
             
            delete directOffers[msg.sender][consumer];
            emit DirectOfferCancelled(msg.sender, consumer, sellOffer.quantity, sellOffer.price);
            return true;
        }
        return false;
    }

     
     
     
     
    function checkMySellerOffer(address consumer) public view returns (uint quantity, uint priceRatio, uint totalWeiCost) {
        quantity = directOffers[msg.sender][consumer].quantity;
        priceRatio = directOffers[msg.sender][consumer].price;
        totalWeiCost = calculateEthValueFromTokens(quantity, priceRatio);  
    }

     
     
     
     
     
    function checkSellerOffer(address seller) public view returns (uint quantity, uint priceRatio, uint totalWeiCost) {
        quantity = directOffers[seller][msg.sender].quantity;
        priceRatio = directOffers[seller][msg.sender].price;
        totalWeiCost = calculateEthValueFromTokens(quantity, priceRatio);  
    }
    
     
     
     
     
     
     
     
    function buyFromTrusterDealer(address dealer, uint quantity, uint priceRatio) public payable noReentrancy whenNotPaused returns (bool success) {
         
        require(directOffers[dealer][msg.sender].quantity > 0 && directOffers[dealer][msg.sender].price > 0);  
        if(quantity > directOffers[dealer][msg.sender].quantity) {
            emit OrderQuantityMismatch(dealer, directOffers[dealer][msg.sender].quantity, quantity);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value);  
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        if(directOffers[dealer][msg.sender].price != priceRatio) {
            emit OrderPriceMismatch(dealer, directOffers[dealer][msg.sender].price, priceRatio);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value);  
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        
         
        
         
        uint weiToBePayed = calculateEthValueFromTokens(quantity, priceRatio);
        
         
        if(msg.value < weiToBePayed) {
            emit OrderInsufficientPayment(msg.sender, weiToBePayed, msg.value);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value);  
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        
         
        if(quantity > balances[dealer]) {
             
            emit OrderInsufficientBalance(dealer, quantity, balances[dealer]);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value);  
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        
         
        balances[dealer] = balances[dealer] - quantity;  
        balances[msg.sender] = safeAdd(balances[msg.sender], quantity);
        emit Transfer(dealer, msg.sender, quantity);

         
        if(quantity < directOffers[dealer][msg.sender].quantity) {
             
            directOffers[dealer][msg.sender].quantity = directOffers[dealer][msg.sender].quantity - quantity;
        }
        else {
             
            delete directOffers[dealer][msg.sender];
        }

         
         
        uint fee = safeDiv(weiToBePayed, directOffersComissionRatio);
        uint valueForSeller = safeSub(weiToBePayed, fee);
        
         
         
         
        dealer.transfer(valueForSeller);

         
        uint changeToGive = safeSub(msg.value, weiToBePayed);

        if(changeToGive > 0) {
             
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], changeToGive);
            emit ChangeToReceiveGotten(msg.sender, changeToGive, changeToReturn[msg.sender]);
        }

        return true;
    }
    
    /****************************************************************************
     
     

     
     
     
    function greaterPriceMsgComparator(uint valuePayedNew, uint nodeNext) internal view returns (bool success) {
        return valuePayedNew > (topMessagesMap[nodeNext].valuePayed);
    }
    
     
     
     
     
     
    function placeMessage(string message, bool anon) public payable whenNotPaused returns (bool success, uint numMsgTop) {
        uint msgSize = bytes(message).length;
        if(msgSize > maxCharactersMessage) {  
             
            emit ExceededMaximumMessageSize(msgSize, maxCharactersMessage);
            
            if(msg.value > 0) {  
                revert();  
            }
            return (false, 0);
        }

         
         

         
         
        uint nextSpot;
        bool foundPosition;
        uint sizeNow;
        (nextSpot, foundPosition, sizeNow) = topMessagesSorted.getSortedSpotByFunction(HEAD, msg.value, NEXT, greaterPriceMsgComparator, maxMessagesTop);
        if(foundPosition) {

             
            uint newNodeNum = ++topMessagesCounter;  
            topMessagesMap[newNodeNum].valuePayed = msg.value;
            topMessagesMap[newNodeNum].msg = message;
            topMessagesMap[newNodeNum].from = anon ? address(0) : msg.sender;
            
             
            topMessagesSorted.insert(nextSpot, newNodeNum, PREV);
    
            if(int32(sizeNow) > maxMessagesTop) {
                 
                uint lastIndex = topMessagesSorted.pop(PREV);  
                delete topMessagesMap[lastIndex];
            }
            
        }
        
         
        insertMessage(message, anon);

        emit NewMessageAvailable(anon ? address(0) : msg.sender, message);
        
        return (true, newNodeNum);
    }

    function lengthMessages() internal view returns (uint) {
        return (firstMsgGlobal > 0) ? messages.length : uint(lastMsgGlobal + 1);
    }

    function insertMessage(string message, bool anon) internal {
        Message memory newMsg;
        bool insertInLastPos = false;
        newMsg.valuePayed = msg.value;
        newMsg.msg = message;
        newMsg.from = anon ? address(0) : msg.sender;
        
        if(((lastMsgGlobal + 1) >= int32(messages.length) && int32(messages.length) < maxMessagesGlobal)) {
             
            messages.push(newMsg);
             
        } else {
             
            insertInLastPos = true; 
        }
        
         
        uint sizeMessages = lengthMessages();  
        lastMsgGlobal = (lastMsgGlobal + 1) % maxMessagesGlobal; 
        if(lastMsgGlobal <= firstMsgGlobal && sizeMessages > 0) {
            firstMsgGlobal = (firstMsgGlobal + 1) % maxMessagesGlobal;
        }
        
        if(insertInLastPos) {
            messages[uint(lastMsgGlobal)] = newMsg;
        }
    }
    
    function strConcat(string _a, string _b, string _c) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory ab = new string(_ba.length + _bb.length + _bc.length);
        bytes memory ba = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) ba[k++] = _bc[i];
        return string(ba);
    }

     
     
     
     
     
    function getMessages() public view returns (string memory r) {
        uint countMsg = lengthMessages();  
        uint indexMsg = uint(firstMsgGlobal);
        bool first = true;
        while(countMsg > 0) {
            if(first) {
                r = messages[indexMsg].msg;
                first = false;
            }
            else {
                r = strConcat(r, " <||> ", messages[indexMsg].msg);
            }
            
            indexMsg = (indexMsg + 1) % uint(maxMessagesGlobal);
            countMsg--;
        }

        return r;
    }

     
     
     
    function setMaxMessagesGlobal(int32 _maxMessagesGlobal) public onlyOwner returns (bool success) {
        if(_maxMessagesGlobal < maxMessagesGlobal) {
             
             
             
            lastMsgGlobal = int32(lengthMessages()) - 1;  
            if(lastMsgGlobal != -1 && lastMsgGlobal > (int32(_maxMessagesGlobal) - 1)) {
                lastMsgGlobal = int32(_maxMessagesGlobal) - 1;
            }
            firstMsgGlobal = 0;
            messages.length = uint(_maxMessagesGlobal);
        }
        maxMessagesGlobal = _maxMessagesGlobal;
        return true;
    }

     
     
     
    function setMaxMessagesTop(int32 _maxMessagesTop) public onlyOwner returns (bool success) {
        uint topMessagesSortedSize = topMessagesSorted.sizeOf();
        if(topMessagesSortedSize > uint(_maxMessagesTop)) {
            int32 diff = int32(topMessagesSortedSize - uint(_maxMessagesTop));
            require(diff <= int32(topMessagesSortedSize));  
             
            while  (diff > 0) {
                uint lastMsg = topMessagesSorted.pop(PREV);  
                delete topMessagesMap[lastMsg];
                diff--;
            }
        }
        
        maxMessagesTop = _maxMessagesTop;
        return true;
    }

     
     
     
    function getTop10Messages() public view returns (string memory r) {
        bool exists;
        uint prev;
        uint elem;
        bool first = true;
        (exists, prev, elem) = topMessagesSorted.getNode(HEAD);
        if(exists) {
            uint size = min(topMessagesSorted.sizeOf(), 10);
            for (uint i = 0; i < size; i++) {
                if(first) {
                    r = topMessagesMap[elem].msg;
                    first = false;
                }
                else {
                    r = strConcat(r, " <||> ", topMessagesMap[elem].msg);
                }
                (exists, elem) = topMessagesSorted.getAdjacent(elem, NEXT);
            }
        }
        
        return r;
    }
    
     
     
     
    function getTop11_20Messages() public view returns (string memory r) {
        bool exists;
        uint prev;
        uint elem;
        bool first = true;
        (exists, prev, elem) = topMessagesSorted.getNode(HEAD);
        if(exists) {
            uint size = min(topMessagesSorted.sizeOf(), uint(maxMessagesTop));
            for (uint i = 0; i < size; i++) {
                if(i >= 10) {
                    if(first) {
                        r = topMessagesMap[elem].msg;
                        first = false;
                    }
                    else {
                        r = strConcat(r, " <||> ", topMessagesMap[elem].msg);
                    }
                }
                (exists, elem) = topMessagesSorted.getAdjacent(elem, NEXT);
            }
        }
        
        return r;
    }
    
     
     
     
    function setMessageMaxCharacters(uint _maxCharactersMessage) public onlyOwner returns (bool success) {
        maxCharactersMessage = _maxCharactersMessage;
        return true;
    }

     
     
     
    function getMessageMaxCharacters() public view returns (uint maxChars) {
        return maxCharactersMessage;
    }

     
     
     
    function () public payable {
        buyCoke();
    }

}