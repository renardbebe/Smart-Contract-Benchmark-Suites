 

pragma solidity ^0.4.21;

 
 

 
 
 
 
 
 

contract RobinHood{
     
    address public owner;
    
     
    uint8 devFee = 5;
     
    uint256 public amountToCreate = 20000000000000000;
    
     
     
    bool public open = false;
    
    event TowerCreated(uint256 id);
    event TowerBought(uint256 id);
    event TowerWon(uint256 id);

     
    struct Tower{
         
        uint32 timer; 
         
         
        uint256 timestamp;
         
         
         
         
         
        uint16 payout; 
         
         
        uint16 priceIncrease;  
         
        uint256 price;
         
        uint256 amount; 
         
         
        uint256 minPrice; 
         
         
         
        uint16 creatorFee; 
         
         
         
         
        uint256 amountToHalfTime; 
         
         
         
         
         
         
        uint16 minPriceAfterWin;  
         
        address creator;
         
        address owner;
         
        string quote;
    }
    
   
     
    mapping(uint256 => Tower) public Towers;
    
     
    uint256 public next_tower_index=0;

     
     
     
    modifier onlyOpen(){
        if (open){
            _;
        }
        else{
            revert();
        }
    }
    
     
     
     
    modifier onlyOpenOrOwner(){
        if (open || msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }
    
     
     
    modifier onlyOwner(){
        if (msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }
    
    
     
     
    function RobinHood() public{
         
        owner = msg.sender;
    
        
        
         
         
         
         
         
         
         
         
         
         
       
       
        AddTower(600, 9000, 3000, 5000000000000000000, 2000000000000000, 1000, 0);
    
    
         
         
         
         
         
         
         
         
         
        
        AddTower(600, 5000,150 , 2500000000000000000, 4000000000000000, 0, 0);
  
         
         
         
         
         
         
         
         
         
        AddTower(3600, 5000, 1000, (1000000000000000000), 5000000000000000, 5000, 0);

         
         
         
         
         
         
         
         
         
        AddTower(86400, 7500, 2000, (2000000000000000000), 10000000000000000, 2500, 0);
         

  
         
         
         
         
         
         
         
         
         
        AddTower(604800, 7500, 2500, (2500000000000000000), 50000000000000000, 0, 0);
    }
    
     
     
    function OpenGame() public onlyOwner{
        open = true;
    }
    
     
     
     
    function ChangeFee(uint8 _fee) public onlyOwner{
        require(_fee <= 5);
        devFee = _fee;
    }
    
     
    function ChangeAmountPrice(uint256 _newPrice) public onlyOwner{
        amountToCreate = _newPrice;
    }
    
     
     
     
     
    
     
     
     
    
     
     
     
    
     
     
    
     
     
     
     
     
    
     
     
     
    
     
     
     

     
     
     
    
    function AddTower(uint32 _timer, uint16 _payout, uint16 _priceIncrease, uint256 _amountToHalfTime, uint256 _minPrice, uint16 _minPriceAfterWin, uint16 _creatorFee) public payable onlyOpenOrOwner returns (uint256) {
        require (_timer >= 300);  
        require (_timer <= 31622400);
        require (_payout >= 0 && _payout <= 10000);
        require (_priceIncrease >= 0 && _priceIncrease <= 10000);
        require (_minPriceAfterWin >= 0 && _minPriceAfterWin <= 10000);
        
        require(_amountToHalfTime == 0 || _amountToHalfTime >= 1000000000000);
        require(_creatorFee >= 0 && _creatorFee <= 2500);
        require(_minPrice >= (1 szabo) && _minPrice <= (1 ether));
        if (msg.sender == owner){
             
            _creatorFee = 0;
            if (msg.value > 0){
                owner.transfer(msg.value);
            }
        }
        else{
            if (msg.value >= amountToCreate){
                uint256 toDiv = (mul(amountToCreate, tokenDividend))/100;
                uint256 left = sub(amountToCreate, toDiv);
                owner.transfer(left);
                addDividend(toDiv);
                processBuyAmount(amountToCreate);
            }
            else{
                revert();  
            }
            uint256 diff = sub(msg.value, amountToCreate);
             
             
            if (diff >= 0){
                msg.sender.transfer(diff);
            }
        }
   
         

        
         
        var NewTower = Tower(_timer, 0, _payout, _priceIncrease, _minPrice, 0, _minPrice, _creatorFee, _amountToHalfTime, _minPriceAfterWin, msg.sender, msg.sender, "");
        
         
        Towers[next_tower_index] = NewTower;
        
         
        emit TowerCreated(next_tower_index);
        
         
        next_tower_index = add(next_tower_index, 1);
        return (next_tower_index - 1);
    }
    
     
     
     
    function getTimer(uint256 _id) public onlyOpen returns (uint256)  {
        require(_id < next_tower_index);
        var UsedTower = Towers[_id];
         
         
        if (UsedTower.amountToHalfTime == 0){
            return UsedTower.timer;
        }
        
        uint256 var2 = UsedTower.amountToHalfTime;
        uint256 var3 = add(UsedTower.amount / 1000000000000, UsedTower.amountToHalfTime / 1000000000000);
        
        
       if (var2 == 0 && var3 == 0){
            
           return UsedTower.timer;
       }
       

       
       uint256 target = (mul(UsedTower.timer, var2/var3 )/1000000000000);
       
        
        
       if (target < 300){
           return 300;
       }
       
       return target;
    }
    
     
    function Payout_intern(uint256 _id) internal {
         
        
        var UsedTower = Towers[_id];
         
        uint256 Paid = mul(UsedTower.amount, UsedTower.payout) / 10000;
        
         
        UsedTower.amount = sub(UsedTower.amount, Paid);
        
         
        UsedTower.owner.transfer(Paid);
        
         
        uint256 newPrice = (UsedTower.price * UsedTower.minPriceAfterWin)/10000;
        
         
        if (newPrice < UsedTower.minPrice){
            newPrice = UsedTower.minPrice;
        }
        
         
        UsedTower.price = newPrice;
        
          
        if (UsedTower.amount > UsedTower.minPrice){
             
            UsedTower.timestamp = block.timestamp;
        }
        else{
             
            UsedTower.timestamp = 0;
        }
    
         
        emit TowerWon(_id);
    }
    
    
     
     
     
     
     
    function TakePrize(uint256 _id) public onlyOpen{
        require(_id < next_tower_index);
        var UsedTower = Towers[_id];
        require(UsedTower.timestamp > 0);  
        var Timing = getTimer(_id);
        if (block.timestamp > (add(UsedTower.timestamp,  Timing))){
            Payout_intern(_id);
        }
        else{
            revert();
        }
    }
    
     
     
    
     
     
    function ShootRobinHood(uint256 _id, string _quote) public payable onlyOpen{
        require(_id < next_tower_index);
        var UsedTower = Towers[_id];
        var Timing = getTimer(_id);
    
         
        if (UsedTower.timestamp != 0 && block.timestamp > (add(UsedTower.timestamp,  Timing))){
            Payout_intern(_id);
             
            if (msg.value > 0){
                msg.sender.transfer(msg.value);
            }
            return;
        }
        
         
        require(msg.value >= UsedTower.price);
         
        
        uint256 devFee_used = (mul( UsedTower.price, 5))/100;
        uint256 creatorFee = (mul(UsedTower.creatorFee, UsedTower.price)) / 10000;
        uint256 divFee = (mul(UsedTower.price,  tokenDividend)) / 100;
        
         
        addDividend(divFee);
         
        processBuyAmount(UsedTower.price);
        
         
        
        uint256 ToPay = sub(sub(UsedTower.price, devFee_used), creatorFee);
        
         
        uint256 diff = sub(msg.value, UsedTower.price);
        if (creatorFee != 0){
            UsedTower.creator.transfer(creatorFee);
        }
         
        if (diff > 0){
            msg.sender.transfer(diff); 
        }
        
         
        owner.transfer(devFee_used);
        
         
         
        UsedTower.timestamp = block.timestamp;
         
        UsedTower.owner = msg.sender;
         
        UsedTower.quote = _quote;
         
        UsedTower.amount = add(UsedTower.amount, sub(ToPay, divFee));
         
        UsedTower.price = (UsedTower.price * (10000 + UsedTower.priceIncrease)) / 10000;
        
         
        emit TowerBought(_id);
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
    
    
     


     
    uint256 public numTokens;
     
    uint256 public ethDividendAmount;
     
    uint256 constant public tokenStartPrice = 1000000000000;
     
    uint256 constant public tokenIncrease = 100000000000;
    
     
    uint256 public tokenPrice = tokenStartPrice;
    
     
    uint8 constant public tokenDividend = 5;
    
     
    uint256 constant public tokenScaleFactor = 1000;
    
     
    mapping(address => uint256) public tokensPerAddress;
     
    
    
     
    function addDividend(uint256 amt) internal {
        ethDividendAmount = ethDividendAmount + amt;
    }
    
     
     
     
    function getNumTokens(uint256 amt) internal  returns (uint256){
        uint256 a = tokenIncrease;
        uint256 b = 2*tokenPrice - tokenIncrease;
       
        uint256 D = b*b + 8*a*amt;
        uint256 sqrtD = tokenScaleFactor*sqrt(D);
         
        return (sqrtD - (b * tokenScaleFactor)) / (2*a);
    }
    
     
    function processBuyAmount(uint256 amt) internal {
        uint256 tokens = getNumTokens(amt );
        tokensPerAddress[msg.sender] = add(tokensPerAddress[msg.sender], tokens);

        
        numTokens = add(numTokens, tokens);
         
         
        
         
        
         
        
       tokenPrice = add(tokenPrice , ((mul(tokenIncrease, tokens))/tokenScaleFactor));

    }
    
     
    function sellTokens() public {
        uint256 tokens = tokensPerAddress[msg.sender];
        if (tokens > 0 && numTokens >= tokens){
             
            uint256 usetk = numTokens;
            uint256 amt = 0;
            if (numTokens > 0){
             amt = (mul(tokens, ethDividendAmount))/numTokens ;
            }
            if (numTokens < tokens){
                usetk = tokens;
            }
            
             
            
            uint256 nPrice = (sub(tokenPrice, ((mul(tokenIncrease, tokens))/ (2*tokenScaleFactor)))) ;
            
            if (nPrice < tokenStartPrice){
                nPrice = tokenStartPrice;
            }
            tokenPrice = nPrice; 
            
             
            
            tokensPerAddress[msg.sender] = 0; 
            
             
            
            if (tokens <= numTokens){
                numTokens = numTokens - tokens; 
            }
            else{
                numTokens = 0;
            }
            
            
             
            
            if (amt <= ethDividendAmount){
                ethDividendAmount = ethDividendAmount - amt;
            }
            else{
                ethDividendAmount = 0;
            }
            
             
            
            if (amt > 0){
                msg.sender.transfer(amt);
            }
        }
    }
    
     
    function sqrt(uint x) internal returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    
}