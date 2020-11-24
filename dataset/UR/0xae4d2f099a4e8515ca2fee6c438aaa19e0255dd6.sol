 

pragma solidity ^0.5.2;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 
 
 
contract URACToken is PausableToken {
    using SafeMath for uint;

     
    string public constant name = "URACToken";
    string public constant symbol = "URAC";
    uint public constant decimals = 18;

     
    uint public currentSupply;

     
     
    address public minter;

     
    mapping (address => uint) public lockedBalances;

     
    bool public claimedFlag;

     
    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    modifier canClaimed {
        require(claimedFlag == true);
        _;
    }

    modifier maxTokenAmountNotReached (uint amount){
        require(currentSupply.add(amount) <= totalSupply);
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }

     
    constructor(address _minter, address _admin, uint _maxTotalSupply)
        public
        validAddress(_admin)
        validAddress(_minter)
        {
        minter = _minter;
        totalSupply = _maxTotalSupply;
        claimedFlag = false;
        transferOwnership(_admin);
    }

    function mintex(uint amount) public onlyOwner {
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
    }

     

    function mint(address receipent, uint amount, bool isLock)
        external
        onlyMinter
        maxTokenAmountNotReached(amount)
        returns (bool)
    {
        if (isLock ) {
            lockedBalances[receipent] = lockedBalances[receipent].add(amount);
        } else {
            balances[receipent] = balances[receipent].add(amount);
        }
        currentSupply = currentSupply.add(amount);
        return true;
    }


    function setClaimedFlag(bool flag)
        public
        onlyOwner
    {
        claimedFlag = flag;
    }

      

     
    function claimTokens(address[] calldata receipents)
        external
        canClaimed
    {
        for (uint i = 0; i < receipents.length; i++) {
            address receipent = receipents[i];
             
            balances[msg.sender] = balances[msg.sender].add(lockedBalances[receipent]);
            transfer(receipent, lockedBalances[receipent]);
            lockedBalances[receipent] = 0;
        }
    }
}

 

 
 
 
contract URACCrowdSale is Pausable {
    using SafeMath for uint;

     
     
    uint public constant URAC_TOTAL_SUPPLY = 3500000000 ether;
    uint public constant MAX_SALE_DURATION = 10 days;
    uint public constant STAGE_1_TIME =  3 days;
    uint public constant STAGE_2_TIME = 7 days;
    uint public constant MIN_LIMIT = 0.1 ether;
    uint public constant MAX_STAGE_1_LIMIT = 10 ether;

     
     
    enum STAGE {STAGE_1, STAGE_2}

     
    uint public  exchangeRate = 6200;


    uint public constant MINER_STAKE = 4000;     
    uint public constant OPEN_SALE_STAKE = 158;  
    uint public constant OTHER_STAKE = 5842;     


    uint public constant DIVISOR_STAKE = 10000;

     
    uint public constant MAX_OPEN_SOLD = URAC_TOTAL_SUPPLY * OPEN_SALE_STAKE / DIVISOR_STAKE;
    uint public constant STAKE_MULTIPLIER = URAC_TOTAL_SUPPLY / DIVISOR_STAKE;

     
    address payable public wallet;
    address payable public minerAddress;
    address payable public otherAddress;

     
    uint public startTime;
     
    uint public endTime;

     
     
    uint public openSoldTokens;
     
    URACToken public uracToken;

     
    mapping (address => bool) public fullWhiteList;

    mapping (address => uint) public firstStageFund;
 
     
    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event NewWallet(address onwer, address oldWallet, address newWallet);

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier ceilingNotReached() {
        require(openSoldTokens < MAX_OPEN_SOLD);
        _;
    }

    modifier isSaleEnded() {
        require(now > endTime || openSoldTokens >= MAX_OPEN_SOLD);
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }

    constructor (
        address payable _wallet,
        address payable _minerAddress,
        address payable _otherAddress
        ) public
        validAddress(_wallet)
        validAddress(_minerAddress)
        validAddress(_otherAddress)
        {
        paused = true;
        wallet = _wallet;
        minerAddress = _minerAddress;
        otherAddress = _otherAddress;

        openSoldTokens = 0;
         
        uracToken = new URACToken(address(this), msg.sender, URAC_TOTAL_SUPPLY);

        uracToken.mint(minerAddress, MINER_STAKE * STAKE_MULTIPLIER, false);
        uracToken.mint(otherAddress, OTHER_STAKE * STAKE_MULTIPLIER, false);
    }

    function setExchangeRate(uint256 rate)
        public
        onlyOwner
        earlierThan(endTime)
    {
        exchangeRate = rate;
    }

    function setStartTime(uint _startTime )
        public
        onlyOwner
    {
        startTime = _startTime;
        endTime = startTime + MAX_SALE_DURATION;
    }

     
     
    function setWhiteList(address[] calldata users, bool openTag)
        external
        onlyOwner
        earlierThan(endTime)
    {
        require(saleNotEnd());
        for (uint i = 0; i < users.length; i++) {
            fullWhiteList[users[i]] = openTag;
        }
    }


     
     
    function addWhiteList(address user, bool openTag)
        external
        onlyOwner
        earlierThan(endTime)
    {
        require(saleNotEnd());
        fullWhiteList[user] = openTag;

    }

     
    function setWallet(address payable newAddress)  external onlyOwner {
        emit NewWallet(owner, wallet, newAddress);
        wallet = newAddress;
    }

     
    function saleNotEnd() view internal returns (bool) {
        return now < endTime && openSoldTokens < MAX_OPEN_SOLD;
    }

     
    function ()external payable {
        buyURAC(msg.sender);
    }

     
     
     
    function buyURAC(address receipient)
        internal
        whenNotPaused
        ceilingNotReached
        notEarlierThan(startTime)
        earlierThan(endTime)
        validAddress(receipient)
        returns (bool)
    {
         
        require(!isContract(msg.sender));
        require(tx.gasprice <= 10000000000 wei);
        require(msg.value >= MIN_LIMIT);

        bool inWhiteListTag = fullWhiteList[receipient];
        require(inWhiteListTag == true);

        STAGE stage = STAGE.STAGE_2;
        if ( startTime <= now && now < startTime + STAGE_1_TIME ) {
            stage = STAGE.STAGE_1;
            require(msg.value <= MAX_STAGE_1_LIMIT);
            uint fund1 = firstStageFund[receipient];
            require (fund1 < MAX_STAGE_1_LIMIT );
        }

        doBuy(receipient, stage);

        return true;
    }


     
    function doBuy(address receipient, STAGE stage) internal {
         
        uint value = msg.value;

        if ( stage == STAGE.STAGE_1 ) {
            uint fund1 = firstStageFund[receipient];
            fund1 = fund1.add(value);
            if (fund1 > MAX_STAGE_1_LIMIT ) {
                uint refund1 = fund1.sub(MAX_STAGE_1_LIMIT);
                value = value.sub(refund1);
                msg.sender.transfer(refund1);
            }
        }

        uint tokenAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        require(tokenAvailable > 0);
        uint toFund;
        uint toCollect;
        (toFund, toCollect) = costAndBuyTokens(tokenAvailable, value);
        if (toFund > 0) {
            require(uracToken.mint(receipient, toCollect, true));
            wallet.transfer(toFund);
            openSoldTokens = openSoldTokens.add(toCollect);
            emit NewSale(receipient, toFund, toCollect);
        }

         
        uint toReturn = value.sub(toFund);
        if (toReturn > 0) {
            msg.sender.transfer(toReturn);
        }

        if ( stage == STAGE.STAGE_1 ) {
            firstStageFund[receipient] = firstStageFund[receipient].add(toFund);
        }
    }

     
    function costAndBuyTokens(uint availableToken, uint value) view internal returns (uint costValue, uint getTokens) {
         
        getTokens = exchangeRate * value;

        if (availableToken >= getTokens) {
            costValue = value;
        } else {
            costValue = availableToken / exchangeRate;
            getTokens = availableToken;
        }
    }

     
     
     
    function isContract(address payable _addr) view internal returns(bool) {
        uint size;
        if (_addr == 0x0000000000000000000000000000000000000000) {
            return false;
        }

        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}