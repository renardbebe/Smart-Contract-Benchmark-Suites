 

pragma solidity ^0.4.26;

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
    owner = address(0x72bEe2Cf43f658F3EdF5f4E08bAB03b5F777FA0A);
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

contract Hex2 is Ownable {

    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    bool public onlyAmbassadors = true;
    uint256 ACTIVATION_TIME = 1576350000;

    modifier antiEarlyWhale(uint256 _amountOfEthereum, address _customerAddress){
      if (now >= ACTIVATION_TIME) {
         onlyAmbassadors = false;
      }

      if (onlyAmbassadors){
         require((ambassadors_[_customerAddress] == true && (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_));
         ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
         _;
      } else {
         onlyAmbassadors = false;
         _;
      }
    }

    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDivis {
        require(myDividends(true) > 0);
        _;
    }

    event onDistribute(
        address indexed customerAddress,
        uint256 price
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingETH,
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

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    string public name = "HEX2WIN";
    string public symbol = "HEX";
    uint8 constant public decimals = 18;
    uint256 internal entryFee_ = 10;
    uint256 internal transferFee_ = 1;
    uint256 internal exitFee_ = 10;
    uint256 internal referralFee_ = 10;  
    uint256 internal maintenanceFee_ = 10;  
    address internal maintenanceAddress;
    uint256 constant internal magnitude = 2 ** 64;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal invested_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public stakingRequirement = 1e16;
    uint256 public totalHolder = 0;
    uint256 public totalDonation = 0;

    constructor() public {
        maintenanceAddress = address(0x72bEe2Cf43f658F3EdF5f4E08bAB03b5F777FA0A);

        ambassadors_[0xEfB79c12af54CF6F8633AfcFF8019A533d7D1C3A] = true;  
        ambassadors_[0xF8C7a2b4d43c33f7878076D75cf33AC344495D32] = true;  
        ambassadors_[0x87cb806192eC699398511c7aB44b3595C051D13C] = true;  
        ambassadors_[0xb03bEF1D9659363a9357aB29a05941491AcCb4eC] = true;  
        ambassadors_[0xCdB84A89BB3D2ad99a39AfAd0068DC11B8280FbC] = true;  
        ambassadors_[0x875CDdfF875Ee34A262a9d6Cf3d80eE04Fb5129D] = true;  
        ambassadors_[0x43678bB266e75F50Fbe5927128Ab51930b447eaB] = true;  
        ambassadors_[0x843f2C19bc6df9E32B482E2F9ad6C078001088b1] = true;  
        ambassadors_[0x23A2F928c3cBA4d3B7e7E7FA9C08440004b4DfB0] = true;  
        ambassadors_[0x2d6182013CD656246F383146dBC54E298707Dd80] = true;  
        ambassadors_[0x531c2a3328555f0b77f48D79613fe545d329F076] = true;  
        ambassadors_[0x0030b5DF0413234F83d7935cF375E2FBf5fd7822] = true;  
        ambassadors_[0x40D05342433715C3527D87eca9b7C093206Ea3Ec] = true;  
        ambassadors_[0xEc31176d4df0509115abC8065A8a3F8275aafF2b] = true;  
        ambassadors_[0xCf46b80aE8F09faE41b1A789ff555FdE9E98Aa5A] = true;  
        ambassadors_[0x3B2853a3cE696abea69cC186BB467f7df1aBcC76] = true;  
        ambassadors_[0x77dD6596171174C8A21Ad859847ddAdDb8D11460] = true;  
        ambassadors_[0x72bEe2Cf43f658F3EdF5f4E08bAB03b5F777FA0A] = true;  
        ambassadors_[0xEf8340355BA00556652A7D9907Dd64390b16f7A3] = true;  
    }

    function updateMaintenanceAddress(address maintenance) onlyOwner public {
        maintenanceAddress = maintenance;
    }

    function distribute() public payable returns (uint256) {
        require(msg.value > 0, "must be a positive value");
        totalDonation += msg.value;
        profitPerShare_ = SafeMath.add(profitPerShare_, (msg.value * magnitude) / tokenSupply_);
        emit onDistribute(msg.sender, msg.value);
    }

    function buy(address _referredBy) public payable returns (uint256) {
        return purchaseTokens(_referredBy, msg.sender, msg.value);
    }

    function buyFor(address _customerAddress, address _referredBy) public payable returns (uint256) {
        return purchaseTokens(_referredBy, _customerAddress, msg.value);
    }

    function() payable public {
        purchaseTokens(owner, msg.sender, msg.value);
    }

    function reinvest() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(0x0, _customerAddress, _dividends);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_amountOfTokens, exitFee_), 100);
        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends,maintenanceFee_),100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _maintenance);
        uint256 _taxedETH = SafeMath.sub(_amountOfTokens, _undividedDividends);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens + (_taxedETH * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], _maintenance);

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedETH, now, buyPrice());
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool){
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = _tokenFee;

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        return true;
    }

    function setName(string _name) onlyOwner public
    {
       name = _name;
    }

    function setSymbol(string _symbol) onlyOwner public
    {
       symbol = _symbol;
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
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
        uint256 _ethereum = 1e18;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedETH = SafeMath.sub(_ethereum, _dividends);

        return _taxedETH;
    }

    function buyPrice() public view returns (uint256) {
        uint256 _ethereum = 1e18;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
        uint256 _taxedETH = SafeMath.add(_ethereum, _dividends);

        return _taxedETH;
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _amountOfTokens = SafeMath.sub(_ethereumToSpend, _dividends);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokensToSell, exitFee_), 100);
        uint256 _taxedETH = SafeMath.sub(_tokensToSell, _dividends);

        return _taxedETH;
    }

    function getInvested() public view returns (uint256) {
        return invested_[msg.sender];
    }

    function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingETH) internal antiEarlyWhale(_incomingETH, _customerAddress) returns (uint256) {
        if (getInvested() == 0) {
          totalHolder++;
        }

        invested_[msg.sender] += _incomingETH;

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingETH, entryFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_referralBonus,_maintenance));
        uint256 _amountOfTokens = SafeMath.sub(_incomingETH, _undividedDividends);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], _maintenance);

        if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger_[_referredBy] >= stakingRequirement) {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
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

        emit onTokenPurchase(_customerAddress, _incomingETH, _amountOfTokens, _referredBy, now, buyPrice());
        return _amountOfTokens;
    }
}