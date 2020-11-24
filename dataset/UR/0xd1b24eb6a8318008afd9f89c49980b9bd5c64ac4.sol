 

pragma solidity ^0.4.23;

 

 
interface ReinvestProxy {

     
    function reinvestFor(address customer) external payable;

}

 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
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

 

 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

 

 

contract P4RTYDaoVault is Whitelist {


     

     
    modifier onlyDivis {
        require(myDividends() > 0);
        _;
    }


     

    event onStake(
        address indexed customerAddress,
        uint256 stakedTokens,
        uint256 timestamp
    );

    event onDeposit(
        address indexed fundingSource,
        uint256 ethDeposited,
        uint    timestamp
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn,
        uint timestamp
    );

    event onReinvestmentProxy(
        address indexed customerAddress,
        address indexed destinationAddress,
        uint256 ethereumReinvested
    );




     


    uint256 constant internal magnitude = 2 ** 64;


     

     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;

     
    uint256 internal tokenSupply_ = 1;
    uint256 internal profitPerShare_;

    ERC20 public p4rty;


     

    constructor(address _p4rtyAddress) Ownable() public {

        p4rty = ERC20(_p4rtyAddress);

    }

     
    function() payable public {
        deposit();
    }

     
    function deposit() payable public  {

        uint256 _incomingEthereum = msg.value;
        address _fundingSource = msg.sender;

         
        profitPerShare_ += (_incomingEthereum * magnitude / tokenSupply_);


         
        emit onDeposit(_fundingSource, _incomingEthereum, now);

    }

    function stake(uint _amountOfTokens) public {


         
         

        address _customerAddress = msg.sender;

         
        require(p4rty.balanceOf(_customerAddress) > 0);



        uint256 _balance = p4rty.balanceOf(_customerAddress);
        uint256 _stakeAmount = Math.min256(_balance,_amountOfTokens);

        require(_stakeAmount > 0);
        p4rty.transferFrom(_customerAddress, address(this), _stakeAmount);

         
        tokenSupply_ = SafeMath.add(tokenSupply_, _stakeAmount);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _stakeAmount);

         
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _stakeAmount);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        emit onStake(_customerAddress, _amountOfTokens, now);
    }

     
    function withdraw() onlyDivis public {

        address _customerAddress = msg.sender;
         
        uint256 _dividends = dividendsOf(_customerAddress);

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);


         
        _customerAddress.transfer(_dividends);

         
        emit onWithdraw(_customerAddress, _dividends, now);
    }

    function reinvestByProxy(address _customerAddress) onlyWhitelisted public {
         
        uint256 _dividends = dividendsOf(_customerAddress);

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);


         
        ReinvestProxy reinvestProxy =  ReinvestProxy(msg.sender);
        reinvestProxy.reinvestFor.value(_dividends)(_customerAddress);

        emit onReinvestmentProxy(_customerAddress,msg.sender,_dividends);

    }


     

     
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

     
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
    function votingPower(address _customerAddress) public view returns (uint256) {
        return SafeMath.div(balanceOf(_customerAddress), totalSupply());
    }

     
    function myDividends() public view returns (uint256) {
        return dividendsOf(msg.sender);

    }

     
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

}

 

interface Bankroll {

     

     
    function credit(address _customerAddress, uint256 amount) external returns (uint256);

     
    function debit(address _customerAddress, uint256 amount) external returns (uint256);

     
    function withdraw(address _customerAddress) external returns (uint256);

     
    function balanceOf(address _customerAddress) external view returns (uint256);

     
    function statsOf(address _customerAddress) external view returns (uint256[8]);


     

     
    function deposit() external payable;

     
    function depositBy(address _customerAddress) external payable;

     
    function houseProfit(uint256 amount)  external;


     
    function netEthereumBalance() external view returns (uint256);


     
    function totalEthereumBalance() external view returns (uint256);

}

 

 

interface P4RTYRelay {
     
    function relay(address beneficiary, uint256 tokenAmount) external;
}

 

 
contract SessionQueue {

    mapping(uint256 => address) private queue;
    uint256 private first = 1;
    uint256 private last = 0;

     
    function enqueue(address data) internal {
        last += 1;
        queue[last] = data;
    }

     
    function available() internal view returns (bool) {
        return last >= first;
    }

     
    function depth() internal view returns (uint256) {
        return last - first + 1;
    }

     
    function dequeue() internal returns (address data) {
        require(last >= first);
         

        data = queue[first];

        delete queue[first];
        first += 1;
    }

     
    function peek() internal view returns (address data) {
        require(last >= first);
         

        data = queue[first];
    }
}

 

 






 

