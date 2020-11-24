 

pragma solidity 0.4.23;

 


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
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

contract DivvyUpFactoryInterface {
    function create(
        bytes32 name,  
        bytes32 symbol,   
        uint8 dividendDivisor,  
        uint8 decimals,  
        uint256 initialPrice,  
        uint256 incrementPrice,  
        uint256 magnitude,  
        address counter  
     )
        public 
        returns(address);
}


contract DivvyUpFactory is Owned {

    event Create(
        bytes32 name,
        bytes32 symbol,
        uint8 dividendDivisor,
        uint8 decimals,
        uint256 initialPrice,
        uint256 incrementPrice,
        uint256 magnitude,
        address creator
    );

  
    DivvyUp[] public registry;

    function create(
        bytes32 name,  
        bytes32 symbol,   
        uint8 dividendDivisor,  
        uint8 decimals,  
        uint256 initialPrice,  
        uint256 incrementPrice,  
        uint256 magnitude,  
        address counter  
     )
        public 
        returns(address)
    {
        DivvyUp divvyUp = new DivvyUp(name, symbol, dividendDivisor, decimals, initialPrice, incrementPrice, magnitude, counter);
        divvyUp.changeOwner(msg.sender);
        registry.push(divvyUp);
        emit Create(name, symbol, dividendDivisor, decimals, initialPrice, incrementPrice, magnitude, msg.sender);
        return divvyUp;
    }

    function die() onlyOwner public {
        selfdestruct(msg.sender);
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract DivvyUpInterface{
    function purchaseTokens()
        public
        payable
        returns(uint256);

    function purchaseTokensERC20(uint256 amount)
        public
        returns(uint256);
}

contract DivvyUp is ERC20Interface, Owned, DivvyUpInterface {
    using SafeMath for uint256;
     
     
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyDividendHolders() {
        require(dividendDivisor > 0 && myDividends() > 0);
        _;
    }

    modifier erc20Destination(){
        require(counter != 0x0);
        _;
    }
    
     
    event Purchase(
        address indexed customerAddress,
        uint256 incomingCounter,
        uint256 tokensMinted
    );
    
    event Sell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 counterEarned
    );
    
    event Reinvestment(
        address indexed customerAddress,
        uint256 counterReinvested,
        uint256 tokensMinted
    );
    
    event Withdraw(
        address indexed customerAddress,
        uint256 counterWithdrawn
    ); 
    
     
    bytes32 public name;
    bytes32 public symbol;
    uint8  public dividendDivisor;
    uint8 public decimals; 
    uint256 public tokenPriceInitial; 
    uint256 public tokenPriceIncremental; 
    uint256 public magnitude; 
    address counter;

    
     
    mapping(address => uint256) internal tokenBalanceLedger;
     
    mapping(address => int256) internal payoutsTo;
     
    mapping(address => mapping(address => uint)) allowed;
     
    uint256 internal tokenSupply = 0;
     
    uint256 internal profitPerShare;
    
     
     
    function DivvyUp(bytes32 aName, bytes32 aSymbol, uint8 aDividendDivisor, uint8 aDecimals, uint256 aTokenPriceInitial, uint256 aTokenPriceIncremental, uint256 aMagnitude, address aCounter) 
    public {
        require(aDividendDivisor < 100);
        name = aName;
        symbol = aSymbol;
        dividendDivisor = aDividendDivisor;
        decimals = aDecimals;
        tokenPriceInitial = aTokenPriceInitial;
        tokenPriceIncremental = aTokenPriceIncremental;
        magnitude = aMagnitude;
        counter = aCounter;    
    }
    
     
    function changeName(bytes32 newName) onlyOwner() public {
        name = newName;
        
    }
    
     
    function changeSymbol(bytes32 newSymbol) onlyOwner() public {
        symbol = newSymbol;
    }
    
     
    function purchaseTokens()
        public
        payable
        returns(uint256)
    {
        if(msg.value > 0){
            require(counter == 0x0);
        }
        return purchaseTokens(msg.value);
    }
    

     
    function purchaseTokensERC20(uint256 amount)
        public
        erc20Destination
        returns(uint256)
    {
        require(ERC20Interface(counter).transferFrom(msg.sender, this, amount));
        return purchaseTokens(amount);
    }


         
    function()
        payable
        public
    {
        if(msg.value > 0){
            require(counter == 0x0);
        }
        purchaseTokens(msg.value);
    }
    
     
     
    function reinvestDividends()
        onlyDividendHolders()
        public
        returns (uint256)
    {
         
        uint256 dividends = myDividends(); 
       
         
        address customerAddress = msg.sender;
        payoutsTo[customerAddress] += (int256) (dividends * magnitude);
        
         
        uint256 tokens = purchaseTokens(dividends);
        
         
        emit Reinvestment(customerAddress, dividends, tokens);
        
        return tokens;
    }
    
     
    function exit()
        public
    {
         
        address customerAddress = msg.sender;
        uint256 tokens = tokenBalanceLedger[customerAddress];
        if(tokens > 0) {
            sell(tokens);
        }
         
        withdraw();
    }

     
    function withdraw()
        onlyDividendHolders()
        public
    {
         
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(); 

         
        payoutsTo[customerAddress] += (int256) (dividends * magnitude);
                
         
        emit Withdraw(customerAddress, dividends);
    }
    
     
    function sell(uint256 amountOfTokens)
        onlyTokenHolders()
        public
    {
        require(amountOfTokens > 0);
         
        address customerAddress = msg.sender;
         
        require(amountOfTokens <= tokenBalanceLedger[customerAddress]);
        uint256 tokens = amountOfTokens;
        uint256 counterAmount = tokensToCounter(tokens);
        uint256 dividends = dividendDivisor > 0 ? SafeMath.div(counterAmount, dividendDivisor) : 0;
        uint256 taxedCounter = SafeMath.sub(counterAmount, dividends);
        
         
        tokenSupply = SafeMath.sub(tokenSupply, tokens);
        tokenBalanceLedger[customerAddress] = SafeMath.sub(tokenBalanceLedger[customerAddress], tokens);
        
         
        int256 updatedPayouts = (int256) (profitPerShare * tokens + (taxedCounter * magnitude));
        payoutsTo[customerAddress] -= updatedPayouts;       
        
         
        if (tokenSupply > 0 && dividendDivisor > 0) {
             
            profitPerShare = SafeMath.add(profitPerShare, (dividends * magnitude) / tokenSupply);
        }
        
         
        emit Sell(customerAddress, tokens, taxedCounter);
    }
    
     
    function transfer(address toAddress, uint256 amountOfTokens)
        onlyTokenHolders
        public
        returns(bool)
    {

        
        if(toAddress == address(this)){
             
            if(amountOfTokens > 0){
                sell(amountOfTokens);
            }
             
            withdraw();
             
            emit Transfer(0x0, msg.sender, amountOfTokens);

            return true;
        }
       
         
        if(myDividends() > 0) {
            withdraw();
        }
        
        return _transfer(toAddress, amountOfTokens);
    }

    function transferWithDividends(address toAddress, uint256 amountOfTokens) public onlyTokenHolders returns (bool) {
        return _transfer(toAddress, amountOfTokens);
    }

    function _transfer(address toAddress, uint256 amountOfTokens)
        internal
        onlyTokenHolders
        returns(bool)
    {
         
        address customerAddress = msg.sender;
        
         
        require(amountOfTokens <= tokenBalanceLedger[customerAddress]);
       
         
        tokenBalanceLedger[customerAddress] = SafeMath.sub(tokenBalanceLedger[customerAddress], amountOfTokens);
        tokenBalanceLedger[toAddress] = SafeMath.add(tokenBalanceLedger[toAddress], amountOfTokens);
        
         
        emit Transfer(customerAddress, toAddress, amountOfTokens);


        return true;
       
    }

     

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        tokenBalanceLedger[from] = tokenBalanceLedger[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        tokenBalanceLedger[to] = tokenBalanceLedger[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
    function totalDestinationBalance()
        public
        view
        returns(uint256)
    {
        if(counter == 0x0){
            return address(this).balance;
        } else {
            return ERC20Interface(counter).balanceOf(this);
        }
    }
    
     
    function name() 
        public 
        view 
        returns(bytes32)
    {
        return name;
    }
     

     
    function symbol() 
        public
        view
        returns(bytes32)
    {
        return symbol;
    }
     
     
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply;
    }
    
     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address customerAddress = msg.sender;
        return balanceOf(customerAddress);
    }
    
     

    function myDividends() 
        public 
        view 
        returns(uint256)
    {
        address customerAddress = msg.sender;

        return (uint256) ((int256)(profitPerShare * tokenBalanceLedger[customerAddress]) - payoutsTo[customerAddress]) / magnitude;
    }
    
     
    function balanceOf(address customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger[customerAddress];
    }
    
    
     
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
         
        if(tokenSupply == 0){
            return tokenPriceInitial - tokenPriceIncremental;
        } else {
            uint256 counterAmount = tokensToCounter(1e18);
            uint256 dividends = SafeMath.div(counterAmount, dividendDivisor);
            uint256 taxedCounter = SafeMath.sub(counterAmount, dividends);
            return taxedCounter;
        }
    }
    
     
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
         
        if(tokenSupply == 0){
            return tokenPriceInitial + tokenPriceIncremental;
        } else {
            uint256 counterAmount = tokensToCounter(1e18);
            uint256 dividends = SafeMath.div(counterAmount, dividendDivisor);
            uint256 taxedCounter = SafeMath.add(counterAmount, dividends);
            return taxedCounter;
        }
    }
    
     
    function calculateTokensReceived(uint256 counterToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 dividends = SafeMath.div(counterToSpend, dividendDivisor);
        uint256 taxedCounter = SafeMath.sub(counterToSpend, dividends);
        uint256 amountOfTokens = counterToTokens(taxedCounter);
        
        return amountOfTokens;
    }
    
     
    function calculateCounterReceived(uint256 tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(tokensToSell <= tokenSupply);
        uint256 counterAmount = tokensToCounter(tokensToSell);
        uint256 dividends = SafeMath.div(counterAmount, dividendDivisor);
        uint256 taxedCounter = SafeMath.sub(counterAmount, dividends);
        return taxedCounter;
    }
    
     
    function purchaseTokens(uint256 incomingCounter)
        internal
        returns(uint256)
    {
        if(incomingCounter == 0){
            return reinvestDividends();
        }


        
         
        address customerAddress = msg.sender;
 
 
        uint256 dividends = dividendDivisor > 0 ? SafeMath.div(incomingCounter, dividendDivisor) : 0;
        uint256 taxedCounter = SafeMath.sub(incomingCounter, dividends);
        uint256 amountOfTokens = counterToTokens(taxedCounter);
        uint256 fee = dividends * magnitude;
 
         
        assert(amountOfTokens > 0 && (SafeMath.add(amountOfTokens,tokenSupply) > tokenSupply));
               
         
        if(tokenSupply > 0){
            
             
            tokenSupply = SafeMath.add(tokenSupply, amountOfTokens);
 
             
            profitPerShare += (dividends * magnitude / (tokenSupply));
            
             
            fee = dividendDivisor > 0 ? fee - (fee-(amountOfTokens * (dividends * magnitude / (tokenSupply)))) : 0x0;
        
        } else {
             
            tokenSupply = amountOfTokens;
        }
        
         
        tokenBalanceLedger[customerAddress] = SafeMath.add(tokenBalanceLedger[customerAddress], amountOfTokens);
        
         
        int256 updatedPayouts = (int256) ((profitPerShare * amountOfTokens) - fee);
        payoutsTo[customerAddress] += updatedPayouts;
        
         
        emit Purchase(customerAddress, incomingCounter, amountOfTokens);
        emit Transfer(0x0, customerAddress, amountOfTokens);
        return amountOfTokens;
    }

     
    function counterToTokens(uint256 counterAmount)
        internal
        view
        returns(uint256)
    {
        uint256 tokenPrice = tokenPriceInitial * 1e18;
        uint256 tokensReceived = ((SafeMath.sub((sqrt((tokenPrice**2)+(2*(tokenPriceIncremental * 1e18)*(counterAmount * 1e18))+(((tokenPriceIncremental)**2)*(tokenSupply**2))+(2*(tokenPriceIncremental)*tokenPrice*tokenSupply))), tokenPrice))/(tokenPriceIncremental))-(tokenSupply);  
        return tokensReceived;
    }
    
     
    function tokensToCounter(uint256 tokens)
        internal
        view
        returns(uint256)
    {

        uint256 theTokens = (tokens + 1e18);
        uint256 theTokenSupply = (tokenSupply + 1e18);
         
        uint256 etherReceived = (SafeMath.sub((((tokenPriceInitial + (tokenPriceIncremental * (theTokenSupply/1e18)))-tokenPriceIncremental)*(theTokens - 1e18)),(tokenPriceIncremental*((theTokens**2-theTokens)/1e18))/2)/1e18);
        return etherReceived;
    }
    
     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != counter);
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}