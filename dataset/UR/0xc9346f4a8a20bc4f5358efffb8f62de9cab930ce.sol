 

pragma solidity ^0.4.21;

 
 
 

contract GasWar{
    
    
     
   
 
    
     
    uint256 public UTCStart = (2 hours);
    uint256 public UTCStop = (4 hours);
    
    uint256 public RoundTime = (5 minutes);
    uint256 public Price = (0.005 ether);
    
    uint256 public RoundEndTime;
    
    
    uint256 public GasPrice = 0;
    address public Winner;
     
    
    uint256 public TakePot = 8000;  
    

    
    event GameStart(uint256 EndTime);
    event GameWon(address Winner, uint256 Take);
    event NewGameLeader(address Leader, uint256 GasPrice, uint256 pot);
    event NewTX(uint256 pot);
    
    address owner;

    function GasWar() public {
        owner = msg.sender;
    }
    
    function Open() public view returns (bool){
        uint256 sliced = now % (1 days);
        return (sliced >= UTCStart && sliced <= UTCStop);
    }
    
    function NextOpen() public view returns (uint256, uint256){
        
        uint256 sliced = now % (1 days);
        if (sliced > UTCStop){
            uint256 ret2 = (UTCStop) - sliced + UTCStop;
            return (ret2, now + ret2);
        }
        else{
            uint256 ret1 = (UTCStart - sliced);
            return (ret1, now + ret1);
        }
    }
    
    


    
    function Withdraw() public {
       
         
         
        CheckGameStart(false);
    }
    
     
    function _withdraw(bool reduce_price) internal {
         
         require((now > RoundEndTime));
        require (Winner != 0x0);
        
        uint256 subber = 0;
        if (reduce_price){
            subber = Price;
        }
        uint256 Take = (mul(sub(address(this).balance,subber), TakePot)) / 10000;
        Winner.transfer(Take);

        
        emit GameWon(Winner, Take);
        
        Winner = 0x0;
        GasPrice = 0;
    }
    
    function CheckGameStart(bool remove_price) internal returns (bool){
        if (Winner != 0x0){
             
             
            _withdraw(remove_price && Open());  

        }
        if (Winner == 0x0 && Open()){
            Winner = msg.sender;  
            RoundEndTime = now + RoundTime;
            emit GameStart(RoundEndTime);
            return true;
        }
        return false;
    }
    
     
     
     
     
     
     
        
    function BuyIn() public payable {
         
         
         
         
         
        require(msg.value == Price);
        
        
        if (now > RoundEndTime){
            bool started = CheckGameStart(true);
            require(started);
            GasPrice = tx.gasprice;
            emit NewGameLeader(msg.sender, GasPrice, address(this).balance + (Price * 95)/100);
        }
        else{
            if (tx.gasprice > GasPrice){
                GasPrice = tx.gasprice;
                Winner = msg.sender;
                emit NewGameLeader(msg.sender, GasPrice, address(this).balance + (Price * 95)/100);
            }
        }
        
         
        
        owner.transfer((msg.value * 500)/10000);  
        
        emit NewTX(address(this).balance + (Price * 95)/100);
    }
    
     
 
      
      
      
    function SetTakePot(uint256 v) public {
        require(msg.sender==owner);
        require (v <= 10000);
        require(v >= 1000);  
        TakePot = v;
    }
    
    function SetTimes(uint256 NS, uint256 NE) public {
        require(msg.sender==owner);
        require(NS < (1 days));
        require(NE < (1 days));
        UTCStart = NS;
        UTCStop = NE;
    }
    
    function SetPrice(uint256 p) public {
        require(msg.sender == owner);
        require(!Open() && (Winner == 0x0));  
        Price = p;
    }    
    
    function SetRoundTime(uint256 p) public{
        require(msg.sender == owner);
        require(!Open() && (Winner == 0x0));
        RoundTime = p;
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