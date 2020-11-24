 

pragma solidity ^0.4.24;



contract SHT_Token 
{

     
     
    modifier onlyTokenHolders() 
    {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyDividendPositive() 
    {
        require(myDividends() > 0);
        _;
    }

     
    modifier onlyOwner() 
    { 
        require (address(msg.sender) == owner); 
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

     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
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
    
    
     
    string public name = "SHT Token";
    string public symbol = "SHT";
    bool public openToThePublic = false;
    address public owner;
    address public dev;
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee = 10;   
    uint8 constant internal lotteryFee = 5; 
    uint8 constant internal devFee = 5; 
    uint8 constant internal ob2Fee = 2;  
    uint256 constant internal tokenPrice = 400000000000000;   
    uint256 constant internal magnitude = 2**64;
    Onigiri2 private ob2; 
   

    
    
    mapping(address => uint256) internal publicTokenLedger;
    mapping(address => uint256) public   whaleLedger;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => bool) internal founders;
    address[] lotteryPlayers;
    uint256 internal lotterySupply = 0;
    uint256 internal tokenSupply = 0;
    uint256 internal profitPerShare_;
    
     
     
    constructor()
        public
    {
         
        owner = address(msg.sender);

        dev = address(0x7e474fe5Cfb720804860215f407111183cbc2f85);  

         
        founders[0x013f3B8C9F1c4f2f28Fd9cc1E1CF3675Ae920c76] = true;  
        founders[0xF57924672D6dBF0336c618fDa50E284E02715000] = true;  
        founders[0xE4Cf94e5D30FB4406A2B139CD0e872a1C8012dEf] = true;  

         
        ob2 = Onigiri2(0xb8a68f9B8363AF79dEf5c5e11B12e8A258cE5be8);  
    }
    
     
     
    function buy()
        onlyFoundersIfNotPublic()
        public
        payable
        returns(uint256)
    {
        require (msg.sender == tx.origin);
         uint256 tokenAmount;

        tokenAmount = purchaseTokens(msg.value);  

        return tokenAmount;
    }
    
     
    function()
        payable
        public
    {
       buy();
    }
    
     
    function reinvest()
        onlyDividendPositive()
        public
    {   
        require (msg.sender == tx.origin);
        
         
        uint256 dividends = myDividends(); 
        
         
        address customerAddress = msg.sender;
        payoutsTo_[customerAddress] +=  int256(dividends * magnitude);
        
         
        uint256 _tokens = purchaseTokens(dividends);
        
         
        emit onReinvestment(customerAddress, dividends, _tokens);
    }
    
     
    function exit()
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
        onlyDividendPositive()
        public
    {
        require (msg.sender == tx.origin);
        
         
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(); 
        
         
        payoutsTo_[customerAddress] +=  int256(dividends * magnitude);
        
        customerAddress.transfer(dividends);
        
         
        emit onWithdraw(customerAddress, dividends);
    }
    
     
    function sell(uint256 _amountOfTokens)
        onlyTokenHolders()
        public
    {
        require (msg.sender == tx.origin);
        require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0));

        uint256 _tokens = _amountOfTokens;
        uint256 ethereum = tokensToEthereum_(_tokens);

        uint256 undividedDivs = SafeMath.div(ethereum, dividendFee);
        
         
        uint256 communityDivs = SafeMath.div(undividedDivs, 2);  
        uint256 ob2Divs = SafeMath.div(undividedDivs, 4);  
        uint256 lotteryDivs = SafeMath.div(undividedDivs, 10);  
        uint256 tip4Dev = lotteryDivs;
        uint256 whaleDivs = SafeMath.sub(communityDivs, (ob2Divs + lotteryDivs));   


         
        uint256 dividends = SafeMath.sub(undividedDivs, (ob2Divs + lotteryDivs + whaleDivs));

        uint256 taxedEthereum = SafeMath.sub(ethereum, (undividedDivs + tip4Dev));

         
        whaleLedger[owner] += whaleDivs;
        
         
        lotterySupply += ethereumToTokens_(lotteryDivs);

         
        ob2.fromGame.value(ob2Divs)();

         
        dev.transfer(tip4Dev);
        
         
        tokenSupply -=  _tokens;
        publicTokenLedger[msg.sender] -= _tokens;
        
        
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (taxedEthereum * magnitude));
        payoutsTo_[msg.sender] -= _updatedPayouts;  
        
         
        if (tokenSupply > 0) 
        {
             
            profitPerShare_ += ((dividends * magnitude) / tokenSupply);
        }
        
         
        emit onTokenSell(msg.sender, _tokens, taxedEthereum);
    }
    
    
     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyTokenHolders()
        public
        returns(bool)
    {
        assert(_toAddress != owner);
        
         
        require((_amountOfTokens <= publicTokenLedger[msg.sender]) && (_amountOfTokens > 0 ));
             
        publicTokenLedger[msg.sender] -= _amountOfTokens;
        publicTokenLedger[_toAddress] += _amountOfTokens; 
        
         
        payoutsTo_[msg.sender] -= int256(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += int256(profitPerShare_ * _amountOfTokens); 
            
         
        emit Transfer(msg.sender, _toAddress, _amountOfTokens); 

        return true;     
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
        return (tokenSupply + lotterySupply);  
    }
    
     
    function myTokens()
        public
        view
        returns(uint256)
    {
        return balanceOf(msg.sender);
    }

     
    function whaleBalance()
        public
        view
        returns(uint256)
    {
        return  whaleLedger[owner]; 
    }


     
    function lotteryBalance()
        public
        view
        returns(uint256)
    {
        return  lotterySupply; 
    }
    
    
      
    function myDividends() 
        public 
        view 
        returns(uint256)
    {
        return dividendsOf(msg.sender);
    }
    
     
    function balanceOf(address customerAddress)
        view
        public
        returns(uint256)
    {
        return publicTokenLedger[customerAddress];
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
        uint256 dividends = SafeMath.div((ethereum * dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }
    
     
    function calculateTokensReceived(uint256 ethereumToSpend) 
        public 
        pure 
        returns(uint256)
    {
        require(ethereumToSpend >= tokenPrice);
        uint256 dividends = SafeMath.div((ethereumToSpend * dividendFee), 100);
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
        uint256 dividends = SafeMath.div((ethereum * dividendFee ), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }
    
    
     
    
    function purchaseTokens(uint256 incomingEthereum)
        internal
        returns(uint256)
    {
         
        uint256 undividedDivs = SafeMath.div(incomingEthereum, dividendFee);
        
         
        uint256 communityDivs = SafeMath.div(undividedDivs, 2);  
        uint256 ob2Divs = SafeMath.div(undividedDivs, 4);  
        uint256 lotteryDivs = SafeMath.div(undividedDivs, 10);  
        uint256 tip4Dev = lotteryDivs;
        uint256 whaleDivs = SafeMath.sub(communityDivs, (ob2Divs + lotteryDivs));   

         
        uint256 dividends = SafeMath.sub(undividedDivs, (ob2Divs + lotteryDivs + whaleDivs));

        uint256 taxedEthereum = SafeMath.sub(incomingEthereum, (undividedDivs + tip4Dev));
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);

         
        whaleLedger[owner] += whaleDivs;
        
         
        lotterySupply += ethereumToTokens_(lotteryDivs);
        
         
        lotteryPlayers.push(msg.sender);

         
        ob2.fromGame.value(ob2Divs)();

         
        dev.transfer(tip4Dev);
       
        uint256 fee = dividends * magnitude;
 
        require(amountOfTokens > 0 && (amountOfTokens + tokenSupply) > tokenSupply);

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
        
     
         
        emit onTokenPurchase(msg.sender, incomingEthereum, amountOfTokens);
        
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

contract Onigiri2 
{
    function fromGame() external payable;
}


 
library SafeMath {
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}