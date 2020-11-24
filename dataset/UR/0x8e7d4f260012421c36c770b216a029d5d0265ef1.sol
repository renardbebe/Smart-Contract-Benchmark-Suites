 

pragma solidity ^0.4.18;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
     OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
     OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}




 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
         OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


 
contract ERC20Basic {

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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


 

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(block.timestamp)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) public view returns (uint256) {
    return balanceOf(holder);
  }
}



 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;




   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
     Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
     Approval(msg.sender, _spender, _value);
    return true;
  }

   
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
     Transfer(_from, _to, _value);
    return true;
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
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




 
contract MintableToken is StandardToken, Claimable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
  public
  hasMintPermission
  canMint
  returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
     Mint(_to, _amount);
     Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
     MintFinished();
    return true;
  }
}

 
contract ISmartToken {

     
     
     

    bool public transfersEnabled = false;

     
     
     

     
    event NewSmartToken(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);

     
     
     

    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}


 
contract LimitedTransferBancorSmartToken is MintableToken, ISmartToken, LimitedTransferToken {

     
     
     

     
    modifier canDestroy() {
        require(destroyEnabled);
        _;
    }

     
     
     

     
     
     
    bool public destroyEnabled = false;

     
     
     

    function setDestroyEnabled(bool _enable) onlyOwner public {
        destroyEnabled = _enable;
    }

     
     
     

     
    function disableTransfers(bool _disable) onlyOwner public {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount) onlyOwner public {
        require(super.mint(_to, _amount));
         Issuance(_amount);
    }

     
    function destroy(address _from, uint256 _amount) canDestroy public {

        require(msg.sender == _from || msg.sender == owner);  

        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);

         Destruction(_amount);
         Transfer(_from, 0x0, _amount);
    }

     
     
     


     
     
     
     
     
     
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        require(transfersEnabled);
        return super.transferableTokens(holder, time);
    }
}




 
contract BitMEDSmartToken is LimitedTransferBancorSmartToken {

     
     
     

    string public constant name = "BitMED";

    string public constant symbol = "BXM";

    uint8 public constant decimals = 18;

     
     
     

    function BitMEDSmartToken() public {
         
         NewSmartToken(address(this));
    }
}


 
contract Vault is Claimable {
    using SafeMath for uint256;

     
     
     

    enum State { KycPending, KycComplete }

     
     
     
    mapping (address => uint256) public depositedETH;
    mapping (address => uint256) public depositedToken;

    BitMEDSmartToken public token;
    State public state;

     
     
     

    event KycPending();
    event KycComplete();
    event Deposit(address indexed beneficiary, uint256 etherWeiAmount, uint256 tokenWeiAmount);
    event RemoveSupporter(address beneficiary);
    event TokensClaimed(address indexed beneficiary, uint256 weiAmount);
     
     
     

    modifier isKycPending() {
        require(state == State.KycPending);
        _;
    }

    modifier isKycComplete() {
        require(state == State.KycComplete);
        _;
    }


     
     
     

    function Vault(BitMEDSmartToken _token) public {
        require(_token != address(0));

        token = _token;
        state = State.KycPending;
         KycPending();
    }

     
     
     

    function deposit(address supporter, uint256 tokensAmount, uint256 value) isKycPending onlyOwner public{

        depositedETH[supporter] = depositedETH[supporter].add(value);
        depositedToken[supporter] = depositedToken[supporter].add(tokensAmount);

         Deposit(supporter, value, tokensAmount);
    }

    function kycComplete() isKycPending onlyOwner public {
        state = State.KycComplete;
         KycComplete();
    }

     
    function removeSupporter(address supporter) isKycPending onlyOwner public {
        require(supporter != address(0));
        require(depositedETH[supporter] > 0);
        require(depositedToken[supporter] > 0);

        uint256 depositedTokenValue = depositedToken[supporter];
        uint256 depositedETHValue = depositedETH[supporter];

         
        depositedETH[supporter] = 0;
        depositedToken[supporter] = 0;

        token.destroy(address(this),depositedTokenValue);
         
         
         

         RemoveSupporter(supporter);
    }

     
     
    function claimTokens(uint256 tokensToClaim) isKycComplete public {
        require(tokensToClaim != 0);

        address supporter = msg.sender;
        require(depositedToken[supporter] > 0);

        uint256 depositedTokenValue = depositedToken[supporter];
        uint256 depositedETHValue = depositedETH[supporter];

        require(tokensToClaim <= depositedTokenValue);

        uint256 claimedETH = tokensToClaim.mul(depositedETHValue).div(depositedTokenValue);

        assert(claimedETH > 0);

        depositedETH[supporter] = depositedETHValue.sub(claimedETH);
        depositedToken[supporter] = depositedTokenValue.sub(tokensToClaim);

        token.transfer(supporter, tokensToClaim);

         TokensClaimed(supporter, tokensToClaim);
    }

     
     
    function claimAllSupporterTokensByOwner(address supporter) isKycComplete onlyOwner public {
        uint256 depositedTokenValue = depositedToken[supporter];
        require(depositedTokenValue > 0);
        token.transfer(supporter, depositedTokenValue);
         TokensClaimed(supporter, depositedTokenValue);
    }

     
     
    function claimAllTokens() isKycComplete public  {
        uint256 depositedTokenValue = depositedToken[msg.sender];
        claimTokens(depositedTokenValue);
    }


}


 
contract RefundVault is Claimable {
    using SafeMath for uint256;

     
     
     

    enum State { Active, Refunding, Closed }

     
     
     

     
    uint256 public constant REFUND_TIME_FRAME = 3 days;

    mapping (address => uint256) public depositedETH;
    mapping (address => uint256) public depositedToken;

    address public etherWallet;
    BitMEDSmartToken public token;
    State public state;
    uint256 public refundStartTime;

     
     
     

    event Active();
    event Closed();
    event Deposit(address indexed beneficiary, uint256 etherWeiAmount, uint256 tokenWeiAmount);
    event RefundsEnabled();
    event RefundedETH(address beneficiary, uint256 weiAmount);
    event TokensClaimed(address indexed beneficiary, uint256 weiAmount);

     
     
     

    modifier isActiveState() {
        require(state == State.Active);
        _;
    }

    modifier isRefundingState() {
        require(state == State.Refunding);
        _;
    }

    modifier isCloseState() {
        require(state == State.Closed);
        _;
    }

    modifier isRefundingOrCloseState() {
        require(state == State.Refunding || state == State.Closed);
        _;
    }

    modifier  isInRefundTimeFrame() {
        require(refundStartTime <= block.timestamp && refundStartTime + REFUND_TIME_FRAME > block.timestamp);
        _;
    }

    modifier isRefundTimeFrameExceeded() {
        require(refundStartTime + REFUND_TIME_FRAME < block.timestamp);
        _;
    }


     
     
     

    function RefundVault(address _etherWallet, BitMEDSmartToken _token) public {
        require(_etherWallet != address(0));
        require(_token != address(0));

        etherWallet = _etherWallet;
        token = _token;
        state = State.Active;
         Active();
    }

     
     
     

    function deposit(address supporter, uint256 tokensAmount) isActiveState onlyOwner public payable {

        depositedETH[supporter] = depositedETH[supporter].add(msg.value);
        depositedToken[supporter] = depositedToken[supporter].add(tokensAmount);

         Deposit(supporter, msg.value, tokensAmount);
    }

    function close() isRefundingState onlyOwner isRefundTimeFrameExceeded public {
        state = State.Closed;
         Closed();
        etherWallet.transfer(address(this).balance);
    }

    function enableRefunds() isActiveState onlyOwner public {
        state = State.Refunding;
        refundStartTime = block.timestamp;

         RefundsEnabled();
    }

     
    function refundETH(uint256 ETHToRefundAmountWei) isInRefundTimeFrame isRefundingState public {
        require(ETHToRefundAmountWei != 0);

        uint256 depositedTokenValue = depositedToken[msg.sender];
        uint256 depositedETHValue = depositedETH[msg.sender];

        require(ETHToRefundAmountWei <= depositedETHValue);

        uint256 refundTokens = ETHToRefundAmountWei.mul(depositedTokenValue).div(depositedETHValue);

        assert(refundTokens > 0);

        depositedETH[msg.sender] = depositedETHValue.sub(ETHToRefundAmountWei);
        depositedToken[msg.sender] = depositedTokenValue.sub(refundTokens);

        token.destroy(address(this),refundTokens);
        msg.sender.transfer(ETHToRefundAmountWei);

         RefundedETH(msg.sender, ETHToRefundAmountWei);
    }

     
     
    function claimTokens(uint256 tokensToClaim) isRefundingOrCloseState public {
        require(tokensToClaim != 0);

        address supporter = msg.sender;
        require(depositedToken[supporter] > 0);

        uint256 depositedTokenValue = depositedToken[supporter];
        uint256 depositedETHValue = depositedETH[supporter];

        require(tokensToClaim <= depositedTokenValue);

        uint256 claimedETH = tokensToClaim.mul(depositedETHValue).div(depositedTokenValue);

        assert(claimedETH > 0);

        depositedETH[supporter] = depositedETHValue.sub(claimedETH);
        depositedToken[supporter] = depositedTokenValue.sub(tokensToClaim);

        token.transfer(supporter, tokensToClaim);
        if(state != State.Closed) {
            etherWallet.transfer(claimedETH);
        }

         TokensClaimed(supporter, tokensToClaim);
    }

     
     
    function claimAllSupporterTokensByOwner(address supporter) isCloseState onlyOwner public {
        uint256 depositedTokenValue = depositedToken[supporter];
        require(depositedTokenValue > 0);


        token.transfer(supporter, depositedTokenValue);

         TokensClaimed(supporter, depositedTokenValue);
    }

     
     
    function claimAllTokens() isRefundingOrCloseState public  {
        uint256 depositedTokenValue = depositedToken[msg.sender];
        claimTokens(depositedTokenValue);
    }


}


 
contract Crowdsale {
    using SafeMath for uint256;

     
    BitMEDSmartToken public token;

     
    uint256 public startTime;

    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    Vault public vault;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, BitMEDSmartToken _token, Vault _vault) public {
        require(_startTime >= block.timestamp);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_vault != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = _token;
        vault = _vault;
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        require(weiAmount>500000000000000000);

         
        uint256 tokens = weiAmount.mul(getRate());

         
        weiRaised = weiRaised.add(weiAmount);

         
        token.issue(address(vault), tokens);

         
        vault.deposit(beneficiary, tokens, msg.value);

         TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

     
    function getRate() public view returns (uint256) {
        return rate;
    }
}


 
contract FinalizableCrowdsale is Crowdsale, Claimable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public onlyOwner  {
    require(!isFinalized);
    require(hasEnded());

    finalization();
     Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}



