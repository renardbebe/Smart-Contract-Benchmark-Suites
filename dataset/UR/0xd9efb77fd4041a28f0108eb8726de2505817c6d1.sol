 

pragma solidity ^0.4.11;
 
contract ERC20 {
    function totalSupply() public constant returns (uint supply);
    function balanceOf( address who ) public constant returns (uint value);
    function allowance( address owner, address spender ) public constant returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}
 
contract YggdrashCrowd {
    using SafeMath for uint;
    ERC20 public yeedToken;
    Stages stage;
    address public wallet;
    address public owner;
    address public tokenOwner;
    uint public totalAmount;     
    uint public priceFactor;  
    uint public startBlock;
    uint public totalReceived;
    uint public endTime;

    uint public maxValue;  
    uint public minValue;

    uint public maxGasPrice;  

     
    event FundTransfer (address sender, uint amount);

    struct ContributeAddress {
        bool exists;  
        address account;  
        uint amount;  
        uint balance;  
        bytes data;  
    }

    mapping(address => ContributeAddress) public _contributeInfo;
    mapping(bytes => ContributeAddress) _contruibuteData;

     
    modifier isOwner() {
         
        require (msg.sender == owner);
        _;
    }

     
    modifier isValidPayload() {
         
        if(maxValue != 0){
            require(msg.value < maxValue + 1);
        }
         
        if(minValue != 0){
            require(msg.value > minValue - 1);
        }
        require(wallet != msg.sender);
         
        require(msg.data.length != 0);
        _;

    }

     
    modifier isExists() {
        require(_contruibuteData[msg.data].exists == false);
        require(_contributeInfo[msg.sender].amount == 0);
        _;
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }


     
    enum Stages {
    Deployed,
    SetUp,
    Started,
    Ended
    }


     
     
     
     
     
     
     
     

    function YggdrashCrowd(address _token, address _tokenOwner, address _wallet, uint _amount, uint _priceFactor, uint _maxValue, uint _minValue)
    public
    {
        require (_tokenOwner != 0 && _wallet != 0 && _amount != 0 && _priceFactor != 0);
        tokenOwner = _tokenOwner;
        owner = msg.sender;
        wallet = _wallet;
        totalAmount = _amount;
        priceFactor = _priceFactor;
        maxValue = _maxValue;
        minValue = _minValue;
        stage = Stages.Deployed;

        if(_token != 0){  
            yeedToken = ERC20(_token);
            stage = Stages.SetUp;
        }
         
        maxGasPrice = 0;
    }

     
    function setupToken(address _token)
    public
    isOwner
    {
        require(_token != 0);
        yeedToken = ERC20(_token);
        stage = Stages.SetUp;
    }

     
    function startContruibute()
    public
    isOwner
    atStage(Stages.SetUp)
    {
        stage = Stages.Started;
        startBlock = block.number;
    }


     
    function()
    public
    isValidPayload
    isExists
    atStage(Stages.Started)
    payable
    {
        uint amount = msg.value;
        uint maxAmount = totalAmount.div(priceFactor);
         
        if (amount > maxAmount){
            uint refund = amount.sub(maxAmount);
            assert(msg.sender.send(refund));
            amount = maxAmount;
        }
         
        if(maxGasPrice != 0){
            assert(tx.gasprice < maxGasPrice + 1);
        }
        totalReceived = totalReceived.add(amount);
         
        uint token = amount.mul(priceFactor);
        totalAmount = totalAmount.sub(token);

         
        yeedToken.transferFrom(tokenOwner, msg.sender, token);
        FundTransfer(msg.sender, token);

         
        ContributeAddress crowdData = _contributeInfo[msg.sender];
        crowdData.exists = true;
        crowdData.account = msg.sender;
        crowdData.data = msg.data;
        crowdData.amount = amount;
        crowdData.balance = token;
         
        _contruibuteData[msg.data] = crowdData;
        _contributeInfo[msg.sender] = crowdData;
         
        wallet.transfer(amount);

         
        if (amount == maxAmount)
            finalizeContruibute();
    }

     
     
     
     
     
    function changeSettings(uint _totalAmount, uint _priceFactor, uint _maxValue, uint _minValue, uint _maxGasPrice)
    public
    isOwner
    {
        require(_totalAmount != 0 && _priceFactor != 0);
        totalAmount = _totalAmount;
        priceFactor = _priceFactor;
        maxValue = _maxValue;
        minValue = _minValue;
        maxGasPrice = _maxGasPrice;
    }
     
    function setMaxGasPrice(uint _maxGasPrice)
    public
    isOwner
    {
        maxGasPrice = _maxGasPrice;
    }


     
     
    function balanceOf(address src) public constant returns (uint256)
    {
        return _contributeInfo[src].balance;
    }

     
     
    function amountOf(address src) public constant returns(uint256)
    {
        return _contributeInfo[src].amount;
    }

     
     
    function contruibuteData(bytes src) public constant returns(address)
    {
        return _contruibuteData[src].account;
    }

     
    function isContruibuteOpen() public constant returns (bool)
    {
        return stage == Stages.Started;
    }

     
    function halt()
    public
    isOwner
    {
        finalizeContruibute();
    }

     
    function finalizeContruibute()
    private
    {
        stage = Stages.Ended;
         
        totalAmount = 0;
        endTime = now;
    }
}