 

pragma solidity ^0.4.20;  


 
contract DailyDivsSavings{
  using SafeMath for uint;
  address public ceo;
  address public ceo2;
  mapping(address => address) public referrer; 
  mapping(address => uint256) public referralsHeld; 
  mapping(address => uint256) public refBuys; 
  mapping(address => uint256) public tokenBalanceLedger_;
  mapping(address => int256) public payoutsTo_;
  uint256 public tokenSupply_ = 0;
  uint256 public profitPerShare_;
  uint256 constant internal magnitude = 2**64;
  uint256 constant internal tokenPriceInitial_ = 0.0000000001 ether;
  uint8 constant internal dividendFee_ = 50;

  event onTokenPurchase(
      address indexed customerAddress,
      uint256 incomingEthereum,
      uint256 tokensMinted,
      address indexed referredBy
  );
   event onTokenSell(
       address indexed customerAddress,
       uint256 tokensBurned,
       uint256 ethereumEarned
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

   function DailyDivsSavings() public{
     ceo=msg.sender;
     ceo2=0x93c5371707D2e015aEB94DeCBC7892eC1fa8dd80;
   }

  function ethereumToTokens_(uint _ethereum) public view returns(uint){
     
    return _ethereum.div(tokenPriceInitial_);
  }
  function tokensToEthereum_(uint _tokens) public view returns(uint){
    return tokenPriceInitial_.mul(_tokens);
  }
  function myHalfDividends() public view returns(uint){
    return (dividendsOf(msg.sender)*98)/200; 
  }
  function myDividends()
    public
    view
    returns(uint256)
  {
      return dividendsOf(msg.sender) ;
  }
  function dividendsOf(address _customerAddress)
      view
      public
      returns(uint)
  {
      return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }
  function balance() public view returns(uint256){
    return address(this).balance;
  }
  function mySavings() public view returns(uint){
    return tokensToEthereum_(tokenBalanceLedger_[msg.sender]);
  }
  function depositNoRef() public payable{
    deposit(0);
  }
  function deposit(address ref) public payable{
    require(ref!=msg.sender);
    if(referrer[msg.sender]==0 && ref!=0){
      referrer[msg.sender]=ref;
      refBuys[ref]+=1;
    }

    purchaseTokens(msg.value);
  }
  function purchaseTokens(uint _incomingEthereum) private
    {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _dividends = _undividedDividends;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens.add(tokenSupply_) > tokenSupply_);



         
        if(tokenSupply_ > 0){

             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

         
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

         
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, 0);

         
    }
    function sell(uint _amountOfEth) public {
      reinvest();
      sell_(ethereumToTokens_(_amountOfEth));
      withdraw();
    }
    function withdraw()
    private
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();  

         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
         
         

         
        _customerAddress.transfer(_dividends);

         
        onWithdraw(_customerAddress, _dividends);
    }
    function sell_(uint256 _amountOfTokens)
        private
    {
         
        address _customerAddress = msg.sender;
        require(tokenBalanceLedger_[_customerAddress]>0);
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
         
        uint256 _taxedEthereum = _ethereum; 

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
         
             
             
         

         
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    function reinvest()
    public
    {
         
        uint256 _dividends = myDividends();  
        require(_dividends>1);
         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
         
         

        uint halfDivs=_dividends.div(2);

         
        if(ethereumToTokens_(halfDivs.add(referralsHeld[msg.sender]))>0){
          purchaseTokens(halfDivs.add(referralsHeld[msg.sender])); 
          referralsHeld[msg.sender]=0;
        }

         

        address refaddr=referrer[_customerAddress];
        if(refaddr==0){
          uint quarterDivs=halfDivs.div(2);
          referralsHeld[ceo]=referralsHeld[ceo].add(quarterDivs);
          referralsHeld[ceo2]=referralsHeld[ceo2].add(quarterDivs);
        }
        else{
          referralsHeld[refaddr]=referralsHeld[refaddr].add(halfDivs);
        }

         
        onReinvestment(_customerAddress, _dividends, halfDivs);
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