contract BitMEDCrowdsale is FinalizableCrowdsale {

     
     
     
     
     
     
     
     
     
     
    uint8 public constant MAX_TOKEN_GRANTEES = 10;

     
    uint256 public constant EXCHANGE_RATE = 210;

     
    uint256 public constant REFUND_DIVISION_RATE = 2;

     
    uint256 public constant MIN_TOKEN_SALE = 125000000000000000000000000;


     
     
     

     
    modifier onlyWhileSale() {
        require(isActive());
        _;
    }

     
     
     

     
    address public walletTeam;       
    address public walletReserve;    
    address public walletCommunity;  

     
    uint256 public fiatRaisedConvertedToWei;

     
    address[] public presaleGranteesMapKeys;
    mapping (address => uint256) public presaleGranteesMap;   

     
    RefundVault public refundVault;

     
     
     
    event GrantAdded(address indexed _grantee, uint256 _amount);

    event GrantUpdated(address indexed _grantee, uint256 _oldAmount, uint256 _newAmount);

    event GrantDeleted(address indexed _grantee, uint256 _hadAmount);

    event FiatRaisedUpdated(address indexed _address, uint256 _fiatRaised);

    event TokenPurchaseWithGuarantee(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
     
     

    function BitMEDCrowdsale(uint256 _startTime,
    uint256 _endTime,
    address _wallet,
    address _walletTeam,
    address _walletCommunity,
    address _walletReserve,
    BitMEDSmartToken _BitMEDSmartToken,
    RefundVault _refundVault,
    Vault _vault)

    public Crowdsale(_startTime, _endTime, EXCHANGE_RATE, _wallet, _BitMEDSmartToken, _vault) {
        require(_walletTeam != address(0));
        require(_walletCommunity != address(0));
        require(_walletReserve != address(0));
        require(_BitMEDSmartToken != address(0));
        require(_refundVault != address(0));
        require(_vault != address(0));

        walletTeam = _walletTeam;
        walletCommunity = _walletCommunity;
        walletReserve = _walletReserve;

        token = _BitMEDSmartToken;
        refundVault  = _refundVault;

        vault = _vault;

    }

     
     
     

     
     
    function getRate() public view returns (uint256) {
        if (block.timestamp < (startTime.add(24 hours))) {return 700;}
        if (block.timestamp < (startTime.add(3 days))) {return 600;}
        if (block.timestamp < (startTime.add(5 days))) {return 500;}
        if (block.timestamp < (startTime.add(7 days))) {return 400;}
        if (block.timestamp < (startTime.add(10 days))) {return 350;}
        if (block.timestamp < (startTime.add(13 days))) {return 300;}
        if (block.timestamp < (startTime.add(16 days))) {return 285;}
        if (block.timestamp < (startTime.add(19 days))) {return 270;}
        if (block.timestamp < (startTime.add(22 days))) {return 260;}
        if (block.timestamp < (startTime.add(25 days))) {return 250;}
        if (block.timestamp < (startTime.add(28 days))) {return 240;}
        if (block.timestamp < (startTime.add(31 days))) {return 230;}
        if (block.timestamp < (startTime.add(34 days))) {return 225;}
        if (block.timestamp < (startTime.add(37 days))) {return 220;}
        if (block.timestamp < (startTime.add(40 days))) {return 215;}

        return rate;
    }

     
     
     

     
    function finalization() internal {

        super.finalization();

         
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            token.issue(presaleGranteesMapKeys[i], presaleGranteesMap[presaleGranteesMapKeys[i]]);
        }

         
        if(token.totalSupply() <= MIN_TOKEN_SALE){
            uint256 missingTokens = MIN_TOKEN_SALE - token.totalSupply();
            token.issue(walletCommunity, missingTokens);
        }

         
         
        uint256 newTotalSupply = token.totalSupply().mul(400).div(100);

         
        token.issue(walletTeam, newTotalSupply.mul(10).div(100));

         
        token.issue(walletCommunity, newTotalSupply.mul(30).div(100));

         
         
        token.issue(walletReserve, newTotalSupply.mul(35).div(100));

         
        token.disableTransfers(false);

         
        token.setDestroyEnabled(true);

         
        refundVault.enableRefunds();

         
        token.transferOwnership(owner);

         
        refundVault.transferOwnership(owner);

        vault.transferOwnership(owner);

    }

     
     
     
     
    function getTotalFundsRaised() public view returns (uint256) {
        return fiatRaisedConvertedToWei.add(weiRaised);
    }

     
    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp < endTime;
    }

     
     
     
     
     
     
     
    function addUpdateGrantee(address _grantee, uint256 _value) external onlyOwner onlyWhileSale{
        require(_grantee != address(0));
        require(_value > 0);

         
        if (presaleGranteesMap[_grantee] == 0) {
            require(presaleGranteesMapKeys.length < MAX_TOKEN_GRANTEES);
            presaleGranteesMapKeys.push(_grantee);
            GrantAdded(_grantee, _value);
        }
        else {
            GrantUpdated(_grantee, presaleGranteesMap[_grantee], _value);
        }

        presaleGranteesMap[_grantee] = _value;
    }

     
     
    function deleteGrantee(address _grantee) external onlyOwner onlyWhileSale {
    require(_grantee != address(0));
        require(presaleGranteesMap[_grantee] != 0);

         
        delete presaleGranteesMap[_grantee];

         
        uint256 index;
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            if (presaleGranteesMapKeys[i] == _grantee) {
                index = i;
                break;
            }
        }
        presaleGranteesMapKeys[index] = presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        delete presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        presaleGranteesMapKeys.length--;

        GrantDeleted(_grantee, presaleGranteesMap[_grantee]);
    }

     
     
     
     
    function setFiatRaisedConvertedToWei(uint256 _fiatRaisedConvertedToWei) external onlyOwner onlyWhileSale {
        fiatRaisedConvertedToWei = _fiatRaisedConvertedToWei;
        FiatRaisedUpdated(msg.sender, fiatRaisedConvertedToWei);
    }

     
     
    function claimTokenOwnership() external onlyOwner {
        token.claimOwnership();
    }

     
     
    function claimRefundVaultOwnership() external onlyOwner {
        refundVault.claimOwnership();
    }

     
     
    function claimVaultOwnership() external onlyOwner {
        vault.claimOwnership();
    }

     
    function buyTokensWithGuarantee() public payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        require(weiAmount>500000000000000000);

         
        uint256 tokens = weiAmount.mul(getRate());
        tokens = tokens.div(REFUND_DIVISION_RATE);

         
        weiRaised = weiRaised.add(weiAmount);

        token.issue(address(refundVault), tokens);
        refundVault.deposit.value(msg.value)(msg.sender, tokens);

        TokenPurchaseWithGuarantee(msg.sender, address(refundVault), weiAmount, tokens);
    }
}