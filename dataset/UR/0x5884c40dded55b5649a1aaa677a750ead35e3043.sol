 

 

pragma solidity ^0.4.23;

contract OnasanderToken
{
    using SafeMath for uint;
    
    address private wallet;                                 
    address public owner;                                   
    string constant public name = "Onasander";
    string constant public symbol = "ONA";
    uint8 constant public decimals = 18;
    uint public totalSupply = 88000000e18;                       
    uint public totalTokensSold = 0e18;                     
    uint public totalTokensSoldInThisSale = 0e18;           
    uint public maxTokensForSale = 79200000e18;             
    uint public companyReserves = 8800000e18;               
    uint public minimumGoal = 0e18;                         
    uint public tokensForSale = 0e18;                       
    bool public saleEnabled = false;                        
    bool public ICOEnded = false;                           
    bool public burned = false;                             
    uint public tokensPerETH = 800;                         
    bool public wasGoalReached = false;                     
    address private lastBuyer;
    uint private singleToken = 1e18;

    constructor(address icoWallet) public 
    {   
        require(icoWallet != address(0), "ICO Wallet address is required.");

        owner = msg.sender;
        wallet = icoWallet;
        balances[owner] = totalSupply;   
        emit TokensMinted(owner, totalSupply);        
    }

    event ICOHasEnded();
    event SaleEnded();
    event OneTokenBugFixed();
    event ICOConfigured(uint minimumGoal);
    event TokenPerETHReset(uint amount);
    event ICOCapReached(uint amount);
    event SaleCapReached(uint amount);
    event GoalReached(uint amount);
    event Burned(uint amount);    
    event BuyTokens(address buyer, uint tokens);
    event SaleStarted(uint tokensForSale);    
    event TokensMinted(address targetAddress, uint tokens);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    mapping(address => uint) balances;
    
    mapping(address => mapping (address => uint)) allowances;

    function balanceOf(address accountAddress) public constant returns (uint balance)
    {
        return balances[accountAddress];
    }

    function allowance(address sender, address spender) public constant returns (uint remainingAllowedAmount)
    {
        return allowances[sender][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success)
    {     
        require (ICOEnded, "ICO has not ended.  Can not transfer.");
        require (balances[to] + tokens > balances[to], "Overflow is not allowed.");

         
         
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    function transferFrom(address from, address to, uint tokens) public returns(bool success) 
    {
        require (ICOEnded, "ICO has not ended.  Can not transfer.");
        require (balances[to] + tokens > balances[to], "Overflow is not allowed.");

         
        balances[from] = balances[from].sub(tokens);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens);  
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(from, to, tokens);        
        return true;
    }

    function approve(address spender, uint tokens) public returns(bool success) 
    {          
        require (ICOEnded, "ICO has not ended.  Can not transfer.");      
        allowances[msg.sender][spender] = tokens;                
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

         
    function wirePurchase(address to, uint numberOfTokenPurchased) onlyOwner public
    {     
        require (saleEnabled, "Sale must be enabled.");
        require (!ICOEnded, "ICO already ended.");
        require (numberOfTokenPurchased > 0, "Tokens must be greater than 0.");
        require (tokensForSale > totalTokensSoldInThisSale, "There is no more tokens for sale in this sale.");
                        
         
        uint buyAmount = numberOfTokenPurchased;
        uint tokens = 0e18;

         
         
        if (totalTokensSoldInThisSale.add(buyAmount) >= tokensForSale)
        {
            tokens = tokensForSale.sub(totalTokensSoldInThisSale);   
             
        }
        else
        {
            tokens = buyAmount;
        }

         
        require (balances[to].add(tokens) > balances[to], "Overflow is not allowed.");
        balances[to] = balances[to].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        lastBuyer = to;

         
        totalTokensSold = totalTokensSold.add(tokens);
        totalTokensSoldInThisSale = totalTokensSoldInThisSale.add(tokens);
        
        emit BuyTokens(to, tokens);
        emit Transfer(owner, to, tokens);

        isGoalReached();
        isMaxCapReached();
    }

    function buyTokens() payable public
    {        
        require (saleEnabled, "Sale must be enabled.");
        require (!ICOEnded, "ICO already ended.");
        require (tokensForSale > totalTokensSoldInThisSale, "There is no more tokens for sale in this sale.");
        require (msg.value > 0, "Must send ETH");

         
        uint buyAmount = SafeMath.mul(msg.value, tokensPerETH);
        uint tokens = 0e18;

         
         
        if (totalTokensSoldInThisSale.add(buyAmount) >= tokensForSale)
        {
            tokens = tokensForSale.sub(totalTokensSoldInThisSale);   

             
        }
        else
        {
            tokens = buyAmount;
        }

         
        require (balances[msg.sender].add(tokens) > balances[msg.sender], "Overflow is not allowed.");
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        lastBuyer = msg.sender;

         
        wallet.transfer(msg.value);

         
        totalTokensSold = totalTokensSold.add(tokens);
        totalTokensSoldInThisSale = totalTokensSoldInThisSale.add(tokens);
        
        emit BuyTokens(msg.sender, tokens);
        emit Transfer(owner, msg.sender, tokens);

        isGoalReached();
        isMaxCapReached();
    }

     
     
    function() public payable 
    {
         
        buyTokens();
    }

     
     
    function burnRemainingTokens() public onlyOwner
    {
        require (!burned, "Remaining tokens have been burned already.");
        require (ICOEnded, "ICO has not ended yet.");

        uint difference = balances[owner].sub(companyReserves); 

        if (wasGoalReached)
        {
            totalSupply = totalSupply.sub(difference);
            balances[owner] = companyReserves;
        }
        else
        {
             
            totalSupply = totalTokensSold;
            balances[owner] = 0e18;
        }

        burned = true;

        emit Transfer(owner, address(0), difference);     
        emit Burned(difference);        
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public
    {
        address preOwner = owner;        
        owner = newOwner;

        uint previousBalance = balances[preOwner];

         
        balances[newOwner] = balances[newOwner].add(previousBalance);
        balances[preOwner] = 0;

         
        emit OwnershipTransferred(preOwner, newOwner, previousBalance);
    }

     
    function setTokensPerETH(uint newRate) onlyOwner public
    {
        require (!ICOEnded, "ICO already ended.");
        require (newRate > 0, "Rate must be higher than 0.");
        tokensPerETH = newRate;
        emit TokenPerETHReset(newRate);
    }

     
     
    function setMinimumGoal(uint goal) onlyOwner public
    {   
        require(goal > 0e18,"Minimum goal must be greater than 0.");
        minimumGoal = goal;

         
        isGoalReached();

        emit ICOConfigured(goal);
    }

    function createSale(uint numberOfTokens) onlyOwner public
    {
        require (!saleEnabled, "Sale is already going on.");
        require (!ICOEnded, "ICO already ended.");
        require (totalTokensSold < maxTokensForSale, "We already sold all our tokens.");

        totalTokensSoldInThisSale = 0e18;
        uint tryingToSell = totalTokensSold.add(numberOfTokens);

         
        if (tryingToSell > maxTokensForSale)
        {
            tokensForSale = maxTokensForSale.sub(totalTokensSold); 
        }
        else
        {
            tokensForSale = numberOfTokens;
        }

        tryingToSell = 0e18;
        saleEnabled = true;
        emit SaleStarted(tokensForSale);
    }

    function endSale() public
    {
        if (saleEnabled)
        {
            saleEnabled = false;
            tokensForSale = 0e18;
            emit SaleEnded();
        }
    }

    function endICO() onlyOwner public
    {
        if (!ICOEnded)
        {
             
            fixTokenCalcBug();

            endSale();

            ICOEnded = true;            
            lastBuyer = address(0);
            
            emit ICOHasEnded();
        }
    }

    function isGoalReached() internal
    {
         
        if (!wasGoalReached)
        {
            if (totalTokensSold >= minimumGoal)
            {
                wasGoalReached = true;
                emit GoalReached(minimumGoal);
            }
        }
    }

    function isMaxCapReached() internal
    {
        if (totalTokensSoldInThisSale >= tokensForSale)
        {            
            emit SaleCapReached(totalTokensSoldInThisSale);
            endSale();
        }

        if (totalTokensSold >= maxTokensForSale)
        {            
            emit ICOCapReached(maxTokensForSale);
            endICO();
        }
    }

     
    function fixTokenCalcBug() internal
    {        
        require(!burned, "Fix lost token can only run before the burning of the tokens.");        
        
        if (maxTokensForSale.sub(totalTokensSold) == singleToken)
        {
            totalTokensSold = totalTokensSold.add(singleToken);
            totalTokensSoldInThisSale = totalTokensSoldInThisSale.add(singleToken);
            
            balances[lastBuyer] = balances[lastBuyer].add(singleToken);
            balances[owner] = balances[owner].sub(singleToken);

            emit Transfer(owner, lastBuyer, singleToken);
            emit OneTokenBugFixed();
        }
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}