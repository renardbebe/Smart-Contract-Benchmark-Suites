 

pragma solidity ^0.4.21;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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

 

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
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

 

contract BitexToken is MintableToken, BurnableToken {
    using SafeERC20 for ERC20;

    string public constant name = "Bitex Coin";

    string public constant symbol = "XBX";

    uint8 public decimals = 18;

    bool public tradingStarted = false;

     
    mapping (address => bool) public transferable;

     
    modifier allowTransfer(address _spender) {

        require(tradingStarted || transferable[_spender]);
        _;
    }
     

    function modifyTransferableHash(address _spender, bool value) onlyOwner public {
        transferable[_spender] = value;
    }

     
    function startTrading() onlyOwner public {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) allowTransfer(msg.sender) public returns (bool){
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) allowTransfer(_from) public returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public allowTransfer(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public allowTransfer(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public allowTransfer(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

 

contract KnowYourCustomer is Ownable
{
     
     
     
    struct Contributor {
         
        bool cleared;

         
         
         
        uint16 contributor_get;

         
        address ref;

         
        uint16 affiliate_get;
    }


    mapping (address => Contributor) public whitelist;
     

     

    function setContributor(address _address, bool cleared, uint16 contributor_get, uint16 affiliate_get, address ref) onlyOwner public{

         
        require(contributor_get<10000);
        require(affiliate_get<10000);

        Contributor storage contributor = whitelist[_address];

        contributor.cleared = cleared;
        contributor.contributor_get = contributor_get;

        contributor.ref = ref;
        contributor.affiliate_get = affiliate_get;

    }

    function getContributor(address _address) view public returns (bool, uint16, address, uint16 ) {
        return (whitelist[_address].cleared, whitelist[_address].contributor_get, whitelist[_address].ref, whitelist[_address].affiliate_get);
    }

    function getClearance(address _address) view public returns (bool) {
        return whitelist[_address].cleared;
    }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime ;
    bool nonZeroPurchase = msg.value != 0 ;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal{
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
     
     
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

 

 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}

 

contract BitexTokenCrowdSale is Crowdsale, RefundableCrowdsale {
    using SafeMath for uint256;

     
    uint256 public numberOfPurchasers = 0;

     
    uint256 public maxTokenSupply = 0;

     
    uint256 public initialTokenAmount = 0;

     
    uint256 public minimumAmount = 0;

     
    bool public preICO;

     
    BitexToken public token;

     
    KnowYourCustomer public kyc;

     
    address public walletRemaining;

     
    address public pendingOwner;


    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 rate, address indexed referral, uint256 referredBonus );
    event TokenPurchaseAffiliate(address indexed ref, uint256 amount );

    function BitexTokenCrowdSale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        uint256 _minimumAmount,
        uint256 _maxTokenSupply,
        address _wallet,
        BitexToken _token,
        KnowYourCustomer _kyc,
        bool _preICO,
        address _walletRemaining,
        address _pendingOwner
    )
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet) public
    { 
        require(_minimumAmount >= 0);
        require(_maxTokenSupply > 0);
        require(_walletRemaining != address(0));

        minimumAmount = _minimumAmount;
        maxTokenSupply = _maxTokenSupply;

        preICO = _preICO;

        walletRemaining = _walletRemaining;
        pendingOwner = _pendingOwner;

        kyc = _kyc;
        token = _token;

         
         
         
         
        if (preICO)
        {
            initialTokenAmount = token.totalSupply();
        }
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return token;
    }


     
    function computeTokenWithBonus(uint256 weiAmount) public view returns(uint256) {
        uint256 tokens_ = 0;
        if (preICO)
        {
            if (weiAmount >= 50000 ether  ) {

                tokens_ = weiAmount.mul(34).div(100);

            }
            else if (weiAmount<50000 ether && weiAmount >= 10000 ether) {

                tokens_ = weiAmount.mul(26).div(100);

            } else if (weiAmount<10000 ether && weiAmount >= 5000 ether) {

                tokens_ = weiAmount.mul(20).div(100);

            } else if (weiAmount<5000 ether && weiAmount >= 1000 ether) {

                tokens_ = weiAmount.mul(16).div(100);
            }

        }else{
            if (weiAmount >= 50000 ether  ) {

                tokens_ = weiAmount.mul(17).div(100);

            }
            else if (weiAmount<50000 ether && weiAmount >= 10000 ether) {

                tokens_ = weiAmount.mul(13).div(100);

            } else if (weiAmount<10000 ether && weiAmount >= 5000 ether) {

                tokens_ = weiAmount.mul(10).div(100);

            } else if (weiAmount<5000 ether && weiAmount >= 1000 ether) {

                tokens_ = weiAmount.mul(8).div(100);
            }

        }

        return tokens_;
    }
     
     
     
    function claimRefund() public {

         
        uint256 tokenBalance = token.balanceOf(msg.sender);

         
        require(tokenBalance == 0);

         
        super.claimRefund();

    }

      
     
    function finalization() internal {

        if (!preICO)
        {
            uint256 remainingTokens = maxTokenSupply.sub(token.totalSupply());

             
             
             
            token.mint(walletRemaining, remainingTokens);

        }

          
        super.finalization();

        if (!preICO)
        {
             
            token.finishMinting();
        }

         
        token.transferOwnership(pendingOwner);

    }



     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

         
         
        bool cleared;
        uint16 contributor_get;
        address ref;
        uint16 affiliate_get;

        (cleared,contributor_get,ref,affiliate_get) = kyc.getContributor(beneficiary);

         
        require(cleared);

         
        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

          
        uint256 bonus = computeTokenWithBonus(tokens);

         
        uint256 contributorGet = tokens.mul(contributor_get).div(100*100);

         
        tokens = tokens.add(bonus);
        tokens = tokens.add(contributorGet);

         
         
         
        require((minted().add(tokens)) <= maxTokenSupply);


         
        token.mint(beneficiary, tokens);

         
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, rate, ref, contributorGet);

         
        weiRaised = weiRaised.add(weiAmount);
        numberOfPurchasers = numberOfPurchasers + 1;

        forwardFunds();

         
         
         
         
        bool refCleared;
        (refCleared) = kyc.getClearance(ref);
        if (refCleared && ref != beneficiary)
        {
             
            tokens = weiAmount.mul(rate);

             
            uint256 affiliateGet = tokens.mul(affiliate_get).div(100*100);

             
             
             
             
            if ( minted().add(affiliateGet) <= maxTokenSupply)

            {
                 
                token.mint(ref, affiliateGet);
                emit TokenPurchaseAffiliate(ref, tokens );
            }

        }
    }

     
     
    function validPurchase() internal view returns (bool) {

         
        bool minAmount = (msg.value >= minimumAmount);

         
        return super.validPurchase() && minAmount;
    }

    function minted() public view returns(uint256)
    {
        return token.totalSupply().sub(initialTokenAmount); 
    }

     
     
    function hasEnded() public view returns (bool) {
         
         
        return super.hasEnded() || (minted() >= maxTokenSupply);
    }

     
    function changeMinimumAmount(uint256 _minimumAmount) onlyOwner public {
        require(_minimumAmount > 0);

        minimumAmount = _minimumAmount;
    }

      
    function changeRate(uint256 _rate) onlyOwner public {
        require(_rate > 0);
        
        rate = _rate;
    }

     
    function changeDates(uint256 _startTime, uint256 _endTime) onlyOwner public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        startTime = _startTime;
        endTime = _endTime;
    }

    function modifyTransferableHash(address _spender, bool value) onlyOwner public {
        token.modifyTransferableHash(_spender,value);
    }

     
    function transferVault(address newOwner) onlyOwner public {
        vault.transferOwnership(newOwner);

    }
   
}

 

