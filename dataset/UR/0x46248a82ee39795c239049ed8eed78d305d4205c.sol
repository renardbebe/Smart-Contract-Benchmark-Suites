 

pragma solidity ^0.4.24;

contract AcceptsExchange {
    Exchange public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = Exchange(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}


contract Exchange {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

     
    modifier notContract() {
        require (msg.sender == tx.origin);
        _;
    }

     
    modifier maxAmbassadors() {
        require(totalAmbassadors < 100);
        _;
    }

     
    modifier removeAmbassadorCriteria(address _existingAmbassador) {
        require(ambassadorAccumulatedQuota_[_existingAmbassador] < 0.1 ether && ambassadorDepositTime_[_existingAmbassador] + 6 hours < now);
        _;
    }

    uint TRANSFER_SELL_TIME = 1541952000;

     
     
     
    modifier isActivated(){
        require(now >= TRANSFER_SELL_TIME || administrators[msg.sender]);
        _;
    }

     
    modifier isSellActivated(){
        require(now >= TRANSFER_SELL_TIME);
        _;
    }

     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }

    uint ACTIVATION_TIME = 1541865600;

     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum, bool _isReinvest){

        if (now >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }

         
         
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                 
                ambassadors_[msg.sender] == true &&

                 
                (ambassadorAccumulatedQuota_[msg.sender] + _amountOfEthereum) <= ambassadorMaxPurchase_ &&

                 
                 
                (ambassadorAccumulatedQuota_[msg.sender] >= 0.1 ether || _amountOfEthereum >= 0.1 ether || _isReinvest)
            );

             
            ambassadorAccumulatedQuota_[msg.sender] = SafeMath.add(ambassadorAccumulatedQuota_[msg.sender], _amountOfEthereum);
            ambassadorDepositTime_[msg.sender] = now;

             
            _;
        } else {
             
            onlyAmbassadors = false;
            _;
        }

    }

     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        bool isReinvest,
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
        uint256 ethereumWithdrawn,
        uint256 estimateTokens,
        bool isTransfer
    );

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


     
    string public name = "EXCHANGE";
    string public symbol = "SHARES";
    uint8 constant public decimals = 18;

    uint8 constant internal entryFee_ = 10;  
    uint8 constant internal startExitFee_ = 40;  
    uint8 constant internal finalExitFee_ = 10;  
    uint8 constant internal fundFee_ = 5;  
    uint256 constant internal exitFeeFallDuration_ = 30 days;  

    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 constant internal magnitude = 2**64;

     
    address public giveEthFundAddress = 0x0;
    bool public finalizedEthFundAddress = false;
    uint256 public totalEthFundReceived;  
    uint256 public totalEthFundCollected;  

     
    uint256 public stakingRequirement = 25e18;

     
    uint public totalAmbassadors = 0;
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 2.5 ether;
    uint256 constant internal ambassadorQuota_ = 250 ether;

    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(address => uint256) internal ambassadorDepositTime_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

     
    mapping(address => bool) public administrators;

     
    bool public onlyAmbassadors = true;

     
    mapping(address => bool) public canAcceptTokens_;  

     
     
    constructor()
        public
    {
         
        administrators[0x3db1e274bf36824cf655beddb92a90c04906e04b] = true;
    }

     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        require(tx.gasprice <= 0.05 szabo);
        purchaseTokens(msg.value, _referredBy, false);
    }

     
    function()
        payable
        public
    {
        require(tx.gasprice <= 0.05 szabo);
        purchaseTokens(msg.value, 0x0, false);
    }

    function updateFundAddress(address _newAddress)
        onlyAdministrator()
        public
    {
        require(finalizedEthFundAddress == false);
        giveEthFundAddress = _newAddress;
    }

    function finalizeFundAddress(address _finalAddress)
        onlyAdministrator()
        public
    {
        require(finalizedEthFundAddress == false);
        giveEthFundAddress = _finalAddress;
        finalizedEthFundAddress = true;
    }

    function payFund() payable onlyAdministrator() public {
        uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundReceived);
        require(ethToPay > 0);
        totalEthFundReceived = SafeMath.add(totalEthFundReceived, ethToPay);
        if(!giveEthFundAddress.call.value(ethToPay).gas(400000)()) {
          totalEthFundReceived = SafeMath.sub(totalEthFundReceived, ethToPay);
        }
    }

     
    function reinvest()
        onlyStronghands()
        public
    {
         
        uint256 _dividends = myDividends(false);  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends, 0x0, true);

         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

     
    function exit()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);

         
        withdraw(false);
    }

     
    function withdraw(bool _isTransfer)
        isActivated()
        onlyStronghands()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  

        uint256 _estimateTokens = calculateTokensReceived(_dividends);  

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
        emit onWithdraw(_customerAddress, _dividends, _estimateTokens, _isTransfer);
    }

     
    function sell(uint256 _amountOfTokens)
        isSellActivated()
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);

         
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);

         
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        isActivated()
        onlyBagholders()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;

         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if(myDividends(true) > 0) withdraw(true);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

         
        return true;
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true);  
      require(transfer(_to, _value));  

      if (isContract(_to)) {
        AcceptsExchange receiver = AcceptsExchange(_to);
        require(receiver.tokenFallback(msg.sender, _value, _data));
      }

      return true;
    }

     
     function isContract(address _addr) private constant returns (bool is_contract) {
        
       uint length;
       assembly { length := extcodesize(_addr) }
       return length > 0;
     }

     
     
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

     
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }

     
    function setCanAcceptTokens(address _address, bool _value)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = _value;
    }

     
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

     
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

     
    function addAmbassador(address _newAmbassador)
        maxAmbassadors()
        onlyAdministrator()
        public
    {
        totalAmbassadors = SafeMath.add(totalAmbassadors,1);
        ambassadors_[_newAmbassador] = true;
    }

     
    function removeAmbassador(address _existingAmbassador)
        removeAmbassadorCriteria(_existingAmbassador)
        onlyAdministrator()
        public
    {
        totalAmbassadors = SafeMath.sub(totalAmbassadors,1);
        ambassadors_[_existingAmbassador] = false;
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

     
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function sellPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
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
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, fundFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _fundPayout);
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
        return _taxedEthereum;
    }

     
    function etherToSendFund()
        public
        view
        returns(uint256) {
        return SafeMath.sub(totalEthFundCollected, totalEthFundReceived);
    }

     
    function exitFee() public view returns (uint8) {
        if ( now < ACTIVATION_TIME) {
          return startExitFee_;
        }
        uint256 secondsPassed = now - ACTIVATION_TIME;
        if (secondsPassed >= exitFeeFallDuration_) {
            return finalExitFee_;
        }
        uint8 totalChange = startExitFee_ - finalExitFee_;
        uint8 currentChange = uint8(totalChange * secondsPassed / exitFeeFallDuration_);
        uint8 currentFee = startExitFee_- currentChange;
        return currentFee;
    }

     

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy, bool _isReinvest)
        antiEarlyWhale(_incomingEthereum, _isReinvest)
        internal
        returns(uint256)
    {
         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.div(_undividedDividends, 3));
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _fundPayout);
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], SafeMath.div(_undividedDividends, 3));
        } else {
             
             
            _dividends = SafeMath.add(_dividends, SafeMath.div(_undividedDividends, 3));
            _fee = _dividends * magnitude;
        }

         
        if(tokenSupply_ > 0){

             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);

         
         
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[msg.sender] += _updatedPayouts;

         
        emit onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy, _isReinvest, now, buyPrice());

        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                 
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
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

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
             
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }


     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
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