 

pragma solidity ^0.4.24;



contract _8thereum {



     
     
    modifier onlyTokenHolders() 
    {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyDividendPositive() 
    {
        require(myDividends(true) > 0);
        _;
    }

     
    modifier onlyOwner() 
    { 
        require (address(msg.sender) == owner); 
        _; 
    }
    
     
    modifier onlyNonOwner() 
    { 
        require (address(msg.sender) != owner); 
        _; 
    }
    
    modifier onlyFoundersIfNotPublic() 
    {
        if(!openToThePublic)
        {
            require (founders[address(msg.sender)] == true);   
        }
        _;
    }    
    
    modifier onlyApprovedContracts()
    {
        if(!gameList[msg.sender])
        {
            require (msg.sender == tx.origin);
        }
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
    
    event lotteryPayout(
        address customerAddress, 
        uint256 lotterySupply
    );
    
    event whaleDump(
        uint256 amount
    );
    
     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
     
    string public name = "8thereum";
    string public symbol = "BIT";
    bool public openToThePublic = false;
    address public owner;
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee = 15;
    uint256 constant internal tokenPrice = 500000000000000; 
    uint256 constant internal magnitude = 2**64;
    uint256 constant public referralLinkRequirement = 5e18; 
    
    
    mapping(address => bool) internal gameList;
    mapping(address => uint256) internal publicTokenLedger;
    mapping(address => uint256) public   whaleLedger;
    mapping(address => uint256) public   gameLedger;
    mapping(address => uint256) internal referralBalances;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => mapping(address => uint256)) public gamePlayers;
    mapping(address => bool) internal founders;
    address[] lotteryPlayers;
    uint256 internal lotterySupply = 0;
    uint256 internal tokenSupply = 0;
    uint256 internal gameSuppply = 0;
    uint256 internal profitPerShare_;
    
     
     
    constructor()
        public
    {
         
        owner = address(msg.sender);

         
        founders[owner] = true;  
        founders[0x7e474fe5Cfb720804860215f407111183cbc2f85] = true;  
        founders[0x5138240E96360ad64010C27eB0c685A8b2eDE4F2] = true;  
        founders[0xAA7A7C2DECB180f68F11E975e6D92B5Dc06083A6] = true;  
        founders[0x6DC622a04Fd13B6a1C3C5B229CA642b8e50e1e74] = true;  
        founders[0x41a21b264F9ebF6cF571D4543a5b3AB1c6bEd98C] = true;  
    }
    
     
     
    function buy(address referredyBy)
        onlyFoundersIfNotPublic()
        public
        payable
        returns(uint256)
    {
        require (msg.sender == tx.origin);
        excludeWhale(referredyBy); 
    }
    
     
    function()
        onlyFoundersIfNotPublic()
        payable
        public
    {
        require (msg.sender == tx.origin);
        excludeWhale(0x0); 
    }
    
     
    function reinvest()
        onlyDividendPositive()
        onlyNonOwner()
        public
    {   
        
        require (msg.sender == tx.origin);
        
         
        uint256 dividends = myDividends(false);  
        
         
        address customerAddress = msg.sender;
        payoutsTo_[customerAddress] +=  int256(SafeMath.mul(dividends, magnitude));
        
         
        dividends += referralBalances[customerAddress];
        referralBalances[customerAddress] = 0;
        
         
        uint256 _tokens = purchaseTokens(dividends, 0x0);
        
         
        emit onReinvestment(customerAddress, dividends, _tokens);
    }
    
     
    function exit()
        onlyNonOwner()
        onlyTokenHolders()
        public
    {
        require (msg.sender == tx.origin);
        
         
        address customerAddress = address(msg.sender);
        uint256 _tokens = publicTokenLedger[customerAddress];
        
        if(_tokens > 0) 
        {
            sell(_tokens);
        }

        withdraw();
    }

     
    function withdraw()
        onlyNonOwner()
        onlyDividendPositive()
        public
    {
        require (msg.sender == tx.origin);
        
         
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(false);  
        
         
        payoutsTo_[customerAddress] +=  int256(SafeMath.mul(dividends, magnitude));
        
         
        dividends += referralBalances[customerAddress];
        referralBalances[customerAddress] = 0;
        
        customerAddress.transfer(dividends);
        
         
        emit onWithdraw(customerAddress, dividends);
    }
    
     
    function sell(uint256 _amountOfTokens)
        onlyNonOwner()
        onlyTokenHolders()
        public
    {
        require (msg.sender == tx.origin);
        require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0));

        uint256 _tokens = _amountOfTokens;
        uint256 ethereum = tokensToEthereum_(_tokens);
        uint256 dividends = (ethereum * dividendFee) / 100;
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        
         
        uint256 lotteryAndWhaleFee = dividends / 3;
        dividends -= lotteryAndWhaleFee;
        
         
        uint256 lotteryFee = lotteryAndWhaleFee / 2;
         
        uint256 whaleFee = lotteryAndWhaleFee - lotteryFee;
        whaleLedger[owner] += whaleFee;
         
        lotterySupply += ethereumToTokens_(lotteryFee);
         
        tokenSupply -=  _tokens;
        publicTokenLedger[msg.sender] -= _tokens;
        
        
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (taxedEthereum * magnitude));
        payoutsTo_[msg.sender] -= _updatedPayouts;  
        
         
        if (tokenSupply > 0) 
        {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (dividends * magnitude) / tokenSupply);
        }
        
         
        emit onTokenSell(msg.sender, _tokens, taxedEthereum);
    }
    
    
     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyNonOwner()
        onlyTokenHolders()
        onlyApprovedContracts()
        public
        returns(bool)
    {
        assert(_toAddress != owner);
        
         
        if(gameList[msg.sender] == true)  
        {
            require((_amountOfTokens <= gameLedger[msg.sender]) && (_amountOfTokens > 0 ));
              
            gameLedger[msg.sender] -= _amountOfTokens;
            gameSuppply -= _amountOfTokens;
            publicTokenLedger[_toAddress] += _amountOfTokens; 
            
             
            payoutsTo_[_toAddress] += int256(profitPerShare_ * _amountOfTokens); 
        }
        else if (gameList[_toAddress] == true)  
        {
             
             
            require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0 && (_amountOfTokens == 1e18)));
             
              
            publicTokenLedger[msg.sender] -=  _amountOfTokens;
            gameLedger[_toAddress] += _amountOfTokens; 
            gameSuppply += _amountOfTokens;
            gamePlayers[_toAddress][msg.sender] += _amountOfTokens;
            
             
            payoutsTo_[msg.sender] -= int256(profitPerShare_ * _amountOfTokens);
        }
        else{
             
            require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0 ));
                 
            publicTokenLedger[msg.sender] -= _amountOfTokens;
            publicTokenLedger[_toAddress] += _amountOfTokens; 
            
             
            payoutsTo_[msg.sender] -= int256(profitPerShare_ * _amountOfTokens);
            payoutsTo_[_toAddress] += int256(profitPerShare_ * _amountOfTokens); 
            
        }
        
         
        emit Transfer(msg.sender, _toAddress, _amountOfTokens); 
        
         
        return true;
       
    }
    
     

     
    function setGames(address newGameAddress)
    onlyOwner()
    public
    {
        gameList[newGameAddress] = true;
    }
    
     
    function goPublic() 
        onlyOwner()
        public 
        returns(bool)

    {
        openToThePublic = true;
        return openToThePublic;
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
        return (tokenSupply + lotterySupply + gameSuppply);  
    }
    
     
    function myTokens()
        public
        view
        returns(uint256)
    {
        return balanceOf(msg.sender);
    }
    
      
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        return _includeReferralBonus ? dividendsOf(msg.sender) + referralBalances[msg.sender] : dividendsOf(msg.sender) ;
    }
    
     
    function balanceOf(address customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 balance;

        if (customerAddress == owner) 
        { 
             
            balance = whaleLedger[customerAddress]; 
        }
        else if(gameList[customerAddress] == true) 
        {
             
            balance = gameLedger[customerAddress];
        }
        else 
        {   
             
            balance = publicTokenLedger[customerAddress];
        }
        return balance;
    }
    
     
    function dividendsOf(address customerAddress)
        view
        public
        returns(uint256)
    {
      return (uint256) ((int256)(profitPerShare_ * publicTokenLedger[customerAddress]) - payoutsTo_[customerAddress]) / magnitude;
    }
    
     
    function buyAndSellPrice()
    public
    pure 
    returns(uint256)
    {
        uint256 ethereum = tokenPrice;
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereum, dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }
    
     
    function calculateTokensReceived(uint256 ethereumToSpend) 
        public 
        pure 
        returns(uint256)
    {
        require(ethereumToSpend >= tokenPrice);
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereumToSpend, dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereumToSpend, dividends);
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);
        
        return amountOfTokens;
    }
    
     
    function calculateEthereumReceived(uint256 tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(tokensToSell <= tokenSupply);
        uint256 ethereum = tokensToEthereum_(tokensToSell);
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereum, dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }
    
    
     
    
    
    function excludeWhale(address referredyBy) 
        onlyNonOwner()
        internal 
        returns(uint256) 
    { 
        require (msg.sender == tx.origin);
        uint256 tokenAmount;

        tokenAmount = purchaseTokens(msg.value, referredyBy);  

        if(gameList[msg.sender] == true)
        {
            tokenSupply = SafeMath.sub(tokenSupply, tokenAmount);  
            publicTokenLedger[msg.sender] = SafeMath.sub(publicTokenLedger[msg.sender], tokenAmount);  
            gameLedger[msg.sender] += tokenAmount;     
            gameSuppply += tokenAmount;  
        }

        return tokenAmount;
    }


    function purchaseTokens(uint256 incomingEthereum, address referredyBy)
        internal
        returns(uint256)
    {
        require (msg.sender == tx.origin);
         
        uint256 undividedDivs = SafeMath.div(SafeMath.mul(incomingEthereum, dividendFee ), 100);
        
         
        uint256 lotteryAndWhaleFee = undividedDivs / 3;
        uint256 referralBonus = lotteryAndWhaleFee;
        uint256 dividends = SafeMath.sub(undividedDivs, (referralBonus + lotteryAndWhaleFee));
        uint256 taxedEthereum = incomingEthereum - undividedDivs;
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);
        uint256 whaleFee = lotteryAndWhaleFee / 2;
         
        whaleLedger[owner] += whaleFee;
        
         
        lotterySupply += ethereumToTokens_(lotteryAndWhaleFee - whaleFee);
        
         
        lotteryPlayers.push(msg.sender);
       
        uint256 fee = dividends * magnitude;
 
        require(amountOfTokens > 0 && (amountOfTokens + tokenSupply) > tokenSupply);
        
         
        if(
             
            referredyBy != 0x0000000000000000000000000000000000000000 &&

             
            referredyBy != msg.sender && 
            
             
            gameList[referredyBy] == false  &&
            
             
            publicTokenLedger[referredyBy] >= referralLinkRequirement
        )
        {
             
            referralBalances[referredyBy] += referralBonus;
        } else
        {
             
             
            dividends += referralBonus;
            fee = dividends * magnitude;
        }

        uint256 payoutDividends = isWhalePaying();
        
         
        if(tokenSupply > 0)
        {
             
            tokenSupply += amountOfTokens;
            
              
            profitPerShare_ += ((payoutDividends + dividends) * magnitude / (tokenSupply));
            
             
            fee -= fee-(amountOfTokens * (dividends * magnitude / (tokenSupply)));
        } else 
        {
             
            tokenSupply = amountOfTokens;
            
             
            if(whaleLedger[owner] == 0)
            {
                whaleLedger[owner] = payoutDividends;
            }
        }

         
        publicTokenLedger[msg.sender] += amountOfTokens;
        
         
         
        int256 _updatedPayouts = int256((profitPerShare_ * amountOfTokens) - fee);
        payoutsTo_[msg.sender] += _updatedPayouts;
        
     
         
        emit onTokenPurchase(msg.sender, incomingEthereum, amountOfTokens, referredyBy);
        
        return amountOfTokens;
    }
    
    
      
    function isWhalePaying()
    private
    returns(uint256)
    {
        uint256 payoutDividends = 0;
          
        if(whaleLedger[owner] >= 1 ether)
        {
            if(lotteryPlayers.length > 0)
            {
                uint256 winner = uint256(blockhash(block.number-1))%lotteryPlayers.length;
                
                publicTokenLedger[lotteryPlayers[winner]] += lotterySupply;
                emit lotteryPayout(lotteryPlayers[winner], lotterySupply);
                tokenSupply += lotterySupply;
                lotterySupply = 0;
                delete lotteryPlayers;
               
            }
             
            payoutDividends = whaleLedger[owner];
            whaleLedger[owner] = 0;
            emit whaleDump(payoutDividends);
        }
        return payoutDividends;
    }

     
    function ethereumToTokens_(uint256 ethereum)
        internal
        pure
        returns(uint256)
    {
        uint256 tokensReceived = ((ethereum / tokenPrice) * 1e18);
               
        return tokensReceived;
    }
    
     
     function tokensToEthereum_(uint256 coin)
        internal
        pure
        returns(uint256)
    {
        uint256 ethReceived = tokenPrice * (SafeMath.div(coin, 1e18));
        
        return ethReceived;
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