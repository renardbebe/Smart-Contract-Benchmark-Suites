 

pragma solidity ^0.4.20;

contract NeverEndingApp {


     

     
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }


     

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

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


     

    string public name = "Never Ending App";
    string public symbol = "NEAT";  
    uint8 constant public decimals = 18;

     
    uint8 constant internal entryFee_ = 12;

     
    uint8 constant internal transferFee_ = 4;

     
    uint8 constant internal exitFee_ = 12;

     
    uint8 constant internal refferalFee_ = 35;

    uint256 constant internal tokenPriceInitial_ = 0.000000000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.0000000000009 ether;
    uint256 constant internal magnitude = 2 ** 64;

     
    uint256 public stakingRequirement = 100e18;
    
     
    
     
    address internal devFeeAddress = 0x5B2FA02281491E51a97c0b087215c8b2597C8a2f;
     
    address internal marketingFeeAddress = 0xf42934E5C290AA1586d9945Ca8F20cFb72307f91;
     
    address internal feedingFeeAddress = 0x8b8158c9D815E7720e16CEc3e1166A2D4F96b8A6;
     
    address internal employeeFeeAddress1 = 0x2959114502Fca4d506Ae7cf88f602e7038a29AC1; 
     
    address internal employeeFeeAddress2 = 0x5B2FA02281491E51a97c0b087215c8b2597C8a2f;
     
    address internal employeeFeeAddress3 = 0x5B2FA02281491E51a97c0b087215c8b2597C8a2f;
    
    address internal admin;
    mapping(address => bool) internal ambassadors_;


    

     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 constant internal ambassadorMaxPurchase_ = 0.55 ether;
    uint256 constant internal ambassadorQuota_ = 5000 ether;
    bool public onlyAmbassadors = true;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    
    uint ACTIVATION_TIME = 1543172400;
    
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        if (now >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }
         
         
        if(onlyAmbassadors){
            require(
                 
                (ambassadors_[msg.sender] == true &&
                
                 
                (ambassadorAccumulatedQuota_[msg.sender] + _amountOfEthereum) <= ambassadorMaxPurchase_)
                
            );
            
             
            ambassadorAccumulatedQuota_[msg.sender] = SafeMath.add(ambassadorAccumulatedQuota_[msg.sender], _amountOfEthereum);
        
             
            _;
        }else{
            onlyAmbassadors=false;
            _;
        }
        
    }
    
    
    function NeverEndingApp() public{
        admin=msg.sender;

        ambassadors_[0x4f574642be8C00BD916803c4BC1EC1FC05efa5cF] = true;  
        ambassadors_[0x77c192342F25a364FB17C25cdDddb194a8d34991] = true;  
        ambassadors_[0xE206201116978a48080C4b65cFA4ae9f03DA3F0D] = true;  
        ambassadors_[0x21adD73393635b26710C7689519a98b09ecdc474] = true;  
        ambassadors_[0xEc31176d4df0509115abC8065A8a3F8275aafF2b] = true;  
        ambassadors_[0x77a21F9E0325950f679d28ed99d8715437c74145] = true;  
        ambassadors_[0xc7F15d0238d207e19cce6bd6C0B85f343896F046] = true;  
        ambassadors_[0xBa21d01125D6932ce8ABf3625977899Fd2C7fa30] = true;  
        ambassadors_[0x2277715856C6d9E0181BA01d21e059f76C79f2bD] = true;  
        ambassadors_[0xB1dB0FB75Df1cfb37FD7fF0D7189Ddd0A68C9AAF] = true;  
        ambassadors_[0xEafE863757a2b2a2c5C3f71988b7D59329d09A78] = true;  
        ambassadors_[0xB19772e5E8229aC499C67E820Db53BF52dbaf0dE] = true;  
        ambassadors_[0x42830382f378d083A8Ae55Eb729A9d789fA4dEA6] = true;  
        ambassadors_[0x87f7baA7e7570DD811e50fC43F5c26d02801F3f4] = true;  
        ambassadors_[0x53e1eB6a53d9354d43155f76861C5a2AC80ef361] = true;  
        ambassadors_[0x80F946BF39531E65DBEdfcA1B9e29CaC562d43a4] = true;  
        ambassadors_[0x41a21b264F9ebF6cF571D4543a5b3AB1c6bEd98C] = true;  
        ambassadors_[0x267fa9F2F846da2c7A07eCeCc52dF7F493589098] = true;  
        
        
        

    }
    
  function disableAmbassadorPhase() public{
        require(admin==msg.sender);
        onlyAmbassadors=false;
    }
    
  function changeEmployee1(address _employeeAddress1) public{
        require(admin==msg.sender);
        employeeFeeAddress1=_employeeAddress1;
    }
    
  function changeEmployee2(address _employeeAddress2) public{
        require(admin==msg.sender);
        employeeFeeAddress2=_employeeAddress2;
    }
    
  function changeEmployee3(address _employeeAddress3) public{
        require(admin==msg.sender);
        employeeFeeAddress3=_employeeAddress3;
    }
    
  function changeMarketing(address _marketingAddress) public{
        require(admin==msg.sender);
        marketingFeeAddress=_marketingAddress;
    }
    
     

     
    function buy(address _referredBy) public payable returns (uint256) {
        purchaseTokens(msg.value, _referredBy);
    }

     
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }

     
    function reinvest() onlyStronghands public {
         
        uint256 _dividends = myDividends(false);  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

         
         onReinvestment(_customerAddress, _dividends, _tokens);
    }

     
    function exit() public {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

         
        withdraw();
    }

     
    function withdraw() onlyStronghands public {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
         onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens) onlyBagholders public {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _devFee = SafeMath.div(SafeMath.mul(_ethereum, 1), 100);
        uint256 _marketingFee = SafeMath.div(SafeMath.mul(_ethereum, 1), 100);
        uint256 _feedingFee = SafeMath.div(SafeMath.mul(_ethereum, 1), 100);
        
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _devFee), _marketingFee), _feedingFee);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        devFeeAddress.transfer(_devFee);
        marketingFeeAddress.transfer(_marketingFee);
        feedingFeeAddress.transfer(_feedingFee);
         
         onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
       
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
         
        address _customerAddress = msg.sender;

         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if (myDividends(true) > 0) {
            withdraw();
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

         
         Transfer(_customerAddress, _toAddress, _taxedTokens);

         
        return true;
    }


     

     
    function totalEthereumBalance() public view returns (uint256) {
        return this.balance;
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
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

     
    function buyPrice() public view returns (uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
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


     

     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) antiEarlyWhale(_incomingEthereum)
       internal returns (uint256) {
         
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 3), 200));
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

         
        if (
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
             
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

         
         onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());
        devFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 3), 200));
        marketingFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        feedingFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        employeeFeeAddress1.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        employeeFeeAddress2.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        employeeFeeAddress3.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));
        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
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
                            ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                            +
                            (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            ) / (tokenPriceIncremental_)
        ) - (tokenSupply_);

        return _tokensReceived;
    }

     
    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
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

     
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
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