contract P6 is Whitelist, SessionQueue {


     

     
    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyDivis {
        require(myDividends(true) > 0);
        _;
    }

     
    modifier invested {
        require(stats[msg.sender].invested > 0, "Must buy tokens once to withdraw");

        _;

    }

     
    modifier cooledOff {
        require(msg.sender == owner && !contractIsLaunched || now - bot[msg.sender].coolOff > coolOffPeriod);
        _;
    }

     
    modifier teamPlayer {
        require(msg.sender == owner || now - lastReward[msg.sender] > rewardProcessingPeriod, "No spamming");
        _;
    }

     
    modifier launched {
        require(contractIsLaunched || msg.sender == owner, "Contract not lauched");
        _;
    }


     

    event onLog(
        string heading,
        address caller,
        address subj,
        uint val
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onCommunityReward(
        address indexed sourceAddress,
        address indexed destinationAddress,
        uint256 ethereumEarned
    );

    event onReinvestmentProxy(
        address indexed customerAddress,
        address indexed destinationAddress,
        uint256 ethereumReinvested
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    event onDeposit(
        address indexed customerAddress,
        uint256 ethereumDeposited
    );

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


     

     
    uint256  internal entryFee_ = 10;

     
    uint256  internal transferFee_ = 1;

     
    uint256  internal exitFee_ = 10;

     
     
     
    uint256  internal referralFee_ = 30;

     
    uint256  internal maintenanceFee_ = 20;
    address  internal maintenanceAddress;

     
    uint256 constant internal bankrollThreshold = 0.5 ether;
    uint256 constant internal botThreshold = 0.01 ether;
    uint256 constant rewardProcessingPeriod = 6 hours;
    uint256 constant reapPeriod = 7 days;
    uint256 public  maxProcessingCap = 10;

    uint256 public coolOffPeriod = 3 days;
    uint256 public launchETHMaximum = 20 ether;
    bool public contractIsLaunched = false;
    uint public lastReaped;


    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;

    uint256 constant internal magnitude = 2 ** 64;

     
    uint256 public stakingRequirement = 100e18;


     

     
    struct Bot {
        bool active;
        bool queued;
        uint256 lastBlock;
        uint256 coolOff;
    }

     
    struct Stats {
        uint invested;
        uint reinvested;
        uint withdrawn;
        uint rewarded;
        uint contributed;
        uint transferredTokens;
        uint receivedTokens;
        uint xInvested;
        uint xReinvested;
        uint xRewarded;
        uint xContributed;
        uint xWithdrawn;
        uint xTransferredTokens;
        uint xReceivedTokens;
    }


     
    mapping(address => uint256) internal lastReward;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => Bot) internal bot;
    mapping(address => Stats) internal stats;
     
    mapping(address => address) public referrals;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

    P4RTYRelay public relay;
    Bankroll public bankroll;
    bool internal bankrollEnabled = true;

     

    constructor(address relayAddress)  public {

        relay = P4RTYRelay(relayAddress);
        updateMaintenanceAddress(msg.sender);
    }

     

     
    function updateMaintenanceAddress(address maintenance) onlyOwner public {
        maintenanceAddress = maintenance;
    }

     
    function updateBankrollAddress(address bankrollAddress) onlyOwner public {
        bankroll = Bankroll(bankrollAddress);
    }

     
    function updateProcessingCap(uint cap) onlyOwner public {
        require(cap >= 5 && cap <= 15, "Capacity set outside of policy range");
        maxProcessingCap = cap;
    }

     
    function updateCoolOffPeriod(uint coolOff) onlyOwner public {
        require(coolOff >= 5 minutes && coolOff <= 3 days);
        coolOffPeriod = coolOff;
    }

     
    function launchContract() onlyOwner public {
        contractIsLaunched = true;
    }


     

     
    function activateBot(bool auto) public {
        bot[msg.sender].active = auto;

         
        if (bot[msg.sender].active) {
            if (!bot[msg.sender].queued) {
                bot[msg.sender].queued = true;
                enqueue(msg.sender);
            }
        }
    }

     
    function botEnabled() public view returns (bool){
        return bot[msg.sender].active;
    }


    function fundBankRoll(uint256 amount) internal {
        bankroll.deposit.value(amount)();
    }

     
    function buyFor(address _customerAddress) onlyWhitelisted public payable returns (uint256) {
        return purchaseTokens(_customerAddress, msg.value);
    }

     
    function buy() public payable returns (uint256) {
        if (contractIsLaunched){
             
            if(stats[msg.sender].invested == 0 && referralBalance_[msg.sender] > 0){
                reinvestFor(msg.sender);
            }
            return purchaseTokens(msg.sender, msg.value);
        }  else {
             
            return deposit();
        }
    }

    function deposit() internal returns (uint256) {
        require(msg.value > 0);

         
        referralBalance_[msg.sender] = SafeMath.add(referralBalance_[msg.sender], msg.value);

        require(referralBalance_[msg.sender] <= launchETHMaximum, "Exceeded investment cap");

        emit onDeposit(msg.sender, msg.value);

        return 0;

    }

     
    function() payable public {
        purchaseTokens(msg.sender, msg.value);
    }

     
    function reinvest() onlyDivis launched public {
        reinvestFor(msg.sender);
    }

     
    function investSupporter(address _customerAddress) public onlyOwner {
        require(!contractIsLaunched, "Contract already opened");
        reinvestFor(_customerAddress);
    }

     
    function reinvestFor(address _customerAddress) internal {

         
        uint256 _dividends = totalDividends(_customerAddress, false);
         

        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);

         
        emit onReinvestment(_customerAddress, _dividends, _tokens);

         
        stats[_customerAddress].reinvested = SafeMath.add(stats[_customerAddress].reinvested, _dividends);
        stats[_customerAddress].xReinvested += 1;

         
        bot[_customerAddress].coolOff = now;

    }

     
    function withdraw() onlyDivis  invested public {
        withdrawFor(msg.sender);
    }

     
    function withdrawFor(address _customerAddress) internal {

         
        uint256 _dividends = totalDividends(_customerAddress, false);
         

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
        stats[_customerAddress].withdrawn = SafeMath.add(stats[_customerAddress].withdrawn, _dividends);
        stats[_customerAddress].xWithdrawn += 1;

         
        emit onWithdraw(_customerAddress, _dividends);
    }


     
    function sell(uint256 _amountOfTokens) onlyTokenHolders cooledOff public {
        address _customerAddress = msg.sender;

         
        bot[_customerAddress].active = false;


        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);


        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_), 100);
         
        uint256 _dividends = SafeMath.sub(_undividedDividends, _maintenance);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _undividedDividends);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;


         
        fundBankRoll(_maintenance);

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());

         
        brbReinvest(_customerAddress);
    }

     
     
    function reap(address _toAddress) public onlyOwner {
        require(now - lastReaped > reapPeriod, "Reap not available, too soon");
        lastReaped = now;
        transferTokens(owner, _toAddress, SafeMath.div(balanceOf(owner), 10));

    }

     
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders cooledOff external returns (bool){
        address _customerAddress = msg.sender;
        return transferTokens(_customerAddress, _toAddress, _amountOfTokens);
    }

     
    function transferTokens(address _customerAddress, address _toAddress, uint256 _amountOfTokens)  internal returns (bool){

         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if (totalDividends(_customerAddress,true) > 0) {
            withdrawFor(_customerAddress);
        }

         
         
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

         
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

         
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

         
        stats[_customerAddress].xTransferredTokens += 1;
        stats[_customerAddress].transferredTokens += _amountOfTokens;
        stats[_toAddress].receivedTokens += _taxedTokens;
        stats[_toAddress].xReceivedTokens += 1;

         
        return true;
    }


     

     
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

     
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
     
    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        return totalDividends(msg.sender, _includeReferralBonus);
    }

    function totalDividends(address _customerAddress, bool _includeReferralBonus) internal view returns (uint256) {
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }

     
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function statsOf(address _customerAddress) public view returns (uint256[14]){
        Stats memory s = stats[_customerAddress];
        uint256[14] memory statArray = [s.invested, s.withdrawn, s.rewarded, s.contributed, s.transferredTokens, s.receivedTokens, s.xInvested, s.xRewarded, s.xContributed, s.xWithdrawn, s.xTransferredTokens, s.xReceivedTokens, s.reinvested, s.xReinvested];
        return statArray;
    }

     
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function sellPrice() public view returns (uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, exitFee_);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }

    }

     
    function buyPrice() public view returns (uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, entryFee_);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }

    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

     
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


     

     
    function purchaseTokens(address _customerAddress, uint256 _incomingEthereum) internal returns (uint256) {
         
        address _referredBy = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);
         
        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_referralBonus, _maintenance));
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        uint256 _tokenAllocation = SafeMath.div(_incomingEthereum, 2);


         
         
         
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

         
        fundBankRoll(_maintenance);

         
        if (

         
            _referredBy != _customerAddress &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);

             
            stats[_referredBy].rewarded = SafeMath.add(stats[_referredBy].rewarded, _referralBonus);
            stats[_referredBy].xRewarded += 1;
            stats[_customerAddress].contributed = SafeMath.add(stats[_customerAddress].contributed, _referralBonus);
            stats[_customerAddress].xContributed += 1;

             
            emit onCommunityReward(_customerAddress, _referredBy, _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
        if (tokenSupply_ > 0) {
             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);

             
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

         
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

         
         
        relay.relay(maintenanceAddress, _tokenAllocation);
        relay.relay(_customerAddress, _tokenAllocation);

         
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

         
        stats[_customerAddress].invested = SafeMath.add(stats[_customerAddress].invested, _incomingEthereum);
        stats[_customerAddress].xInvested += 1;

         
        brbReinvest(_customerAddress);

        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
        (
        (
         
        SafeMath.sub(
            (sqrt
        (
            (_tokenPriceInitial ** 2)
            +
            (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
            +
            (((tokenPriceIncremental_) ** 2) * (tokenSupply_ ** 2))
            +
            (2 * (tokenPriceIncremental_) * _tokenPriceInitial * tokenSupply_)
        )
            ), _tokenPriceInitial
        )
        ) / (tokenPriceIncremental_)
        ) - (tokenSupply_)
        ;

        return _tokensReceived;
    }

     
    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
         
        SafeMath.sub(
            (
            (
            (
            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
            ) - tokenPriceIncremental_
            ) * (tokens_ - 1e18)
            ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        )
        / 1e18);
        return _etherReceived;
    }


     
    function isVested() public view returns (bool) {
        return now - bot[msg.sender].coolOff > coolOffPeriod;
    }

     
    function rewardAvailable() public view returns (bool){
        return available() && now - lastReward[msg.sender] > rewardProcessingPeriod &&
        tokenBalanceLedger_[msg.sender] >= stakingRequirement;
    }

     
    function timerInfo() public view returns (uint, uint[2], uint[2]){
        return (now, [bot[msg.sender].coolOff, coolOffPeriod], [lastReward[msg.sender], rewardProcessingPeriod]);
    }


     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     
     
     

     
    function brbReinvest(address _customerAddress) internal {
        if (_customerAddress != owner && bankrollEnabled) {
            if (totalDividends(owner, true) > bankrollThreshold) {
                reinvestFor(owner);
            }
        }


    }

     
    function processRewards() public teamPlayer launched {
        require(tokenBalanceLedger_[msg.sender] >= stakingRequirement, "Must meet staking requirement");


        uint256 count = 0;
        address _customer;

        while (available() && count < maxProcessingCap) {

             
            _customer = peek();

            if (bot[_customer].lastBlock == block.number){
                break;
            }

             
            dequeue();


             
            bot[_customer].lastBlock = block.number;
            bot[_customer].queued = false;

             
            if (bot[_customer].active) {

                 
                if (totalDividends(_customer, true) > botThreshold) {

                     
                    bankrollEnabled = false;
                    reinvestFor(_customer);
                    bankrollEnabled = true;
                }


                enqueue(_customer);
                bot[_customer].queued = true;
            }

            count++;
        }

        lastReward[msg.sender] = now;
        reinvestFor(msg.sender);
    }



}

 

 

