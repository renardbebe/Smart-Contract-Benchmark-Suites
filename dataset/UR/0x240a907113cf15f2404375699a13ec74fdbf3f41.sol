 

pragma solidity 0.4.20;
 
  
library SafeMath {
  function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
    uint _numerator  = numerator * 10 ** (precision+1);
    uint _quotient =  ((_numerator / denominator) + 5) / 10;
    return (value*_quotient/1000000000000000000);
  }
  
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

contract TDAPP24MAY {
    
     
    
     
    string public name                                      = "TDAPP24MAY";
    string public symbol                                    = "TDAPP";
    uint8 constant public decimals                          = 18;
    uint256 constant internal tokenPriceInitial             = 0.000000001 ether;
    
     
    uint256 constant internal tokenPriceIncDec              = 0.000000001 ether;
    
     
    uint256 public stakingReq                               = 1e18;
    uint256 constant internal magnitude                     = 2**64;
    
     
    uint8 constant internal referralFeePercent              = 5;
    uint8 constant internal dividendFeePercent              = 10;
    uint8 constant internal tradingFundWalletFeePercent     = 10;
    uint8 constant internal communityWalletFeePercent       = 10;
    
     
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal sellingWithdrawBalance_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(address => string) internal contractTokenHolderAddresses;

    uint256 internal tokenTotalSupply                       = 0;
    uint256 internal calReferralPercentage                  = 0;
    uint256 internal calDividendPercentage                  = 0;
    uint256 internal calculatedPercentage                   = 0;
    uint256 internal soldTokens                             = 0;
    uint256 internal tempIncomingEther                      = 0;
    uint256 internal tempProfitPerShare                     = 0;
    uint256 internal tempIf                                 = 0;
    uint256 internal tempCalculatedDividends                = 0;
    uint256 internal tempReferall                           = 0;
    uint256 internal tempSellingWithdraw                    = 0;
    uint256 internal profitPerShare_;
    
     
    bool public onlyAmbassadors = false;
    
     
    address internal constant CommunityWalletAddr           = address(0x1e5A8DE394e3cbA8adAC8C58C7CF3d9ae042fC34);
     
    address internal constant TradingWalletAddr             = address(0x9BB77a5f75aD4e17A350DBcc36ee543EdA11EED5);  

     
    mapping(bytes32 => bool) public admin;
    
     
    
     
    modifier onlybelievers() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyhodler() {
        require(myDividends(true) > 0);
        _;
    }
    
     
    modifier onlySelingholder() {
        require(sellingWithdrawBalance_[msg.sender] > 0);
        _;
    }
    
     
     
     
     
     
     
     
     
     
    modifier onlyAdmin() {
        address _adminAddress = msg.sender;
        require(admin[keccak256(_adminAddress)]);
        _;
    }
    
     
    
     
    function disableInitialStage() onlyAdmin() public {
        onlyAmbassadors = false;
    }
    
    function setAdmin(bytes32 _identifier, bool _status) onlyAdmin() public {
        admin[_identifier]      = _status;
    }
    
    function setStakingReq(uint256 _tokensAmount) onlyAdmin() public {
        stakingReq              = _tokensAmount;
    }
    
    function setName(string _tokenName) onlyAdmin() public {
        name                    = _tokenName;
    }
    
    function setSymbol(string _tokenSymbol) onlyAdmin() public {
        symbol                  = _tokenSymbol;
    }
    
     
    
    event onTokenPurchase (
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell (
        address indexed customerAddress,
        uint256 tokensBurned
    );
    
    event onReinvestment (
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw (
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    event onSellingWithdraw (
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    
    );
    
    event Transfer (
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
     
    
    function Treasure() public {
         
        admin[0x13321a0b5634e9b7ef729599faca1aa51f0a45b5ad8a4e6e3ce8fe8ecdfc54a3] = true;
    }
    
     
    function totalEthereumBalance() public view returns(uint) {
        return this.balance;
    }
    
     
    function totalSupply() public view returns(uint256) {
        return tokenTotalSupply;
    }
    
     
    function myTokens() public view returns(uint256) {
        address ownerAddress = msg.sender;
        return tokenBalanceLedger_[ownerAddress];
    }
    
     
    function getSoldTokens() public view returns(uint256) {
        return soldTokens;
    }
    
     
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
     
    function dividendsOf(address _customerAddress) view public returns(uint256) {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
     
    function balanceOf(address ownerAddress) public view returns(uint256) {
        return tokenBalanceLedger_[ownerAddress];  
    }
    
     
    function sellingWithdrawBalance() view public returns(uint256) {
        address _customerAddress = msg.sender; 
        uint256 _sellingWithdraw = (uint256) (sellingWithdrawBalance_[_customerAddress]) ;  
        return  _sellingWithdraw;
    }
    
     
    function sellPrice() public view returns(uint256) {
        if(tokenTotalSupply == 0){
            return tokenPriceInitial - tokenPriceIncDec;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            return _ethereum - SafeMath.percent(_ethereum,15,100,18);
        }
    }
    
     
    function buyPrice() public view returns(uint256) {
        if(tokenTotalSupply == 0){
            return tokenPriceInitial;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            return _ethereum;
        }
    }
    
     
    function reinvest() onlyhodler() public {
        address _customerAddress = msg.sender;
         
        uint256 _dividends                  = myDividends(true);  
         
        uint256  TenPercentForDistribution  = SafeMath.percent(_dividends,10,100,18);
         
        uint256  NinetyPercentToReinvest    = SafeMath.percent(_dividends,90,100,18);
         
        uint256 _tokens                     = purchaseTokens(NinetyPercentToReinvest, 0x0);
         
        payoutsTo_[_customerAddress]        +=  (int256) (SafeMath.sub(_dividends, referralBalance_[_customerAddress]) * magnitude);
        referralBalance_[_customerAddress]  = 0;
        
         
        profitPerShare_ = SafeMath.add(profitPerShare_, (TenPercentForDistribution * magnitude) / tokenTotalSupply);
        
         
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
     
    function exit() public {
         
        address _customerAddress            = msg.sender;
        uint256 _tokens                     = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
    
        withdraw();
    }
    
     
    function withdraw() onlyhodler() public {
        address _customerAddress            = msg.sender;
         
        uint256 _dividends                  = myDividends(true);  
         
        uint256 TenPercentForTradingWallet  = SafeMath.percent(_dividends,10,100,18);
         
        uint256 TenPercentForCommunityWallet= SafeMath.percent(_dividends,10,100,18);

         
        payoutsTo_[_customerAddress]        +=  (int256) (SafeMath.sub(_dividends, referralBalance_[_customerAddress]) * magnitude);
        referralBalance_[_customerAddress]  = 0;
       
         
        address(CommunityWalletAddr).transfer(TenPercentForCommunityWallet);
        
         
        address(TradingWalletAddr).transfer(TenPercentForTradingWallet);
        
         
        uint256 EightyPercentForCustomer    = SafeMath.percent(_dividends,80,100,18);

         
        address(_customerAddress).transfer(EightyPercentForCustomer);
        
         
        onWithdraw(_customerAddress, _dividends);
    }
    
     
    function sellingWithdraw() onlySelingholder() public {
        address customerAddress             = msg.sender;
        uint256 _sellingWithdraw            = sellingWithdrawBalance_[customerAddress];
        
         
        sellingWithdrawBalance_[customerAddress] = 0;

         
        address(customerAddress).transfer(_sellingWithdraw);
        
         
        onSellingWithdraw(customerAddress, _sellingWithdraw);
    }
    
     
     
    function sell(uint256 _amountOfTokens) onlybelievers() public {
        address customerAddress                 = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[customerAddress] && _amountOfTokens > 1e18);
        
        uint256 _tokens                         = SafeMath.sub(_amountOfTokens, 1e18);
        uint256 _ethereum                       = tokensToEthereum_(_tokens);
         
        uint256  TenPercentToDistribute         = SafeMath.percent(_ethereum,10,100,18);
         
        uint256  NinetyPercentToCustomer        = SafeMath.percent(_ethereum,90,100,18);
        
         
        tokenTotalSupply                        = SafeMath.sub(tokenTotalSupply, _tokens);
        tokenBalanceLedger_[customerAddress]    = SafeMath.sub(tokenBalanceLedger_[customerAddress], _tokens);
        
         
        soldTokens                              = SafeMath.sub(soldTokens,_tokens);
        
         
        sellingWithdrawBalance_[customerAddress] += NinetyPercentToCustomer;   
        
         
        int256 _updatedPayouts                  = (int256) (profitPerShare_ * _tokens + (TenPercentToDistribute * magnitude));
        payoutsTo_[customerAddress]             -= _updatedPayouts; 
        
         
        if (tokenTotalSupply > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (TenPercentToDistribute * magnitude) / tokenTotalSupply);
        }
      
         
        onTokenSell(customerAddress, _tokens);
    }
    
     
     
    function transfer(address _toAddress, uint256 _amountOfTokens) onlybelievers() public returns(bool) {
        address customerAddress                 = msg.sender;
         
        
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[customerAddress] && _amountOfTokens > 1e18);
        
         
        uint256  FivePercentOfTokens            = SafeMath.percent(_amountOfTokens,5,100,18);
         
        uint256  NinetyFivePercentOfTokens      = SafeMath.percent(_amountOfTokens,95,100,18);
        
         
         
        tokenTotalSupply                        = SafeMath.sub(tokenTotalSupply,FivePercentOfTokens);
        
         
        soldTokens                              = SafeMath.sub(soldTokens, FivePercentOfTokens);

         
        tokenBalanceLedger_[customerAddress]    = SafeMath.sub(tokenBalanceLedger_[customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress]         = SafeMath.add(tokenBalanceLedger_[_toAddress], NinetyFivePercentOfTokens) ;
        
         
        uint256 FivePercentToDistribute         = tokensToEthereum_(FivePercentOfTokens);
        
         
        payoutsTo_[customerAddress]             -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress]                  += (int256) (profitPerShare_ * NinetyFivePercentOfTokens);
        
         
        profitPerShare_                         = SafeMath.add(profitPerShare_, (FivePercentToDistribute * magnitude) / tokenTotalSupply);

         
        Transfer(customerAddress, _toAddress, NinetyFivePercentOfTokens);
        
        return true;
    }
    
     
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {
         
        uint256  fifteen_percentToDistribute= SafeMath.percent(_ethereumToSpend,15,100,18);

        uint256 _dividends = SafeMath.sub(_ethereumToSpend, fifteen_percentToDistribute);
        uint256 _amountOfTokens = ethereumToTokens_(_dividends);
        
        return _amountOfTokens;
    }
    
     
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenTotalSupply);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
         
        uint256  ten_percentToDistribute= SafeMath.percent(_ethereum,10,100,18);
        
        uint256 _dividends = SafeMath.sub(_ethereum, ten_percentToDistribute);

        return _dividends;
    }
    
     
    function buy(address referredBy) public payable {
        purchaseTokens(msg.value, referredBy);
    }
    
     
     
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }
    
     
    
    function purchaseTokens(uint256 incomingEthereum, address referredBy) internal returns(uint256) {
         
        address customerAddress     = msg.sender;
        tempIncomingEther           = incomingEthereum;

         
        calReferralPercentage       = SafeMath.percent(incomingEthereum,referralFeePercent,100,18);
         
        calDividendPercentage       = SafeMath.percent(incomingEthereum,dividendFeePercent,100,18);
         
        calculatedPercentage        = SafeMath.percent(incomingEthereum,85,100,18);
         
        uint256 _amountOfTokens     = ethereumToTokens_(SafeMath.percent(incomingEthereum,85,100,18));  
        uint256 _dividends          = 0;
        uint256 minOneToken         = 1 * (10 ** decimals);
        require(_amountOfTokens > minOneToken && (SafeMath.add(_amountOfTokens,tokenTotalSupply) > tokenTotalSupply));
        
         
        if(
             
            referredBy  != 0x0000000000000000000000000000000000000000 &&
             
            referredBy  != customerAddress &&
             
            tokenBalanceLedger_[referredBy] >= stakingReq
        ) {
             
            referralBalance_[referredBy]    += SafeMath.percent(incomingEthereum,5,100,18);
            _dividends              = calDividendPercentage;
        } else {
             
            _dividends              = SafeMath.add(calDividendPercentage, calReferralPercentage);
        }
        
         
        if(tokenTotalSupply > 0) {
             
            tokenTotalSupply        = SafeMath.add(tokenTotalSupply, _amountOfTokens);
            profitPerShare_         += (_dividends * magnitude / (tokenTotalSupply));
        } else {
             
            tokenTotalSupply        = _amountOfTokens;
        }
        
         
        tokenBalanceLedger_[customerAddress] = SafeMath.add(tokenBalanceLedger_[customerAddress], _amountOfTokens);
        
         
        int256 _updatedPayouts      = (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[customerAddress] += _updatedPayouts;
        
         
        onTokenPurchase(customerAddress, incomingEthereum, _amountOfTokens, referredBy);
        
         
        soldTokens += _amountOfTokens;
        
        return _amountOfTokens;

    }
    
     
     
     
    function ethereumToTokens_(uint256 _ethereum) internal view returns(uint256) {
        uint256 _tokenPriceInitial  = tokenPriceInitial * 1e18;
        uint256 _tokensReceived     = 
         (
            (
                SafeMath.sub(
                    (SqRt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncDec * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncDec)**2)*(tokenTotalSupply**2))
                            +
                            (2*(tokenPriceIncDec)*_tokenPriceInitial*tokenTotalSupply)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncDec)
        )-(tokenTotalSupply);
        return _tokensReceived;
    }
    
     
     
     
    function tokensToEthereum_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_         = (_tokens + 1e18);
        uint256 _tokenSupply    = (tokenTotalSupply + 1e18);
        uint256 _etherReceived  =
        (
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial + (tokenPriceIncDec * (_tokenSupply/1e18))
                        )-tokenPriceIncDec
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncDec*((tokens_**2-tokens_)/1e18))/2
            )/1e18);
        return _etherReceived;
    }
    
     
    function SqRt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
}