contract IcoController is Ownable {
     
     

     
     
     

     
    uint8 public statePhase = 0;

     
    address public pendingOwner;

     
    address public whiteListingAdmin;

     
    BitexToken public token;

     
    BitexTokenCrowdSale public preICO;

     
    BitexTokenCrowdSale public currentIco;

     
    KnowYourCustomer public kyc;

     
    bool public lastRound = false;

    address public walletRemaining;

     
    uint256 public maxTokenSupply = 0;

    uint256 public finalizePreIcoDate;
    uint256 public finalizeIcoDate;

     
    function InitIcoController(address _pendingOwner) onlyOwner public{
         
        pendingOwner = _pendingOwner;

        token = new BitexToken();
        kyc = new KnowYourCustomer();
    }

     
    function prepare(uint256 _maxTokenSupply,address _walletRemaining,address _whiteListingAdmin) onlyOwner public{
         
        require(statePhase == 0);

         
        require(owner == pendingOwner);

         
         

         
         

        maxTokenSupply = _maxTokenSupply;
        walletRemaining = _walletRemaining;

        whiteListingAdmin = _whiteListingAdmin;

        statePhase = 1;
    }

     
    function mint(uint256 tokens,address beneficiary) onlyOwner public{
         
        require(statePhase == 1);
         
         
         

         
         
        bool lessThanMaxSupply = (token.totalSupply() + tokens) <= maxTokenSupply;
        require(lessThanMaxSupply);

         
        token.mint(beneficiary, tokens);
    }

     
    function mintAndCreatePreIcoBitex(address _walletRemaining,address _teamWallet) onlyOwner public
    {
        prepare(300000000000000000000000000,_walletRemaining, 0xd68cE8BF133297C3C27cc582A9E5452F64F76E4b);

         
        mint(63000000000000000000000000,0xB52c45b43B5c2dC6928149C54A05bA3A91542060);

         
        mint(27000000000000000000000000,_teamWallet);

         
        createPreIco(1525791600,
                     1527606000,
                     1000,
                     1000000000000000000000,
                     100000000000000000,
                     30000000000000000000000000,
                     0x1eF0cAD0E9A12cf39494e7D40643985538E7e963);

         
        modifyTransferableHash(_walletRemaining,true);
        modifyTransferableHash(_teamWallet,true);
        modifyTransferableHash(0xB52c45b43B5c2dC6928149C54A05bA3A91542060,true);

    }
     
    function createPreIco(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        uint256 _minimumAmount,
        uint256 _maxTokenForThisRound,
        address _wallet
        ) onlyOwner public
    {
         
        require(statePhase<=1); 

         
        currentIco = new BitexTokenCrowdSale(
            _startTime,
            _endTime,
            _rate,
            _goal,
            _minimumAmount,
            _maxTokenForThisRound,
            _wallet,
            token,
            kyc,
            true,
            walletRemaining,
            address(this)
        );

         
        preICO = currentIco;

         
        token.transferOwnership(currentIco);

         
        statePhase = 2;
    }

     
    function createIco(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        uint256 _minimumAmount,
        address _wallet) onlyOwner public
    {
        require(statePhase==2);  

         
        currentIco = new BitexTokenCrowdSale(
            _startTime,
            _endTime,
            _rate,
            _goal,
            _minimumAmount,
            maxTokenSupply,
            _wallet,
            token,
            kyc,
            false,
            walletRemaining,
            pendingOwner  
        );

         
        token.transferOwnership(currentIco);

         
        statePhase = 3;
    }


    function finalizeIco() onlyOwner public
    {
        if (statePhase==2)
        {
            finalizePreIcoDate = now;
        }else{
            finalizeIcoDate = now;
        }
        currentIco.finalize();
    }
      
    function modifyTransferableHash(address _spender, bool value) onlyOwner public
    {
         
         

         
        if (statePhase<=1)
        {
            token.modifyTransferableHash(_spender,value);
       }else{
            
            
            
           currentIco.modifyTransferableHash(_spender, value);
        }

    }

     
    function changeMinimumAmount(uint256 _minimumAmount) onlyOwner public {
         
         
         

        currentIco.changeMinimumAmount(_minimumAmount);
    }

      
    function changeRate(uint256 _rate) onlyOwner public {
         
         
        currentIco.changeRate(_rate);
    }

     
    function changeDates(uint256 _startTime, uint256 _endTime) onlyOwner public {
         
         
        currentIco.changeDates(_startTime, _endTime);
    }

     
    function transferCrowdSale(bool preIco) onlyOwner public {
        if (preIco)
        {
            require(finalizePreIcoDate!=0);
            require(now>=(finalizePreIcoDate+30 days));
            preICO.transferOwnership(owner);
            kyc.transferOwnership(owner);
        }else{
            require(finalizeIcoDate!=0);
            require(now>=finalizeIcoDate+30 days);
            currentIco.transferOwnership(owner);
        }
    }

     
    function setContributor(address _address, bool cleared, uint16 contributor_get, uint16 affiliate_get, address ref) public{
        require(msg.sender == whiteListingAdmin);
         
         
        kyc.setContributor(_address, cleared, contributor_get, affiliate_get, ref);
    }
     
    function setWhiteListAdmin(address _address) onlyOwner public{
        whiteListingAdmin=_address;
    }

    
    function transferOwnerShipToPendingOwner() public {

         
        require(msg.sender == pendingOwner);

         
         

         
        emit OwnershipTransferred(owner, pendingOwner);

         
        owner = pendingOwner;

    }


}