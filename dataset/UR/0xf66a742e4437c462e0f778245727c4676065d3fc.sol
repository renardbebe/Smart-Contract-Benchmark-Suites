 

pragma solidity ^0.4.24;
 
contract risebox {
    string public name = "RiseBox";
    string public symbol = "RBX";
    uint8 constant public decimals = 0;
    uint8 constant internal dividendFee_ = 10;

    uint256 constant ONEDAY = 86400;
    uint256 public lastBuyTime;
    address public lastBuyer;
    bool public isEnd = false;

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal profitPerShare_ = 0;
    address internal foundation;
    
    uint256 internal tokenSupply_ = 0;
    uint256 constant internal tokenPriceInitial_ = 1e14;
    uint256 constant internal tokenPriceIncremental_ = 15e6;


     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        uint256 _balance = address(this).balance;

        if(_balance <= 1000 ether) {
            require(_amountOfEthereum <= 2 ether);
            _;
        } else {
            _;
        }
    }
     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
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

    constructor () public {
        foundation =  msg.sender;
        lastBuyTime = now;
    }

    function buy(address _referredBy) 
        public 
        payable 
        returns(uint256)
    {
        assert(isEnd==false);

        if(breakDown()) {
            return liquidate();
        } else {
            return purchaseTokens(msg.value, _referredBy);
        }
    }

    function()
        payable
        public
    {
        assert(isEnd==false);

        if(breakDown()) {
            liquidate();
        } else {
            purchaseTokens(msg.value, 0x00);
        }
    }

     
    function reinvest()
        onlyStronghands()  
        public
    {
         
        uint256 _dividends = myDividends(false);  
        
         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends);
        
         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
         
        uint256 _tokens = purchaseTokens(_dividends, 0x00);
        
         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }


     
    function exit(address _targetAddress)
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
         
        withdraw(_targetAddress);
    }


    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        internal
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        payoutsTo_[foundation] -= (int256)(_dividends);
    }



     
    function withdraw(address _targetAddress)
        onlyStronghands()
        internal
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  
        
         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends);
        
         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
         
        if(_dividends > address(this).balance/2) {
            _dividends = address(this).balance / 2;
        }

        _targetAddress.transfer(_dividends);

         
        emit onWithdraw(_targetAddress, _dividends);       
    }

     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;
        
         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
         
        if(myDividends(true) > 0) withdraw(msg.sender);
        

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        
         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        
        
         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
         
        return true;
       
    }

     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        address _customerAddress = msg.sender; 
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 2); 
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus); 
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends); 

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends;

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress
        ) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else if (
            _referredBy != _customerAddress
        ){
            payoutsTo_[foundation] -= (int256)(_referralBonus);
        } else {
            referralBalance_[foundation] -= _referralBonus;
        }

         
        if(tokenSupply_ > 0){
            
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            _fee = _amountOfTokens * (_dividends / tokenSupply_);
         
        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

        profitPerShare_ += SafeMath.div(_dividends , tokenSupply_);

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        lastBuyTime = now;
        lastBuyer = msg.sender;
         
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }


     
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokensReceived = 0;
        
        if(_ethereum < (tokenPriceInitial_ + tokenPriceIncremental_*tokenSupply_)) {
            return _tokensReceived;
        }

        _tokensReceived = 
         (
            (
                 
                SafeMath.sub(
                    (SafeMath.sqrt
                        (
                            (tokenPriceInitial_**2)
                            +
                            (2 * tokenPriceIncremental_ * _ethereum)
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*tokenPriceInitial_*tokenSupply_)
                        )
                    ), tokenPriceInitial_
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }

     
    function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        uint256 _etherReceived = 

        SafeMath.sub(
            _tokens * (tokenPriceIncremental_ * tokenSupply_ +     tokenPriceInitial_) , 
            (_tokens**2)*tokenPriceIncremental_/2
        );

        return _etherReceived;
    }


     
    function dividendsOf(address _customerAddress)
        internal
        view
        returns(uint256)
    {
        int256 _dividend = (int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress];

        if(_dividend < 0) {
            _dividend = 0;
        }
        return (uint256)(_dividend);
    }


     
    function balanceOf(address _customerAddress)
        internal
        view
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function breakDown() 
        internal
        returns(bool)
    {
         
        if (lastBuyTime + ONEDAY < now) {
            isEnd = true;
            return true;
        } else {
            return false;
        }
    }

    function liquidate()
        internal
        returns(uint256)
    {
         
        msg.sender.transfer(msg.value);

         
        uint256 _balance = address(this).balance;
         
        uint256 _taxedEthereum = _balance * 88 / 100;
         
        uint256 _tax = SafeMath.sub(_balance , _taxedEthereum);

        foundation.transfer(_tax);
        lastBuyer.transfer(_taxedEthereum);

        return _taxedEthereum;
    }

     
     
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
     
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
   
      
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
     
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
     
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1);
            uint256 _dividends = SafeMath.div(_ethereum, (dividendFee_-1)  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
     
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
         
        require(_ethereumToSpend <= 1e32 , "number is too big");
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
    
     
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }

}


 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b > 0);  
      uint256 c = a / b;
       

      return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }

        return y;
    }

}