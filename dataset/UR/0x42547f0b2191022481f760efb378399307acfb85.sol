 

pragma solidity ^0.4.18;

 
 
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
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

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract TradeableToken is StandardToken, Ownable {
    using SafeMath for uint256;

    event Sale(address indexed buyer, uint256 amount);
    event Redemption(address indexed seller, uint256 amount);
    event DistributionError(address seller, uint256 amount);

     
    enum State{Collecting, Distribution}

    State   public currentState;                 
    uint256 public previousPeriodRate;           
    uint256 public currentPeriodEndTimestamp;    
    uint256 public currentPeriodStartBlock;      

    uint256 public currentPeriodRate;            
    uint256 public currentPeriodEtherCollected;  
    uint256 public currentPeriodTokenCollected;  

    mapping(address => uint256) receivedEther;   
    mapping(address => uint256) soldTokens;      

    uint32 constant MILLI_PERCENT_DIVIDER = 100*1000;
    uint32 public buyFeeMilliPercent;            
    uint32 public sellFeeMilliPercent;           

    uint256 public minBuyAmount;                 
    uint256 public minSellAmount;                

    modifier canBuyAndSell() {
        require(currentState == State.Collecting);
        require(now < currentPeriodEndTimestamp);
        _;
    }

    function TradeableToken() public {
        currentState = State.Distribution;
         
        currentPeriodEndTimestamp = now;     
    }

     
    function() payable public {
        require(msg.value > 0);
        buy(msg.sender, msg.value);
    }    

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            return sell(msg.sender, _value);
        }else{
            return super.transfer(_to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            var _allowance = allowed[_from][msg.sender];
            require (_value <= _allowance);
            allowed[_from][msg.sender] = _allowance.sub(_value);
            return sell(_from, _value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

     
    function buy(address who, uint256 amount) canBuyAndSell internal returns(bool){
        require(amount >= minBuyAmount);
        currentPeriodEtherCollected = currentPeriodEtherCollected.add(amount);
        receivedEther[who] = receivedEther[who].add(amount);   
        Sale(who, amount);
        return true;
    }

     
    function sell(address who, uint256 amount) canBuyAndSell internal returns(bool){
        require(amount >= minSellAmount);
        currentPeriodTokenCollected = currentPeriodTokenCollected.add(amount);
        soldTokens[who] = soldTokens[who].add(amount);   
        totalSupply = totalSupply.sub(amount);
        Redemption(who, amount);
        Transfer(who, address(0), amount);
        return true;
    }
     
    function setBuyFee(uint32 _buyFeeMilliPercent) onlyOwner public {
        require(_buyFeeMilliPercent < MILLI_PERCENT_DIVIDER);
        buyFeeMilliPercent = _buyFeeMilliPercent;
    }
     
    function setSellFee(uint32 _sellFeeMilliPercent) onlyOwner public {
        require(_sellFeeMilliPercent < MILLI_PERCENT_DIVIDER);
        sellFeeMilliPercent = _sellFeeMilliPercent;
    }
     
    function setMinBuyAmount(uint256 _minBuyAmount) onlyOwner public {
        minBuyAmount = _minBuyAmount;
    }
     
    function setMinSellAmount(uint256 _minSellAmount) onlyOwner public {
        minSellAmount = _minSellAmount;
    }

     
    function collectEther(uint256 amount) onlyOwner public {
        owner.transfer(amount);
    }

     
    function startDistribution(uint256 _currentPeriodRate) onlyOwner public {
        require(currentState != State.Distribution);     
        require(_currentPeriodRate != 0);                 
         

        currentState = State.Distribution;
        currentPeriodRate = _currentPeriodRate;
    }

     
    function distributeTokens(address[] buyers) onlyOwner public {
        require(currentState == State.Distribution);
        require(currentPeriodRate > 0);
        for(uint256 i=0; i < buyers.length; i++){
            address buyer = buyers[i];
            require(buyer != address(0));
            uint256 etherAmount = receivedEther[buyer];
            if(etherAmount == 0) continue;  
            uint256 tokenAmount = etherAmount.mul(currentPeriodRate);
            uint256 fee = tokenAmount.mul(buyFeeMilliPercent).div(MILLI_PERCENT_DIVIDER);
            tokenAmount = tokenAmount.sub(fee);
            
            receivedEther[buyer] = 0;
            currentPeriodEtherCollected = currentPeriodEtherCollected.sub(etherAmount);
             
            totalSupply = totalSupply.add(tokenAmount);
            balances[buyer] = balances[buyer].add(tokenAmount);
            Transfer(address(0), buyer, tokenAmount);
        }
    }

     
    function distributeEther(address[] sellers) onlyOwner payable public {
        require(currentState == State.Distribution);
        require(currentPeriodRate > 0);
        for(uint256 i=0; i < sellers.length; i++){
            address seller = sellers[i];
            require(seller != address(0));
            uint256 tokenAmount = soldTokens[seller];
            if(tokenAmount == 0) continue;  
            uint256 etherAmount = tokenAmount.div(currentPeriodRate);
            uint256 fee = etherAmount.mul(sellFeeMilliPercent).div(MILLI_PERCENT_DIVIDER);
            etherAmount = etherAmount.sub(fee);
            
            soldTokens[seller] = 0;
            currentPeriodTokenCollected = currentPeriodTokenCollected.sub(tokenAmount);
            if(!seller.send(etherAmount)){
                 
                DistributionError(seller, etherAmount);
                owner.transfer(etherAmount);  
            }
        }
    }

    function startCollecting(uint256 _collectingEndTimestamp) onlyOwner public {
        require(_collectingEndTimestamp > now);       
        require(currentState == State.Distribution);     
        require(currentPeriodEtherCollected == 0);       
        require(currentPeriodTokenCollected == 0);       
        previousPeriodRate = currentPeriodRate;
        currentPeriodRate = 0;
        currentPeriodStartBlock = block.number;
        currentPeriodEndTimestamp = _collectingEndTimestamp;
        currentState = State.Collecting;
    }
}

contract UP1KToken is TradeableToken, MintableToken, HasNoContracts, HasNoTokens {  
    string public symbol = "UP1K";
    string public name = "UpStart 1000";
    uint8 public constant decimals = 18;

    address public founder;     
    function init(address _founder, uint32 _buyFeeMilliPercent, uint32 _sellFeeMilliPercent, uint256 _minBuyAmount, uint256 _minSellAmount) onlyOwner public {
        founder = _founder;
        setBuyFee(_buyFeeMilliPercent);
        setSellFee(_sellFeeMilliPercent);
        setMinBuyAmount(_minBuyAmount);
        setMinSellAmount(_minSellAmount);
    }

     
    modifier canTransfer() {
        require(mintingFinished || msg.sender == founder);
        _;
    }
    
    function transfer(address _to, uint256 _value) canTransfer public returns(bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract UP1KCrowdsale is Ownable, Destructible {
    using SafeMath for uint256;    

    uint256 public maxGasPrice  = 50000000000 wei;       

    uint256 public startTimestamp;      
    uint256 public endTimestamp;        
    uint256 public rate;                
    uint256 public hardCap;             

    UP1KToken public token;
    uint256 public collectedEther;

     
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice);
        _;
    }
     
    function UP1KCrowdsale(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _rate, uint256 _hardCap, 
        uint256 _ownerTokens, uint32 _buyFeeMilliPercent, uint32 _sellFeeMilliPercent, uint256 _minBuyAmount, uint256 _minSellAmount) public {
        require(_startTimestamp < _endTimestamp);
        require(_rate > 0);

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        rate = _rate;
        hardCap = _hardCap;

        token = new UP1KToken();
        token.init(msg.sender, _buyFeeMilliPercent, _sellFeeMilliPercent, _minBuyAmount, _minSellAmount);
        token.mint(msg.sender, _ownerTokens);
    }

    function () payable validGasPrice public {
        require(crowdsaleOpen());
        require(msg.value > 0);
        require(collectedEther.add(msg.value) <= hardCap);

        collectedEther = collectedEther.add(msg.value);
        uint256 buyerTokens = rate.mul(msg.value);
        token.mint(msg.sender, buyerTokens);
    }

    function crowdsaleOpen() public constant returns(bool){
        return (rate > 0) && (collectedEther < hardCap) && (startTimestamp <= now) && (now <= endTimestamp);
    }

     
    function setMaxGasPrice(uint256 _maxGasPrice) public onlyOwner  {
        maxGasPrice = _maxGasPrice;
    }

     
    function finalizeCrowdsale() public onlyOwner {
        rate = 0;    
        token.finishMinting();
        token.transferOwnership(owner);
        if(this.balance > 0) owner.transfer(this.balance);    
    }
     
    function claimEther() public onlyOwner {
        if(this.balance > 0) owner.transfer(this.balance);
    }

}