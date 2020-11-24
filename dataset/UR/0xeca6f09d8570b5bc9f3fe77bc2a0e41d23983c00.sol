 

pragma solidity ^0.4.23;


 

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}




contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }



}

contract MSCE is Ownable, StandardToken, BurnableToken{
    using SafeMath for uint256;

    uint8 public constant TOKEN_DECIMALS = 18;

    string public name = "Mobile Ecosystem"; 
    string public symbol = "MSCE";
    uint8 public decimals = TOKEN_DECIMALS;


    uint256 public totalSupply = 500000000 *(10**uint256(TOKEN_DECIMALS)); 
    uint256 public soldSupply = 0; 
    uint256 public sellSupply = 0; 
    uint256 public buySupply = 0; 
    bool public stopSell = true;
    bool public stopBuy = false;

    uint256 public crowdsaleStartTime = block.timestamp;
    uint256 public crowdsaleEndTime = 1526831999;

    uint256 public crowdsaleTotal = 2000*40000*(10**18);


    uint256 public buyExchangeRate = 40000;   
    uint256 public sellExchangeRate = 100000;  
    address public ethFundDeposit;  


    bool public allowTransfers = true; 


    mapping (address => bool) public frozenAccount;

    bool public enableInternalLock = true;
    uint256 unitCount = 100; 
    uint256 unitTime = 1 days;
    uint256 lockTime = unitCount * unitTime;

    mapping (address => bool) public internalLockAccount;
    mapping (address => uint256) public releaseLockAccount;
    mapping (address => uint256) public lockAmount;
    mapping (address => uint256) public lockStartTime;
    mapping (address => uint256) public lockReleaseTime;

    event LockAmount(address _from, address _to, uint256 amount, uint256 releaseTime);
    event FrozenFunds(address target, bool frozen);
    event IncreaseSoldSaleSupply(uint256 _value);
    event DecreaseSoldSaleSupply(uint256 _value);

    function MSCE() public {
        balances[msg.sender] = totalSupply;
        ethFundDeposit = msg.sender;                      
        allowTransfers = true;
    }

    function _isUserInternalLock() internal view returns (bool) {

        return getAccountLockState(msg.sender);

    }

    function increaseSoldSaleSupply (uint256 _value) onlyOwner public {
        require (_value + soldSupply < totalSupply);
        soldSupply = soldSupply.add(_value);
        emit IncreaseSoldSaleSupply(_value);
    }

    function decreaseSoldSaleSupply (uint256 _value) onlyOwner public {
        require (soldSupply - _value > 0);
        soldSupply = soldSupply.sub(_value);
        emit DecreaseSoldSaleSupply(_value);
    }


    function setEthFundDeposit(address _ethFundDeposit) onlyOwner public {
        require(_ethFundDeposit != address(0));
        ethFundDeposit = _ethFundDeposit;
    }

    function transferETH() onlyOwner public {
        require(ethFundDeposit != address(0));
        require(this.balance != 0);
        require(ethFundDeposit.send(this.balance));
    }


    function setExchangeRate(uint256 _sellExchangeRate, uint256 _buyExchangeRate) onlyOwner public {
        sellExchangeRate = _sellExchangeRate;
        buyExchangeRate = _buyExchangeRate;
    }

    function setExchangeStatus(bool _stopSell, bool _stopBuy) onlyOwner public {
        stopSell = _stopSell;
        stopBuy = _stopBuy;
    }

    function setAllowTransfers(bool _allowTransfers) onlyOwner public {
        allowTransfers = _allowTransfers;
    }

    function setEnableInternalLock(bool _isEnable) onlyOwner public {
        enableInternalLock = _isEnable;
    }



    function getAccountUnlockTime(address _target) public view returns(uint256) {

        return releaseLockAccount[_target];

    }
    function getAccountLockState(address _target) public view returns(bool) {
        if(enableInternalLock && internalLockAccount[_target]){
            if((releaseLockAccount[_target] > 0)&&(releaseLockAccount[_target]<block.timestamp)){       
                return false;
            }          
            return true;
        }
        return false;

    }

    function setUnitTime(uint256 unit) external onlyOwner{
        unitTime = unit;
    }
    
    function isOwner() internal view returns(bool success) {
        if (msg.sender == owner) return true;
        return false;
    }
     
     
     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[_from]);                                         
            require(!frozenAccount[_to]);                                        
            require(!_isUserInternalLock());
        }
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[msg.sender]);                                       
            require(!frozenAccount[_to]);                                             
            require(!_isUserInternalLock());
            require(_value <= balances[msg.sender] - lockAmount[msg.sender] + releasedAmount(msg.sender));
        }
        if(_value >= releasedAmount(msg.sender)){
            lockAmount[msg.sender] = lockAmount[msg.sender].sub(releasedAmount(msg.sender));
        }else{
            lockAmount[msg.sender] = lockAmount[msg.sender].sub(_value);
        }
        
        return super.transfer(_to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[msg.sender]);                                         
            require(!frozenAccount[_spender]);                                        
            require(!_isUserInternalLock());
            require(_value <= balances[msg.sender] - lockAmount[msg.sender] + releasedAmount(msg.sender));
        }
        if(_value >= releasedAmount(msg.sender)){
            lockAmount[msg.sender] = lockAmount[msg.sender].sub(releasedAmount(msg.sender));
        }else{
            lockAmount[msg.sender] = lockAmount[msg.sender].sub(_value);
        }
        return super.approve(_spender, _value);
    }

    function transferFromAdmin(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function () internal payable{

        uint256 currentTime = block.timestamp;
        require((currentTime>crowdsaleStartTime)&&(currentTime<crowdsaleEndTime));
        require(crowdsaleTotal>0);

        require(buy());

        crowdsaleTotal = crowdsaleTotal.sub(msg.value.mul(buyExchangeRate));

    }

    function buy() payable public returns (bool){


        uint256 amount = msg.value.mul(buyExchangeRate);

        require(!stopBuy);
        require(amount <= balances[owner]);

        balances[owner] = balances[owner].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        soldSupply = soldSupply.add(amount);
        buySupply = buySupply.add(amount);

        Transfer(owner, msg.sender, amount);
        return true;
    }

    function sell(uint256 amount) public {
        uint256 ethAmount = amount.div(sellExchangeRate);
        require(!stopSell);
        require(this.balance >= ethAmount);      
        require(ethAmount >= 1);      

        require(balances[msg.sender] >= amount);                 
        require(balances[owner] + amount > balances[owner]);       
        require(!frozenAccount[msg.sender]);                       
        require(!_isUserInternalLock());                                          

        balances[owner] = balances[owner].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        soldSupply = soldSupply.sub(amount);
        sellSupply = sellSupply.add(amount);

        Transfer(msg.sender, owner, amount);

        msg.sender.transfer(ethAmount); 
    }

    function setCrowdsaleStartTime(uint256 _crowdsaleStartTime) onlyOwner public {
        crowdsaleStartTime = _crowdsaleStartTime;
    }

    function setCrowdsaleEndTime(uint256 _crowdsaleEndTime) onlyOwner public {
        crowdsaleEndTime = _crowdsaleEndTime;
    }
   

    function setCrowdsaleTotal(uint256 _crowdsaleTotal) onlyOwner public {
        crowdsaleTotal = _crowdsaleTotal;
    }

     
     
     
    function transferLockAmount(address _to, uint256 _value) public{
         
        require(balances[msg.sender] >= _value, "Not enough MSCE");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        lockAmount[_to] = lockAmount[_to].add(_value);
        _resetReleaseTime(_to);
        emit Transfer(msg.sender, _to, _value);
        emit LockAmount(msg.sender, _to, _value, uint256(now + lockTime));
    }

    function _resetReleaseTime(address _target) internal {
        lockStartTime[_target] = uint256(now);
        lockReleaseTime[_target] = uint256(now + lockTime);
    }

    function releasedAmount(address _target) public view returns (uint256) {
        if(now >= lockReleaseTime[_target]){
            return lockAmount[_target];
        }
        else{
            return (now - lockStartTime[_target]).div(unitTime).mul(lockAmount[_target]).div(100);
        }
    }
    
}