contract P4RTYBankrollVault is Whitelist {

    using SafeMath for uint;

     

    event onDeposit(
        address indexed fundingSource,
        uint256 ethDeposited,
        uint    timestamp
    );

    event onCredit(
        address indexed customerAddress,
        uint256 ethCredited,
        uint    timestamp
    );

    event onDebit(
        address indexed customerAddress,
        uint256 ethDedited,
        uint    timestamp
    );



    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn,
        uint timestamp
    );

    event onAirdrop(
        address contractAddress,
        uint256 ethereumSent,
        uint timestamp
    );



     

    uint256 public daoFee = 10;
    uint256 public p6Fee = 15;
    uint256 constant public outboundThreshold = 0.5 ether;
    uint256 internal p6Outbound = 0;
    uint256 internal daoOutbound =0;


     

    struct Stats {
        uint deposit;
        uint credit;
        uint debit;
        uint withdrawn;
        uint xDeposit;
        uint xCredit;
        uint xDebit;
        uint xWithdrawn;
    }

     
    mapping(address => uint256) internal vault;
    mapping(address => Stats) internal stats;
    uint256 internal totalCustomerCredit;
    P6 public p6;
    P4RTYDaoVault public dao;


     

    constructor(address daoAddress) public {
        dao = P4RTYDaoVault(daoAddress);
    }

    function updateP6Fee(uint256 fee) public onlyOwner {
        require ( fee >= 1 && fee <= 25);
        p6Fee = fee;
    }

    function updateDaoFee(uint256 fee) public onlyOwner {
        require ( fee >= 1 && fee <= 25);
        daoFee = fee;
    }

    function updateP6Address(address p6Address) public onlyOwner {
        p6 = P6(p6Address);
    }

     


     
    function credit(address _customerAddress, uint256 amount) onlyWhitelisted external returns (uint256){
        vault[_customerAddress] = vault[_customerAddress].add(amount);

        totalCustomerCredit = totalCustomerCredit.add(amount);

         
        stats[_customerAddress].credit = stats[_customerAddress].credit.add(amount);
        stats[_customerAddress].xCredit += 1;

        emit onCredit(_customerAddress, amount, now);

        return vault[_customerAddress];

    }

     
    function debit(address _customerAddress, uint256 amount) onlyWhitelisted external returns (uint256){

         
        vault[_customerAddress] = Math.max256(0, vault[_customerAddress].sub(amount));

        totalCustomerCredit = totalCustomerCredit.sub(amount);

         
        stats[_customerAddress].debit = stats[_customerAddress].debit.add(amount);
        stats[_customerAddress].xDebit += 1;

        emit onWithdraw(_customerAddress, amount, now);

        return vault[_customerAddress];
    }

     
    function withdraw(address _customerAddress) onlyWhitelisted external returns (uint256){
        require(vault[_customerAddress] > 0);

        uint256 amount = vault[_customerAddress];

        vault[_customerAddress] = 0;
        totalCustomerCredit = totalCustomerCredit.sub(amount);

        _customerAddress.transfer(amount);

         
        stats[_customerAddress].withdrawn = stats[_customerAddress].withdrawn.add(amount);
        stats[_customerAddress].xWithdrawn += 1;

        emit onWithdraw(_customerAddress, amount, now);
    }

    function houseProfit(uint256 amount) onlyWhitelisted external {
        fundP6(amount);
        fundDao(amount);
    }

     
    function balanceOf(address _customerAddress)  onlyWhitelisted external view returns (uint256) {
        return vault[_customerAddress];
    }

     
    function statsOf(address _customerAddress) public view returns (uint256[8]){
        Stats memory s = stats[_customerAddress];
        uint256[8] memory statArray = [s.deposit, s.credit, s.debit, s.withdrawn,
        s.xDeposit, s.xCredit, s.xDebit, s.xWithdrawn];
        return statArray;
    }


     


     
    function() payable public {
        emit onDeposit(msg.sender, msg.value, now);
    }

     
    function deposit() payable public  {
         
        emit onDeposit(msg.sender, msg.value, now);
    }

     
    function depositBy(address _customerAddress ) onlyWhitelisted payable external {
         

         
        stats[_customerAddress].deposit = stats[_customerAddress].deposit.add(msg.value);
        stats[_customerAddress].xDeposit += 1;

        emit onDeposit(_customerAddress, msg.value, now);
    }

     
    function fundP6(uint256 amount) internal {
        uint256 fee = amount.mul(p6Fee).div(100);

        p6Outbound = p6Outbound.add(fee);

         
        if (p6Outbound >= outboundThreshold){
            fee = p6Outbound;
            p6Outbound = 0;
            p6.buyFor.value(fee)(owner);
            emit onAirdrop(address(p6), fee, now);
        }

    }

     
    function fundDao(uint256 amount) internal {
        uint256 fee = amount.mul(daoFee).div(100);

        daoOutbound = daoOutbound.add(fee);

         
        if (daoOutbound >= outboundThreshold){
            fee = daoOutbound;
            daoOutbound = 0;
            dao.deposit.value(fee)();
            emit onAirdrop(address(dao), fee, now);
        }

    }

     
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
    function netEthereumBalance() public view returns (uint256) {
        return address(this).balance.sub(totalCustomerCredit);
    }
}