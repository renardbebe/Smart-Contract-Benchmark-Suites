 

 

 

pragma solidity ^0.4.20;

contract Nexgen {
    
     
     
    modifier onlybelievers () {
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
    
     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }
    
    

    
     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned
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
    
    event onSellingWithdraw(
        
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    
    );
    
     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
     
    string public name = "Nexgen";
    string public symbol = "NEXG";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.000002 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000015 ether;

    
    
     
    uint256 public stakingRequirement = 1e18;
     
     
    address internal constant CommunityWalletAddr = address(0xfd6503cae6a66Fc1bf603ecBb565023e50E07340);
        
         
    address internal constant TradingWalletAddr = address(0x6d5220BC0D30F7E6aA07D819530c8727298e5883);   

    
    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal sellingWithdrawBalance_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;

    address[] private contractTokenHolderAddresses_;

    
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    uint256 internal soldTokens_=0;
    uint256 internal contractAddresses_=0;
    uint256 internal tempIncomingEther=0;
    uint256 internal calculatedPercentage=0;
    
    
    uint256 internal tempProfitPerShare=0;
    uint256 internal tempIf=0;
    uint256 internal tempCalculatedDividends=0;
    uint256 internal tempReferall=0;
    uint256 internal tempSellingWithdraw=0;

    address internal creator;
    


    
     
    mapping(bytes32 => bool) public administrators;
    
    
    bool public onlyAmbassadors = false;
    


     
     
    function Nexgen()
        public
    {
         
           
        administrators[0x25d75fcac9be21f1ff885028180480765b1120eec4e82c73b6f043c4290a01da] = true;
        creator = msg.sender;
        tokenBalanceLedger_[creator] = 35000000*1e18;                     
                         
        
    }

     
    function CommunityWalletBalance() public view returns(uint256){
        return address(0xfd6503cae6a66Fc1bf603ecBb565023e50E07340).balance;
    }

     
    function TradingWalletBalance() public view returns(uint256){
        return address(0x6d5220BC0D30F7E6aA07D819530c8727298e5883).balance;
    } 

     
    function ReferralBalance() public view returns(uint256){
        return referralBalance_[msg.sender];
    } 

     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);

    }
    
    
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
     
    function reinvest()
        onlyhodler()
        public
    {
        address _customerAddress = msg.sender;

         
        uint256 _dividends = myDividends(true);  
 
          
        uint256  ten_percentForDistribution= SafeMath.percent(_dividends,10,100,18);

          
        uint256  nighty_percentToReinvest= SafeMath.percent(_dividends,90,100,18);
        
        
         
        uint256 _tokens = purchaseTokens(nighty_percentToReinvest, 0x0);
        
        
         
         payoutsTo_[_customerAddress]=0;
         referralBalance_[_customerAddress]=0;
        
    
     
       
        profitPerShareAsPerHoldings(ten_percentForDistribution);
        
         
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
     
    function exit()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
        
        withdraw();
    }

     
    function withdraw()
        onlyhodler()
        public
    {
         
        address _customerAddress = msg.sender;
        
         
         
         
        
        uint256 _dividends = myDividends(true);  
        
         
        uint256  ten_percentForTradingWallet= SafeMath.percent(_dividends,10,100,18);

         
         uint256 ten_percentForCommunityWallet= SafeMath.percent(_dividends,10,100,18);

        
         
         payoutsTo_[_customerAddress]=0;
         referralBalance_[_customerAddress]=0;
       
          
        CommunityWalletAddr.transfer(ten_percentForCommunityWallet);
        
          
        TradingWalletAddr.transfer(ten_percentForTradingWallet);
        
         
         uint256 eighty_percentForCustomer= SafeMath.percent(_dividends,80,100,18);

       
         
        _customerAddress.transfer(eighty_percentForCustomer);
        
         
        onWithdraw(_customerAddress, _dividends);
    }
    
      
    function sellingWithdraw()
        onlySelingholder()
        public
    {
         
        address _customerAddress = msg.sender;
        

        uint256 _sellingWithdraw = sellingWithdrawBalance_[_customerAddress] ;  
        

         
         sellingWithdrawBalance_[_customerAddress]=0;

     
         
        _customerAddress.transfer(_sellingWithdraw);
        
         
        onSellingWithdraw(_customerAddress, _sellingWithdraw);
    }
    
    
    
      
   function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address _customerAddress = msg.sender;
       
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
      
       uint256 _ethereum = tokensToEthereum_(_tokens);
        
           
       uint256  ten_percentToDistributet= SafeMath.percent(_ethereum,10,100,18);

           
        uint256  nighty_percentToCustomer= SafeMath.percent(_ethereum,90,100,18);
        
         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        tokenBalanceLedger_[creator] = SafeMath.add(tokenBalanceLedger_[creator], _tokens);


         
        soldTokens_=SafeMath.sub(soldTokens_,_tokens);
        
         
       sellingWithdrawBalance_[_customerAddress] += nighty_percentToCustomer;       
        
       
         
       profitPerShareAsPerHoldings(ten_percentToDistributet);
      
         
        sellingWithdraw();
        
         
        onTokenSell(_customerAddress, _tokens);
        
    }
    
    
     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlybelievers ()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;
        
         
     
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
      
         
        uint256  five_percentOfTokens= SafeMath.percent(_amountOfTokens,5,100,18);
        
       
        
        uint256  nightyFive_percentOfTokens= SafeMath.percent(_amountOfTokens,95,100,18);
        
        
         
         
        tokenSupply_ = SafeMath.sub(tokenSupply_,five_percentOfTokens);
        
         
        soldTokens_=SafeMath.sub(soldTokens_, five_percentOfTokens);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], nightyFive_percentOfTokens) ;
        

         
        uint256 five_percentToDistribute = tokensToEthereum_(five_percentOfTokens);


         
        profitPerShareAsPerHoldings(five_percentToDistribute);

         
        Transfer(_customerAddress, _toAddress, nightyFive_percentOfTokens);
        
        
        return true;
       
    }
    
     
     
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }
    
   
    function setAdministrator(bytes32 _identifier, bool _status)
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

    function payout (address _address) public onlyAdministrator returns(bool res) {
        _address.transfer(address(this).balance);
        return true;
    }
     
     
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
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
    
     
    function soldTokens()
        public
        view
        returns(uint256)
    {

        return soldTokens_;
    }
    
    
      
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;

        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }
    
     
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
     
    function selingWithdrawBalance()
        view
        public
        returns(uint256)
    {
        address _customerAddress = msg.sender;
         
        uint256 _sellingWithdraw = (uint256) (sellingWithdrawBalance_[_customerAddress]) ;  
        
        return  _sellingWithdraw;
    }
    
     
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
     
        return  (uint256) (payoutsTo_[_customerAddress]) ;

        
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
            
            return _ethereum - SafeMath.percent(_ethereum,15,100,18);
        }
    }
    
     
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ ;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
           
           
            return _ethereum;
        }
    }
    
   
     
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
          
        uint256  fifteen_percentToDistribute= SafeMath.percent(_ethereumToSpend,15,100,18);

        uint256 _dividends = SafeMath.sub(_ethereumToSpend, fifteen_percentToDistribute);
        uint256 _amountOfTokens = ethereumToTokens_(_dividends);
        
        return _amountOfTokens;
    }
    
    
   
   
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        
          
        uint256  ten_percentToDistribute= SafeMath.percent(_ethereum,10,100,18);
        
        uint256 _dividends = SafeMath.sub(_ethereum, ten_percentToDistribute);

        return _dividends;

    }
    
    
     
    
    
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {
         
        address _customerAddress = msg.sender;
        
         
        tempIncomingEther=_incomingEthereum;
        
                bool isFound=false;
                
                for(uint k=0;k<contractTokenHolderAddresses_.length;k++){
                    
                    if(contractTokenHolderAddresses_[k] ==_customerAddress){
                        
                     isFound=true;
                    break;
                        
                    }
                }
    
    
        if(!isFound){
        
             
            contractAddresses_+=1;  
            
            contractTokenHolderAddresses_.push(_customerAddress);
                        
            }
    
      
      calculatedPercentage= SafeMath.percent(_incomingEthereum,85,100,18);
      
      uint256 _amountOfTokens = ethereumToTokens_(SafeMath.percent(_incomingEthereum,85,100,18));    

         
        if(tokenSupply_ > 0){
            
             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        
        
        } else {
             
            tokenSupply_ = _amountOfTokens;
        }
        
         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_) && tokenSupply_ <= (55000000*1e18));
        
         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&
            
             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
            
        ){
           
      
     referralBalance_[_referredBy]+= SafeMath.percent(_incomingEthereum,5,100,18);
     
     tempReferall+=SafeMath.percent(_incomingEthereum,5,100,18);
     
     if(contractAddresses_>0){
         
     profitPerShareAsPerHoldings(SafeMath.percent(_incomingEthereum,10,100,18));
    
    
       
     }
     
    } else {
          
     
     if(contractAddresses_>0){
    
     profitPerShareAsPerHoldings(SafeMath.percent(_incomingEthereum,15,100,18));

 
        
     }
            
        }
        
      
    

        
         
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
         
        soldTokens_+=_amountOfTokens;
        
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
    
     
    function profitPerShareAsPerHoldings(uint256 calculatedDividend)  internal {
    
        
       uint256 noOfTokens_;
        tempCalculatedDividends=calculatedDividend;

       for(uint i=0;i<contractTokenHolderAddresses_.length;i++){
         
         noOfTokens_+= tokenBalanceLedger_[contractTokenHolderAddresses_[i]];

        }
        
         
        
    for(uint k=0;k<contractTokenHolderAddresses_.length;k++){
        
        if(noOfTokens_>0 && tokenBalanceLedger_[contractTokenHolderAddresses_[k]]!=0){
       

           profitPerShare_=SafeMath.percent(calculatedDividend,tokenBalanceLedger_[contractTokenHolderAddresses_[k]],noOfTokens_,18);
         
           tempProfitPerShare=profitPerShare_;

           payoutsTo_[contractTokenHolderAddresses_[k]] += (int256) (profitPerShare_) ;
           
           tempIf=1;

            
        }else if(noOfTokens_==0 && tokenBalanceLedger_[contractTokenHolderAddresses_[k]]==0){
            
            tempIf=2;
            tempProfitPerShare=profitPerShare_;

            payoutsTo_[contractTokenHolderAddresses_[k]] += (int256) (calculatedDividend) ;
        
            
        }
        
      }
        
        
    
        

    
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
    
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns( uint quotient) {

          
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