contract MSCEVote is MSCE {
     
    uint256 votingRight = 10000;
    uint256 dealTime = 3 days;
    
     
    struct Vote{
        bool isActivated;
        bytes32 name;
        address target;
        address spender;
        uint256 targetAmount;
        bool freeze;
        string newName;
        string newSymbol;
        uint256 agreeSupply;
        uint256 disagreeSupply;
        uint256 startTime;
        uint256 endTime;
        uint256 releaseTime;
    }
 
    Vote[] public votes;

    mapping (uint256 => address) public voteToOwner;
    mapping (address => bool) public frozenAccount;

    event NewVote(address _initiator, bytes32 name, address target, uint256 targetAmount);

    modifier onlySuperNode() {
        require(balances[msg.sender] >= 5000000*(10**18), "Just for SuperNodes");
        _;
    }

    modifier onlyVotingRight() {
        require(balances[msg.sender] >= votingRight*(10**18), "You haven't voting right.");
        _;
    }    

    function createVote(bytes32 _name, address _target, address _spender,uint256 _targetAmount, bool _freeze, string _newName, string _newSymbol, uint256 _releaseTime) onlySuperNode public {
        uint256 id = votes.push(Vote(true, _name,  _target, _spender,_targetAmount, _freeze, _newName, _newSymbol, 0, 0, uint256(now), uint256(now + dealTime), _releaseTime)) - 1;
        voteToOwner[id] = msg.sender;
        emit NewVote(msg.sender, _name, _target, _targetAmount);
    }

    function mintToken(address target, uint256 mintedAmount) onlySuperNode public {
        createVote("MINT", target, target, mintedAmount, false, "", "", 0);
    }

    function destroyToken(address target, uint256 amount) onlySuperNode public {
        createVote("DESTROY", target, target, amount, false, "", "", 0);
    }

    function freezeAccount(address _target, bool freeze) onlySuperNode public {
        createVote("FREEZE", _target, _target, 0, freeze, "", "", 0);
    }

    function lockInternalAccount(address _target, bool _lock, uint256 _releaseTime) onlySuperNode public {
        require(_target != address(0));
        createVote("LOCK", _target, _target, 0, _lock, "", "", _releaseTime);
    }

    function setName(string _name) onlySuperNode public {
        createVote("CHANGENAME", msg.sender, msg.sender, 0, false, _name, "", 0);
        
    }

    function setSymbol(string _symbol) onlySuperNode public {
        createVote("CHANGESYMBOL", msg.sender, msg.sender, 0, false, "", _symbol, 0);
    }

    function transferFromAdmin(address _from, address _to, uint256 _value) onlySuperNode public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        createVote("TRANS",_from, _to, _value, false, "", "", 0);
        return true;
    }

     
     
     
    function getVote(uint _id) 
        public 
        view 
        returns (bool, bytes32, address, address, uint256, bool, string, string, uint256, uint256, uint256, uint256){
        Vote storage _vote = votes[_id];
        return(
            _vote.isActivated,
            _vote.name,
            _vote.target,
            _vote.spender,
            _vote.targetAmount,
            _vote.freeze,
            _vote.newName,
            _vote.newSymbol,
            _vote.agreeSupply,
            _vote.disagreeSupply,
            _vote.startTime,
            _vote.endTime
        );
    }

    function voteXId(uint256 _id, bool _agree) onlyVotingRight public{
        Vote storage vote = votes[_id];
        uint256 rate = 100;
        if(vote.name == "FREEZE")
        {
            rate = 30;
        }else if(vote.name == "DESTROY")
        {
            rate = 51;
        }
        else{
            rate = 80;
        }
        if(now > vote.endTime){
            vote.isActivated = false;
            votes[_id] = vote;
        }
        require(vote.isActivated == true, "The vote ended");
        if(_agree == true){
            vote.agreeSupply = vote.agreeSupply.add(balances[msg.sender]);
        }
        else{
            vote.disagreeSupply = vote.disagreeSupply.add(balances[msg.sender]);
        }

        if (vote.agreeSupply >= soldSupply * (rate/100)){
            executeVote(_id);
        }else if (vote.disagreeSupply >= soldSupply * ((100-rate)/100)) {
            vote.isActivated = false;
            votes[_id] = vote;
        }

    }

    function executeVote(uint256 _id)private{
        Vote storage vote = votes[_id];
        vote.isActivated = false;

        if(vote.name == "MINT"){
            balances[vote.target] = balances[vote.target].add(vote.targetAmount);
            totalSupply = totalSupply.add(vote.targetAmount);
            emit Transfer(0, this, vote.targetAmount);
            emit Transfer(this, vote.target, vote.targetAmount);
        }else if(vote.name == "DESTROY"){
            balances[vote.target] = balances[vote.target].sub(vote.targetAmount);
            totalSupply = totalSupply.sub(vote.targetAmount);
            emit Transfer(vote.target, this, vote.targetAmount);
            emit Transfer(this, 0, vote.targetAmount);
        }else if(vote.name == "CHANGENAME"){
            name = vote.newName;
        }else if(vote.name == "CHANGESYMBOL"){
            symbol = vote.newSymbol;
        }else if(vote.name == "FREEZE"){
            frozenAccount[vote.target] = vote.freeze;
            emit FrozenFunds(vote.target, vote.freeze);
        }else if(vote.name == "LOCK"){
            internalLockAccount[vote.target] = vote.freeze;
            releaseLockAccount[vote.target] = vote.endTime;
        }
        else if(vote.name == "TRANS"){
            balances[vote.target] = balances[vote.target].sub(vote.targetAmount);
            balances[vote.spender] = balances[vote.spender].add(vote.targetAmount);
            emit Transfer(vote.target, vote.spender, vote.targetAmount);
        }
        votes[_id] = vote;
    }

    
}