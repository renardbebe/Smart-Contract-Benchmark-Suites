 

pragma solidity ^0.4.19;

 

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
     
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract Pausable is Ownable {
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

contract CelebsPartyGate is Claimable, Pausable {
  address public cfoAddress;
  
  function CelebsPartyGate() public {
    cfoAddress = msg.sender;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  function setCFO(address _newCFO) external onlyOwner {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract CelebsParty is CelebsPartyGate {
    using SafeMath for uint256;

    event AgentHired(uint256 identifier, address player, bool queued);
    event Birth(uint256 identifier, string name, address owner, bool queued);
    event CategoryCreated(uint256 indexed identifier, string name);
    event CelebrityBought(uint256 indexed identifier, address indexed oldOwner, address indexed newOwner, uint256 price);
    event CelebrityReleased(uint256 indexed identifier, address player);
    event FameAcquired(uint256 indexed identifier, address player, uint256 fame);
    event PriceUpdated(uint256 indexed identifier, uint256 price);
    event PrizeAwarded(address player, uint256 amount, string reason);
    event UsernameUpdated(address player, string username);

    struct Category {
        uint256 identifier;
        string name;
    }

    struct Celebrity {
        uint256 identifier;
        uint256[] categories;
        string name;
        uint256 price;
        address owner;
        bool isQueued;
        uint256 lastQueueBlock;
        address agent;
        uint256 agentAwe;
        uint256 famePerBlock;
        uint256 lastFameBlock;
    }

    mapping(uint256 => Category) public categories;
    mapping(uint256 => Celebrity) public celebrities;
    mapping(address => uint256) public fameBalance;
    mapping(address => string) public usernames;
    
    uint256 public categoryCount;
    uint256 public circulatingFame;
    uint256 public celebrityCount;
    uint256 public devBalance;
    uint256 public prizePool;

    uint256 public minRequiredBlockQueueTime;

    function CelebsParty() public {
        _initializeGame();
    }

    function acquireFame(uint256 _identifier) external {
        Celebrity storage celeb = celebrities[_identifier];
        address player = msg.sender;
        require(celeb.owner == player);
        uint256 acquiredFame = SafeMath.mul((block.number - celeb.lastFameBlock), celeb.famePerBlock);
        fameBalance[player] = SafeMath.add(fameBalance[player], acquiredFame);
        celeb.lastFameBlock = block.number;
         
        circulatingFame = SafeMath.add(circulatingFame, acquiredFame);
        FameAcquired(_identifier, player, acquiredFame);
    }

    function becomeAgent(uint256 _identifier, uint256 _agentAwe) public whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
        address newAgent = msg.sender;
        address oldAgent = celeb.agent;
        uint256 currentAgentAwe = celeb.agentAwe;
         
        require(oldAgent != newAgent);
         
        require(fameBalance[newAgent] >= _agentAwe);
         
        require(_agentAwe > celeb.agentAwe);
         
        if (celeb.isQueued) {
             
            celeb.lastQueueBlock = block.number;
             
            if(oldAgent != address(this)) {
                uint256 halfOriginalFame = SafeMath.div(currentAgentAwe, 2);
                circulatingFame = SafeMath.add(circulatingFame, halfOriginalFame);
                fameBalance[oldAgent] = SafeMath.add(fameBalance[oldAgent], halfOriginalFame);
            }
        }
         
        celeb.agent = newAgent;
         
        celeb.agentAwe = _agentAwe;
         
        circulatingFame = SafeMath.sub(circulatingFame, _agentAwe);
        fameBalance[newAgent] = SafeMath.sub(fameBalance[newAgent], _agentAwe);
        AgentHired(_identifier, newAgent, celeb.isQueued);
    }

    function buyCelebrity(uint256 _identifier) public payable whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
         
        require(!celeb.isQueued);
        address oldOwner = celeb.owner;
        uint256 salePrice = celeb.price;
        address newOwner = msg.sender;
         
        require(oldOwner != newOwner);
         
        require(msg.value >= salePrice);
        address agent = celeb.agent;
         
        uint256 generatedFame = uint256(SafeMath.mul((block.number - celeb.lastFameBlock), celeb.famePerBlock));
         
        uint256 payment = uint256(SafeMath.div(SafeMath.mul(salePrice, 91), 100));
         
        uint256 agentFee = uint256(SafeMath.div(SafeMath.mul(salePrice, 4), 100));
         
        uint256 devFee = uint256(SafeMath.div(SafeMath.mul(salePrice, 3), 100));
         
        uint256 prizeFee = uint256(SafeMath.div(SafeMath.mul(salePrice, 2), 100));
         
        uint256 purchaseExcess = SafeMath.sub(msg.value, salePrice);
        if (oldOwner != address(this)) {
             
            oldOwner.transfer(payment);
        } else {
             
            prizePool = SafeMath.add(prizePool, payment);
        }
        if (agent != address(this)) {
             
            agent.transfer(agentFee);
        }
         
        uint256 spoils = SafeMath.div(generatedFame, 2);
        circulatingFame = SafeMath.add(circulatingFame, spoils);
        fameBalance[newOwner] = SafeMath.add(fameBalance[newOwner], spoils);
         
        devBalance = SafeMath.add(devBalance, devFee);
         
        prizePool = SafeMath.add(prizePool, prizeFee);
         
        celeb.owner = newOwner;
         
        celeb.price = _nextPrice(salePrice);
         
        celeb.lastFameBlock = block.number;
         
         
        if(celeb.famePerBlock < 100) {
            celeb.famePerBlock = SafeMath.add(celeb.famePerBlock, 1);
        }
         
        CelebrityBought(_identifier, oldOwner, newOwner, salePrice);
         
        newOwner.transfer(purchaseExcess);
    }

    function createCategory(string _name) external onlyOwner {
        _mintCategory(_name);
    }

    function createCelebrity(string _name, address _owner, address _agent, uint256 _agentAwe, uint256 _price, bool _queued, uint256[] _categories) public onlyOwner {
        require(celebrities[celebrityCount].price == 0);
        address newOwner = _owner;
        address newAgent = _agent;
        if (newOwner == 0x0) {
            newOwner = address(this);
        }
        if (newAgent == 0x0) {
            newAgent = address(this);
        }
        uint256 newIdentifier = celebrityCount;
        Celebrity memory celeb = Celebrity({
            identifier: newIdentifier,
            owner: newOwner,
            price: _price,
            name: _name,
            famePerBlock: 0,
            lastQueueBlock: block.number,
            lastFameBlock: block.number,
            agent: newAgent,
            agentAwe: _agentAwe,
            isQueued: _queued,
            categories: _categories
        });
        celebrities[newIdentifier] = celeb;
        celebrityCount = SafeMath.add(celebrityCount, 1);
        Birth(newIdentifier, _name, _owner, _queued);
    }
    
    function getCelebrity(uint256 _identifier) external view returns
    (uint256 id, string name, uint256 price, uint256 nextPrice, address agent, uint256 agentAwe, address owner, uint256 fame, uint256 lastFameBlock, uint256[] cats, bool queued, uint256 lastQueueBlock)
    {
        Celebrity storage celeb = celebrities[_identifier];
        id = celeb.identifier;
        name = celeb.name;
        owner = celeb.owner;
        agent = celeb.agent;
        price = celeb.price;
        fame = celeb.famePerBlock;
        lastFameBlock = celeb.lastFameBlock;
        nextPrice = _nextPrice(price);
        cats = celeb.categories;
        agentAwe = celeb.agentAwe;
        queued = celeb.isQueued;
        lastQueueBlock = celeb.lastQueueBlock;
    }

    function getFameBalance(address _player) external view returns(uint256) {
        return fameBalance[_player];
    }

    function getUsername(address _player) external view returns(string) {
        return usernames[_player];
    }

    function releaseCelebrity(uint256 _identifier) public whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
        address player = msg.sender;
         
        require(block.number - celeb.lastQueueBlock >= minRequiredBlockQueueTime);
         
        require(celeb.isQueued);
         
        require(celeb.agent == player);
         
        celeb.isQueued = false;
        CelebrityReleased(_identifier, player);
    }

    function setCelebrityPrice(uint256 _identifier, uint256 _price) public whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
         
        require(msg.sender == celeb.owner);
         
        require(_price < celeb.price);
         
        celeb.price = _price;
        PriceUpdated(_identifier, _price);
    }

    function setRequiredBlockQueueTime(uint256 _blocks) external onlyOwner {
        minRequiredBlockQueueTime = _blocks;
    }

    function setUsername(address _player, string _username) public {
         
        require(_player == msg.sender);
         
        usernames[_player] = _username;
        UsernameUpdated(_player, _username);
    }

    function sendPrize(address _player, uint256 _amount, string _reason) external onlyOwner {
        uint256 newPrizePoolAmount = prizePool - _amount;
        require(prizePool >= _amount);
        require(newPrizePoolAmount >= 0);
        prizePool = newPrizePoolAmount;
        _player.transfer(_amount);
        PrizeAwarded(_player, _amount, _reason);
    }

    function withdrawDevBalance() external onlyOwner {
        require(devBalance > 0);
        uint256 withdrawAmount = devBalance;
        devBalance = 0;
        owner.transfer(withdrawAmount);
    }

     

    function _nextPrice(uint256 currentPrice) internal pure returns(uint256) {
        if (currentPrice < .1 ether) {
            return currentPrice.mul(200).div(100);
        } else if (currentPrice < 1 ether) {
            return currentPrice.mul(150).div(100);
        } else if (currentPrice < 10 ether) {
            return currentPrice.mul(130).div(100);
        } else {
            return currentPrice.mul(120).div(100);
        }
    }

    function _mintCategory(string _name) internal {
        uint256 newIdentifier = categoryCount;
        categories[newIdentifier] = Category(newIdentifier, _name);
        CategoryCreated(newIdentifier, _name);
        categoryCount = SafeMath.add(categoryCount, 1);
    }

    function _initializeGame() internal {
        categoryCount = 0;
        celebrityCount = 0;
        minRequiredBlockQueueTime = 1000;
        paused = true;
        _mintCategory("business");
        _mintCategory("film/tv");
        _mintCategory("music");
        _mintCategory("personality");
        _mintCategory("tech");
    }
}