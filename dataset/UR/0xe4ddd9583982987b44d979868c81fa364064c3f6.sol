 

pragma solidity 0.4.21;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    totalSupply_ = totalSupply_.add(_amount);
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

 

contract HVT is MintableToken, BurnableToken {
  using SafeMath for uint256;

  string public name = "HiVe Token";
  string public symbol = "HVT";
  uint8 public decimals = 18;

  enum State {Blocked,Burnable,Transferable}
  State public state = State.Blocked;

   
  function transfer(address _to, uint256 _value) public returns(bool) {
    require(state == State.Transferable);
    return super.transfer(_to,_value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
      require(state == State.Transferable);
      return super.transferFrom(_from,_to,_value);
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(state == State.Transferable);
    return super.approve(_spender,_value);
  }

  function burn(uint256 _value) public {
    require(state == State.Transferable || state == State.Burnable);
    super.burn(_value);
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(state == State.Transferable);
    super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(state == State.Transferable);
    super.decreaseApproval(_spender, _subtractedValue);
  }

   
  function enableTokenTransfers() public onlyOwner {
    state = State.Transferable;
  }

   
  function enableTokenBurn() public onlyOwner {
    state = State.Burnable;
  }

   
  function batchTransferDiff(address[] _to, uint256[] _amount) public {
    require(state == State.Transferable);
    require(_to.length == _amount.length);
    uint256 totalAmount = arraySum(_amount);
    require(totalAmount <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    for(uint i;i < _to.length;i++){
      balances[_to[i]] = balances[_to[i]].add(_amount[i]);
      Transfer(msg.sender,_to[i],_amount[i]);
    }
  }

   
  function batchTransferSame(address[] _to, uint256 _amount) public {
    require(state == State.Transferable);
    uint256 totalAmount = _amount.mul(_to.length);
    require(totalAmount <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    for(uint i;i < _to.length;i++){
      balances[_to[i]] = balances[_to[i]].add(_amount);
      Transfer(msg.sender,_to[i],_amount);
    }
  }

   
  function arraySum(uint256[] _amount) internal pure returns(uint256){
    uint256 totalAmount;
    for(uint i;i < _amount.length;i++){
      totalAmount = totalAmount.add(_amount[i]);
    }
    return totalAmount;
  }
}

 

contract ICOEngineInterface {

     
    function started() public view returns(bool);

     
    function ended() public view returns(bool);

     
    function startTime() public view returns(uint);

     
    function endTime() public view returns(uint);

     
     
     

     
     
     

     
    function totalTokens() public view returns(uint);

     
     
    function remainingTokens() public view returns(uint);

     
    function price() public view returns(uint);
}

 

 


 
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    function KYCBase(address [] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

     
    function releaseTokensTo(address buyer) internal returns(bool);

     
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
         
        bytes32 hash = sha256("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount);
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

     
    function () public {
        revert();
    }
}

 

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
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

 

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

 

 
contract HivePowerCrowdsale is Ownable, ICOEngineInterface, KYCBase {
    using SafeMath for uint;
    enum State {Running,Success,Failure}

    State public state;

    HVT public token;

    address public wallet;

     
    uint [] public prices;

     
    uint public startTime;

     
    uint public endTime;

     
    uint [] public caps;

     
    uint public remainingTokens;

     
    uint public totalTokens;

     
    uint public weiRaised;

     
    uint public goal;

     
    bool public isPreallocated;

     
    uint public companyTokens;

     
    uint public foundersTokens;

     
    RefundVault public vault;

     
    address [4] public timeLockAddresses;

     
    uint public stepLockedToken;

     
    uint public overshoot;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event SentBack(address indexed purchaser, uint256 amount);

     
    event FinalizedOK();

     
    event FinalizedNOK();

     
    event TimeLocked(address indexed timelock, uint256 amount, uint256 releaseTime, address indexed wallet);

     
    event Preallocated(address indexed to, uint256 amount);

     
    function HivePowerCrowdsale(address [] kycSigner, address _token, address _wallet, uint _startTime, uint _endTime, uint [] _prices, uint [] _caps, uint _goal, uint _companyTokens, uint _foundersTokens, uint _stepLockedToken, uint _overshoot)
        public
        KYCBase(kycSigner)
    {
        require(_token != address(0));
        require(_wallet != address(0));
        require(_startTime > now);
        require(_endTime > _startTime);
        require(_prices.length == _caps.length);

        for (uint256 i=0; i < _caps.length -1; i++)
        {
          require(_caps[i+1].sub(_caps[i]) > _overshoot.mul(_prices[i]));
        }

        token = HVT(_token);
        wallet = _wallet;
        startTime = _startTime;
        endTime = _endTime;
        prices = _prices;
        caps = _caps;
        totalTokens = _caps[_caps.length-1];
        remainingTokens = _caps[_caps.length-1];
        vault = new RefundVault(_wallet);
        goal = _goal;
        companyTokens = _companyTokens;
        foundersTokens = _foundersTokens;
        stepLockedToken = _stepLockedToken;
        overshoot = _overshoot;
        state = State.Running;
        isPreallocated = false;
    }

    function preallocate() onlyOwner public {
       
      require(!isPreallocated);

       
      uint numTimelocks = 4;
      uint amount = foundersTokens / numTimelocks;  
      uint256 releaseTime = endTime;
      for(uint256 i=0; i < numTimelocks; i++)
      {
         
        releaseTime = releaseTime.add(stepLockedToken);
         
        TokenTimelock timeLock = new TokenTimelock(token, wallet, releaseTime);
         
        timeLockAddresses[i] = address(timeLock);
         
        token.mint(address(timeLock), amount);
         
        TimeLocked(address(timeLock), amount, releaseTime, wallet);
      }

       
       
      token.mint(wallet, companyTokens);
      Preallocated(wallet, companyTokens);
       
      isPreallocated = true;
    }

     
    function releaseTokensTo(address buyer) internal returns(bool) {
         
        require(started());
         
        require(!ended());

        uint256 weiAmount = msg.value;
        uint256 weiBack = 0;
        uint currentPrice = price();
        uint currentCap = getCap();
        uint tokens = weiAmount.mul(currentPrice);
        uint tokenRaised = totalTokens - remainingTokens;

         
        if (tokenRaised.add(tokens) > currentCap)
        {
          tokens = currentCap.sub(tokenRaised);
          weiAmount = tokens.div(currentPrice);
          weiBack = msg.value - weiAmount;
        }
         

        weiRaised = weiRaised + weiAmount;
        remainingTokens = remainingTokens.sub(tokens);

         
        token.mint(buyer, tokens);
        forwardFunds(weiAmount);

        if (weiBack>0)
        {
          msg.sender.transfer(weiBack);
          SentBack(msg.sender, weiBack);
        }

        TokenPurchase(msg.sender, buyer, weiAmount, tokens);
        return true;
    }

    function forwardFunds(uint256 weiAmount) internal {
      vault.deposit.value(weiAmount)(msg.sender);
    }

     
    function finalize() onlyOwner public {
      require(state == State.Running);
      require(ended());

       
      if(weiRaised >= goal) {
         

         
        token.finishMinting();
         
        token.enableTokenTransfers();
         
        vault.close();

         
         
        state = State.Success;
        FinalizedOK();
      }
      else {
         
         
        finalizeNOK();
      }
    }

     
     function finalizeNOK() onlyOwner public {
        
       require(state == State.Running);
       require(ended());
        
       token.finishMinting();
        
       token.enableTokenBurn();
        
       vault.enableRefunds();
        
        
       state = State.Failure;
       FinalizedNOK();
     }

      
     function claimRefund() public {
       require(state == State.Failure);
       vault.refund(msg.sender);
    }

     
    function getCap() public view returns(uint){
      uint tokenRaised=totalTokens-remainingTokens;
      for (uint i=0;i<caps.length-1;i++){
        if (tokenRaised < caps[i])
        {
           
          uint tokenPerOvershoot = overshoot * prices[i];
          return(caps[i].add(tokenPerOvershoot));
        }
      }
       
      return(totalTokens);
    }

     
    function started() public view returns(bool) {
        return now >= startTime;
    }

     
    function ended() public view returns(bool) {
        return now >= endTime || remainingTokens == 0;
    }

    function startTime() public view returns(uint) {
      return(startTime);
    }

    function endTime() public view returns(uint){
      return(endTime);
    }

    function totalTokens() public view returns(uint){
      return(totalTokens);
    }

    function remainingTokens() public view returns(uint){
      return(remainingTokens);
    }

     
    function price() public view returns(uint){
      uint tokenRaised=totalTokens-remainingTokens;
      for (uint i=0;i<caps.length-1;i++){
        if (tokenRaised < caps[i])
        {
          return(prices[i]);
        }
      }
      return(prices[prices.length-1]);
    }

     
    function () public {
        revert();
    }

}

 

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}