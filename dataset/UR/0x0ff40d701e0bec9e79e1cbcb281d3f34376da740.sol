 

pragma solidity ^0.4.19;
 
 

contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
 
 
 
interface tokenRecipient {
	
	function receiveApproval(address _from, uint256 _tokenAmountApproved, address tokenMacroansy, bytes _extraData) public returns(bool success); 
}   
 
 
    interface ICO {

        function buy( uint payment, address buyer, bool isPreview) public returns(bool success, uint amount);
        function redeemCoin(uint256 amount, address redeemer, bool isPreview) public returns (bool success, uint redeemPayment);
        function sell(uint256 amount, address seller, bool isPreview) public returns (bool success, uint sellPayment );
        function paymentAction(uint paymentValue, address beneficiary, uint paytype) public returns(bool success);

        function recvShrICO( address _spender, uint256 _value, uint ShrID)  public returns (bool success);
        function burn( uint256 value, bool unburn, uint totalSupplyStart, uint balOfOwner)  public returns( bool success);

        function getSCF() public returns(uint seriesCapFactorMulByTenPowerEighteen);
        function getMinBal() public returns(uint minBalForAccnts_ );
        function getAvlShares(bool show) public  returns(uint totalSupplyOfCoinsInSeriesNow, uint coinsAvailableForSale, uint icoFunding);
    }
 
 
    interface Exchg{
        
        function sell_Exchg_Reg( uint amntTkns, uint tknPrice, address seller) public returns(bool success);
        function buy_Exchg_booking( address seller, uint amntTkns, uint tknPrice, address buyer, uint payment ) public returns(bool success);
        function buy_Exchg_BkgChk( address seller, uint amntTkns, uint tknPrice, address buyer, uint payment) public returns(bool success);
        function updateSeller( address seller, uint tknsApr, address buyer, uint payment) public returns(bool success);  

        function getExchgComisnMulByThousand() public returns(uint exchgCommissionMulByThousand_);  

        function viewSellOffersAtExchangeMacroansy(address seller, bool show) view public returns (uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint sellerBookedTime, address buyerWhoBooked, uint buyPaymentBooked, uint buyerBookedTime, uint exchgCommissionMulByThousand_);
    }
 

 
 

 
 
    contract TokenERC20Interface {

        function totalSupply() public constant returns (uint coinLifeTimeTotalSupply);
        function balanceOf(address tokenOwner) public constant returns (uint coinBalance);
        function allowance(address tokenOwner, address spender) public constant returns (uint coinsRemaining);
        function transfer(address to, uint tokens) public returns (bool success);
        function approve(address spender, uint tokens) public returns (bool success);
        function transferFrom(address _from, address to, uint tokens) public returns (bool success);
        event Transfer(address indexed _from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
 
 
 
 
contract TokenMacroansy is TokenERC20Interface, SafeMath { 
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    address internal owner; 
    address private  beneficiaryFunds;
     
    uint256 public totalSupply;
    uint256 internal totalSupplyStart;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping( address => bool) internal frozenAccount;
     
    mapping(address => uint) private msgSndr;
     
    address tkn_addr; address ico_addr; address exchg_addr;
     
    uint256 internal allowedIndividualShare;
    uint256 internal allowedPublicShare;
 
     
     
     
     
 

    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint amount);
    event UnBurn(address indexed from, uint amount);
    event FundOrPaymentTransfer(address beneficiary, uint amount); 
    event FrozenFunds(address target, bool frozen);
    event BuyAtMacroansyExchg(address buyer, address seller, uint tokenAmount, uint payment);
 
 
 
     
    function TokenMacroansy()  public {
        
        owner = msg.sender;
        beneficiaryFunds = owner;
         
        totalSupplyStart = 3999 * 10** uint256(decimals);     
        totalSupply = totalSupplyStart; 
         
        balanceOf[msg.sender] = totalSupplyStart;    
        Transfer(address(0), msg.sender, totalSupplyStart);
         
        name = "TokenMacroansy";  
        symbol = "$BEE";
         
        allowedIndividualShare = uint(1)*totalSupplyStart/100; 
        allowedPublicShare = uint(20)* totalSupplyStart/100;     
         
         
         
         
         
    } 
 

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
    function wadmin_transferOr(address _Or) public onlyOwner {
        owner = _Or;
    }          
 
    
    function totalSupply() constant public returns (uint coinLifeTimeTotalSupply) {
        return totalSupply ;   
    }  
 
    
    function balanceOf(address tokenOwner) constant public  returns (uint coinBalance) {
        return balanceOf[tokenOwner];
    } 
 
    
    function allowance(address tokenOwner, address spender) constant public returns (uint coinsRemaining) {
        return allowance[tokenOwner][spender];
    }
 
 
    function wadmin_setContrAddr(address icoAddr, address exchAddr ) public onlyOwner returns(bool success){
       tkn_addr = this; ico_addr = icoAddr; exchg_addr = exchAddr;
       return true;
    }          
     
    function _getTknAddr() internal  returns(address tkn_ma_addr){  return(tkn_addr); }
    function _getIcoAddr() internal  returns(address ico_ma_addr){  return(ico_addr); } 
    function _getExchgAddr() internal returns(address exchg_ma_addr){ return(exchg_addr); } 
     
     
 
 
     
     
    function _transfer(address _from, address _to, uint _value) internal  {
        require (_to != 0x0);                                       
        require(!frozenAccount[_from]);                             
        require(!frozenAccount[_to]);                               
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;                       
        require (balanceOf[_from] >= _valueA);                       
        require (balanceOf[_to] + _valueA > balanceOf[_to]);                   
        uint previousBalances = balanceOf[_from] + balanceOf[_to];                               
        balanceOf[_from] = safeSub(balanceOf[_from], _valueA);                                  
        balanceOf[_to] = safeAdd(balanceOf[_to], _valueA); 
        Transfer(_from, _to, _valueA);
        _valueA = 0;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);       
    }
 
     
     function transfer(address _to, uint256 _value) public returns(bool success) {

         
        bool sucsSlrLmt = _chkSellerLmts( msg.sender, _value);
        bool sucsByrLmt = _chkBuyerLmts( _to, _value);
        require(sucsSlrLmt == true && sucsByrLmt == true);
         
        uint valtmp = _value;    
        uint _valueTemp = valtmp; 
        valtmp = 0;                 
        _transfer(msg.sender, _to, _valueTemp);
        _valueTemp = 0;
        return true;      
    }  
 
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;
        require(_valueA <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _valueA);
        _transfer(_from, _to, _valueA);
        _valueA = 0;
        return true;
    }
 
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
         
        bool sucsSlrLmt = _chkSellerLmts( msg.sender, _value);
        bool sucsByrLmt = _chkBuyerLmts( _spender, _value);
        require(sucsSlrLmt == true && sucsByrLmt == true);
         
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;         
        allowance[msg.sender][_spender] = _valueA;
        Approval(msg.sender, _spender, _valueA);
         _valueA =0;
        return true;
    }
 
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        
        tokenRecipient spender = tokenRecipient(_spender);
        uint valtmp = _value;
        uint _valueA = valtmp;
        valtmp = 0;         
        if (approve(_spender, _valueA)) {           
            spender.receiveApproval(msg.sender, _valueA, this, _extraData);            
        }
        _valueA = 0; 
        return true;
    }
 
 
     
    function wadmin_freezeAccount(address target, bool freeze) onlyOwner public returns(bool success) {
        frozenAccount[target] = freeze;      
        FrozenFunds(target, freeze);
        return true;
    }
 
 
    function _safeTransferTkn( address _from, address _to, uint amount) internal returns(bool sucsTrTk){
          
          uint tkA = amount;
          uint tkAtemp = tkA;
          tkA = 0;
                   _transfer(_from, _to, tkAtemp); 
          tkAtemp = 0;
          return true;
    }      
 
 
    function _safeTransferPaymnt( address paymentBenfcry, uint payment) internal returns(bool sucsTrPaymnt){
              
          uint pA = payment; 
          uint paymentTemp = pA;
          pA = 0;
                  paymentBenfcry.transfer(paymentTemp); 
          FundOrPaymentTransfer(paymentBenfcry, paymentTemp);                       
          paymentTemp = 0; 
          
          return true;
    }
 
 
    function _safePaymentActionAtIco( uint payment, address paymentBenfcry, uint paytype) internal returns(bool success){
              
     
          uint Pm = payment;
          uint PmTemp = Pm;
          Pm = 0;  
          ICO ico = ICO(_getIcoAddr());       
           
          bool pymActSucs = ico.paymentAction( PmTemp, paymentBenfcry, paytype);
          require(pymActSucs ==  true);
          PmTemp = 0;
          
          return true;
    }

 
     
    function buyCoinsAtICO() payable public returns(bool success) { 

        msgSndr[msg.sender] = msg.value;

        ICO ico = ICO(_getIcoAddr() );

        require(  msg.value > 0 );
        
         
        bool icosuccess;  uint tknsBuyAppr;        
        (icosuccess, tknsBuyAppr) = ico.buy( msg.value, msg.sender, false);        
                require( icosuccess == true );
        
         
        bool sucsTrTk =  _safeTransferTkn( owner, msg.sender, tknsBuyAppr);
        require(sucsTrTk == true);

        msgSndr[msg.sender] = 0;

        return (true) ;
    }     
 
 
     

    function buyCoinsPreview(uint myProposedPaymentInWEI) public view returns(bool success, uint tokensYouCanBuy, uint yourSafeMinBalReqdInWEI) { 
        
        uint payment = myProposedPaymentInWEI;
       
        msgSndr[msg.sender] = payment;  
        success = false;
        
        ICO ico = ICO(_getIcoAddr() );

        tokensYouCanBuy = 0;
        bool icosuccess;            
        (icosuccess, tokensYouCanBuy) = ico.buy( payment, msg.sender, true);        

        msgSndr[msg.sender] = 0;

        return ( icosuccess, tokensYouCanBuy, ico.getMinBal()) ;
    }
 
      
    function redeemCoinsToICO( uint256 amountOfCoinsToRedeem) public returns (bool success ) {

    uint amount = amountOfCoinsToRedeem;

    msgSndr[msg.sender] = amount;  
      bool isPreview = false;

      ICO ico = ICO(_getIcoAddr());

       
      bool icosuccess ; uint redeemPaymentValue;
      (icosuccess , redeemPaymentValue) = ico.redeemCoin( amount, msg.sender, isPreview);
      require( icosuccess == true);  

      require( _getIcoAddr().balance >= safeAdd( ico.getMinBal() , redeemPaymentValue) );

      bool sucsTrTk = false; bool pymActSucs = false;
      if(isPreview == false) {

         
        sucsTrTk =  _safeTransferTkn( msg.sender, owner, amount);
        require(sucsTrTk == true);        

         
      msgSndr[msg.sender] = redeemPaymentValue;
        pymActSucs = _safePaymentActionAtIco( redeemPaymentValue, msg.sender, 1);
        require(pymActSucs ==  true);
      } 

    msgSndr[msg.sender] = 0;  

      return (true);        
    } 
 
         
     function sellCoinsToICO( uint256 amountOfCoinsToSell ) public returns (bool success ) {

      uint amount = amountOfCoinsToSell;

      msgSndr[msg.sender] = amount;  
        bool isPreview = false;

        ICO ico = ICO(_getIcoAddr() );

         
        bool icosuccess; uint sellPaymentValue; 
        ( icosuccess ,  sellPaymentValue) = ico.sell( amount, msg.sender, isPreview);
        require( icosuccess == true );

        require( _getIcoAddr().balance >= safeAdd(ico.getMinBal() , sellPaymentValue) );

        bool sucsTrTk = false; bool pymActSucs = false;
        if(isPreview == false){

           
          sucsTrTk =  _safeTransferTkn( msg.sender, owner,  amount);
          require(sucsTrTk == true);

           
        msgSndr[msg.sender] = sellPaymentValue;
          pymActSucs = _safePaymentActionAtIco( sellPaymentValue, msg.sender, 2);
          require(pymActSucs ==  true);
        }

      msgSndr[msg.sender] = 0;

        return ( true);                
    }
 
     
     
    function _chkSellerLmts( address seller, uint amountOfCoinsSellerCanSell) internal returns(bool success){   

      uint amountTkns = amountOfCoinsSellerCanSell; 
      success = false;
      ICO ico = ICO( _getIcoAddr() );
      uint seriesCapFactor = ico.getSCF();

      if( amountTkns <= balanceOf[seller]  &&  balanceOf[seller] <=  safeDiv(allowedIndividualShare*seriesCapFactor,10**18) ){
        success = true;
      }
      return success;
    }
     
 
 
     
    function _chkBuyerLmts( address buyer, uint amountOfCoinsBuyerCanBuy)  internal  returns(bool success){

    	uint amountTkns = amountOfCoinsBuyerCanBuy;
        success = false;
        ICO ico = ICO( _getIcoAddr() );
        uint seriesCapFactor = ico.getSCF();

        if( amountTkns <= safeSub( safeDiv(allowedIndividualShare*seriesCapFactor,10**18), balanceOf[buyer] )) {
          success = true;
        } 
        return success;        
    }
 
 
     
    function _chkBuyerLmtsAndFinl( address buyer, uint amountTkns, uint priceOfr) internal returns(bool success){
       
       success = false;

       
       bool sucs1 = false; 
       sucs1 = _chkBuyerLmts( buyer, amountTkns);

       
       ICO ico = ICO( _getIcoAddr() );
       bool sucs2 = false;
       if( buyer.balance >=  safeAdd( safeMul(amountTkns , priceOfr) , ico.getMinBal() )  )  sucs2 = true;
       if( sucs1 == true && sucs2 == true)  success = true;   

       return success;
    }
 
 
     function _slrByrLmtChk( address seller, uint amountTkns, uint priceOfr, address buyer) internal returns(bool success){
     
       
        bool successSlrl; 
        (successSlrl) = _chkSellerLmts( seller, amountTkns); 

       
        bool successByrlAFinl;
        (successByrlAFinl) = _chkBuyerLmtsAndFinl( buyer, amountTkns, priceOfr);
        
        require( successSlrl == true && successByrlAFinl == true);

        return true;
    }
 
     
      function sellBkgAtExchg( uint amountOfCoinsOffer, uint priceOfOneCoinInWEI) public returns(bool success){

        uint amntTkns = amountOfCoinsOffer ;
        uint tknPrice = priceOfOneCoinInWEI;
      
         
        bool successSlrl;
        (successSlrl) = _chkSellerLmts( msg.sender, amntTkns); 
        require(successSlrl == true);

      msgSndr[msg.sender] = amntTkns;  

       

        Exchg em = Exchg(_getExchgAddr());

        bool  emsuccess; 
        (emsuccess) = em.sell_Exchg_Reg( amntTkns, tknPrice, msg.sender );
        require(emsuccess == true );
            
      msgSndr[msg.sender] = 0;

        return true;         
    }
 
 
       
      function buyBkgAtExchg( address seller, uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint myProposedPaymentInWEI) public returns(bool success){ 
        
        uint amountTkns = sellersCoinAmountOffer;
        uint priceOfr = sellersPriceOfOneCoinInWEI;
        uint payment = myProposedPaymentInWEI;         
    
      msgSndr[msg.sender] = amountTkns;

         
        bool sucsLmt = _slrByrLmtChk( seller, amountTkns, priceOfr, msg.sender);
        require(sucsLmt == true);

         
     
        Exchg em = Exchg(_getExchgAddr()); 

        bool emBkgsuccess;
        (emBkgsuccess)= em.buy_Exchg_booking( seller, amountTkns, priceOfr, msg.sender, payment);
            require( emBkgsuccess == true );

      msgSndr[msg.sender] = 0;  

        return true;        
    }
 

     
    

    function buyCoinsAtExchg( address seller, uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI) payable public returns(bool success) {
       
        uint amountTkns = sellersCoinAmountOffer;
        uint priceOfr = sellersPriceOfOneCoinInWEI;	       
        require( msg.value > 0 && msg.value <= safeMul(amountTkns, priceOfr ) );

      msgSndr[msg.sender] = amountTkns;

         
  
        uint tknsBuyAppr = safeDiv(msg.value , priceOfr);

         
  
        Exchg em = Exchg(_getExchgAddr()); 
        
        bool sucsBkgChk = em.buy_Exchg_BkgChk(seller, amountTkns, priceOfr, msg.sender, msg.value); 
        require(sucsBkgChk == true);

        

      msgSndr[msg.sender] = tknsBuyAppr;  
 
        bool emUpdateSuccess;
        (emUpdateSuccess) = em.updateSeller(seller, tknsBuyAppr, msg.sender, msg.value); 
        require( emUpdateSuccess == true );
        
        

        bool sucsTrTkn = _safeTransferTkn( seller, msg.sender, tknsBuyAppr);
        require(sucsTrTkn == true);

         
        bool sucsTrPaymnt;
        sucsTrPaymnt = _safeTransferPaymnt( seller,  safeSub( msg.value , safeDiv(msg.value*em.getExchgComisnMulByThousand(),1000) ) );
        require(sucsTrPaymnt == true );
        
        BuyAtMacroansyExchg(msg.sender, seller, tknsBuyAppr, msg.value);  

      msgSndr[msg.sender] = 0; 
        
        return true;
    } 
 

    
    function () public payable {
        if(msg.sender != owner) revert();
    }
 

     
    function wadmin_burn( uint256 value, bool unburn) onlyOwner public returns( bool success ) { 

        msgSndr[msg.sender] = value;
         ICO ico = ICO( _getIcoAddr() );
            if( unburn == false) {

                balanceOf[owner] = safeSub( balanceOf[owner] , value);
                totalSupply = safeSub( totalSupply, value);
                Burn(owner, value);

            }
            if( unburn == true) {

                balanceOf[owner] = safeAdd( balanceOf[owner] , value);
                totalSupply = safeAdd( totalSupply , value);
                UnBurn(owner, value);

            }
        
        bool icosuccess = ico.burn( value, unburn, totalSupplyStart, balanceOf[owner] );
        require( icosuccess == true);             
        
        return true;                     
    }
 
     
    function wadmin_withdrawFund(uint withdrawAmount) onlyOwner public returns(bool success) {
      
        success = _withdraw(withdrawAmount);          
        return success;      
    }   
 
      
    function _withdraw(uint _withdrawAmount) internal returns(bool success) {

        bool sucsTrPaymnt = _safeTransferPaymnt( beneficiaryFunds, _withdrawAmount); 
        require(sucsTrPaymnt == true);         
        return true;     
    }
 
      
    function receiveICOcoins( uint256 amountOfCoinsToReceive, uint ShrID )  public returns (bool success){ 

      msgSndr[msg.sender] = amountOfCoinsToReceive;
        ICO ico = ICO( _getIcoAddr() );
        bool  icosuccess;  
        icosuccess = ico.recvShrICO(msg.sender, amountOfCoinsToReceive, ShrID ); 
        require (icosuccess == true);

        bool sucsTrTk;
        sucsTrTk =  _safeTransferTkn( owner, msg.sender, amountOfCoinsToReceive);
        require(sucsTrTk == true);

      msgSndr[msg.sender] = 0;

        return  true;
    }
 
 
    function sendMsgSndr(address caller, address origin) public returns(bool success, uint value){
        
        (success, value) = _sendMsgSndr(caller, origin);        
         return(success, value);  
    }
 
 
    function _sendMsgSndr(address caller,  address origin) internal returns(bool success, uint value){ 
       
        require(caller == _getIcoAddr() || caller == _getExchgAddr()); 
           
        return(true, msgSndr[origin]);  
    }
 
 
    function a_viewSellOffersAtExchangeMacroansy(address seller, bool show) view public returns (uint sellersCoinAmountOffer, uint sellersPriceOfOneCoinInWEI, uint sellerBookedTime, address buyerWhoBooked, uint buyPaymentBooked, uint buyerBookedTime, uint exchgCommissionMulByThousand_){

      if(show == true){

          Exchg em = Exchg(_getExchgAddr()); 
         
        ( sellersCoinAmountOffer,  sellersPriceOfOneCoinInWEI,  sellerBookedTime,  buyerWhoBooked,  buyPaymentBooked,  buyerBookedTime, exchgCommissionMulByThousand_) = em.viewSellOffersAtExchangeMacroansy( seller, show) ; 

        return ( sellersCoinAmountOffer,  sellersPriceOfOneCoinInWEI,  sellerBookedTime,  buyerWhoBooked,  buyPaymentBooked,  buyerBookedTime, exchgCommissionMulByThousand_);
      }
    }
 
 
	function a_viewCoinSupplyAndFunding(bool show) public view returns(uint totalSupplyOfCoinsInSeriesNow, uint coinsAvailableForSale, uint icoFunding){

	    if(show == true){
	      ICO ico = ICO( _getIcoAddr() );

	      ( totalSupplyOfCoinsInSeriesNow, coinsAvailableForSale, icoFunding) = ico.getAvlShares(show);

	      return( totalSupplyOfCoinsInSeriesNow, coinsAvailableForSale, icoFunding);
	    }
	}
 
 
			 
 
}
 