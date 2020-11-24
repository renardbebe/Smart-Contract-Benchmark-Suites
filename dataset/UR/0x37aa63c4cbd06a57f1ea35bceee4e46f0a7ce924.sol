 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
     
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
     
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
     
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract ERC20Basic {
  uint256 public totalSupply=100000000; 
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
      
      if (balances[msg.sender] < _value) {
             
            throw;
        }
      
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
             
            throw;
        }

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract owned {
     function owned() { owner = msg.sender; }
     address owner;

      
      
      
      
      
      
      
     modifier onlyOwner {
         if(msg.sender != owner)
         {
         throw;
         }
         _;
     }
 }


contract UniContract is StandardToken, owned {


   string public constant name = "SaveUNICOINs";
   string public constant symbol = "UCN";
   uint256 public constant decimals = 0;
   
    
   address public multisig;
   address public founder; 
   
   
    
   uint public start;  
   uint public end;
   uint public launch;
   
    
   uint256 public PRICE = 217135;  
   
    
   uint256 public OVERALLSOLD = 3148890;  
   
    
   uint256 public MAXTOKENSOLD = 85000000;  
   
   
   
   
  
   function UniContract() onlyOwner { 
       founder = 0x204244062B04089b6Ef55981Ad82119cEBf54F88; 
       multisig= 0x9FA2d2231FE8ac207831B376aa4aE35671619960;
       
       start = 1507543200;
       end = 1509098400; 
 	   launch = 1509534000;
 	    
       balances[founder] = balances[founder].add(18148890);  
 
   }
   
   
   
    
   
   uint256 public constant PRICE_PRESALE = 300000;  
   uint256 public constant FACTOR_PRESALE = 38;
   uint256 public constant RANGESTART_PRESALE = 0; 
   uint256 public constant RANGEEND_PRESALE = 10000000; 
   
   
    
   uint256 public constant PRICE_1 = 30000;  
   uint256 public constant FACTOR_1 = 460;
   uint256 public constant RANGESTART_1 = 10000001; 
   uint256 public constant RANGEEND_1 = 10100000;
   
    
   uint256 public constant PRICE_2 = 29783;  
   uint256 public constant FACTOR_2 = 495;
   uint256 public constant RANGESTART_2 = 10100001; 
   uint256 public constant RANGEEND_2 = 11000000;
   
    
   uint256 public constant PRICE_3 = 27964;  
   uint256 public constant FACTOR_3 = 580;
   uint256 public constant RANGESTART_3 = 11000001; 
   uint256 public constant RANGEEND_3 = 15000000;
   
    
   uint256 public constant PRICE_4 = 21068;  
   uint256 public constant FACTOR_4 = 800;
   uint256 public constant RANGESTART_4 = 15000001; 
   uint256 public constant RANGEEND_4 = 20000000;
   
    
   uint256 public constant PRICE_5 = 14818;  
   uint256 public constant FACTOR_5 = 1332;
   uint256 public constant RANGESTART_5 = 20000001; 
   uint256 public constant RANGEEND_5 = 30000000;
   
    
   uint256 public constant PRICE_6 = 7310;  
   uint256 public constant FACTOR_6 = 2700;
   uint256 public constant RANGESTART_6 = 30000001; 
   uint256 public constant RANGEEND_6 = 40000000;
   
    
   uint256 public constant PRICE_7 = 3607;  
   uint256 public constant FACTOR_7 = 5450;
   uint256 public constant RANGESTART_7 = 40000001; 
   uint256 public constant RANGEEND_7 = 50000000;
   
    
   uint256 public constant PRICE_8 = 1772;  
   uint256 public constant FACTOR_8 = 11000;
   uint256 public constant RANGESTART_8 = 50000001; 
   uint256 public constant RANGEEND_8 = 60000000;
   
    
   uint256 public constant PRICE_9 = 863;  
   uint256 public constant FACTOR_9 = 23200;
   uint256 public constant RANGESTART_9 = 60000001; 
   uint256 public constant RANGEEND_9 = 70000000;
   
    
   uint256 public constant PRICE_10 = 432;  
   uint256 public constant FACTOR_10 = 46000;
   uint256 public constant RANGESTART_10 = 70000001; 
   uint256 public constant RANGEEND_10 = 80000000;
   
    
   uint256 public constant PRICE_11 = 214;  
   uint256 public constant FACTOR_11 = 78000;
   uint256 public constant RANGESTART_11 = 80000001; 
   uint256 public constant RANGEEND_11 = 85000000;
   

   uint256 public UniCoinSize=0;

 
   function () payable {
     submitTokens(msg.sender);
   }

    
   function submitTokens(address recipient) payable {
     	if (msg.value == 0) {
       		throw;
     	}
		
   	 	 
   	 	if((now > start && now < end) || now > launch)
   	 		{				
        		uint256 tokens = msg.value.mul(PRICE).div( 1 ether);
        		if(tokens.add(OVERALLSOLD) > MAXTOKENSOLD)
   	 				{
   					throw;
   					}
		
   				 
   				if(((tokens.add(OVERALLSOLD)) > RANGEEND_PRESALE) && (now > start && now < end))
   					{
   					throw;
   					}
		
 				   
        		OVERALLSOLD = OVERALLSOLD.add(tokens);	
	
   		 	     
        		balances[recipient] = balances[recipient].add(tokens);
	 
   	 			 
        		if (!multisig.send(msg.value)) {
          			throw;
        			}
        		Transfer(address(this), recipient, tokens);
       		}
   	  	  else
   	  			{
   	  	  		throw;
   	 		   	}
		
		
		 
		
		if(now>start && now <end)
		{
			 
			if(OVERALLSOLD >= RANGESTART_PRESALE && OVERALLSOLD <= RANGEEND_PRESALE) 
				{
				PRICE = PRICE_PRESALE - (1 + OVERALLSOLD - RANGESTART_PRESALE).div(FACTOR_PRESALE);
				}
		}
		
		 
		if(now>launch)
		{
		 
		if(OVERALLSOLD >= RANGESTART_PRESALE && OVERALLSOLD <= RANGEEND_PRESALE) 
			{
			PRICE = PRICE_PRESALE - (1 + OVERALLSOLD - RANGESTART_PRESALE).div(FACTOR_PRESALE);
			}
		
		 
		if(OVERALLSOLD >= RANGESTART_1 && OVERALLSOLD <= RANGEEND_1)
			{
			PRICE = PRICE_1 - (1 + OVERALLSOLD - RANGESTART_1).div(FACTOR_1);
			}

		 
		if(OVERALLSOLD >= RANGESTART_2 && OVERALLSOLD <= RANGEEND_2)
			{
			PRICE = PRICE_2 - (1 + OVERALLSOLD - RANGESTART_2).div(FACTOR_2);
			}

		 
		if(OVERALLSOLD >= RANGESTART_3 && OVERALLSOLD <= RANGEEND_3)
			{
			PRICE = PRICE_3 - (1 + OVERALLSOLD - RANGESTART_3).div(FACTOR_3);
			}
			
		 
		if(OVERALLSOLD >= RANGESTART_4 && OVERALLSOLD <= RANGEEND_4)
			{
			PRICE = PRICE_4 - (1 + OVERALLSOLD - RANGESTART_4).div(FACTOR_4);
			}
			
		 
		if(OVERALLSOLD >= RANGESTART_5 && OVERALLSOLD <= RANGEEND_5)
			{
			PRICE = PRICE_5 - (1 + OVERALLSOLD - RANGESTART_5).div(FACTOR_5);
			}
		
		 
		if(OVERALLSOLD >= RANGESTART_6 && OVERALLSOLD <= RANGEEND_6)
			{
			PRICE = PRICE_6 - (1 + OVERALLSOLD - RANGESTART_6).div(FACTOR_6);
			}	
		
		 
		if(OVERALLSOLD >= RANGESTART_7 && OVERALLSOLD <= RANGEEND_7)
			{
			PRICE = PRICE_7 - (1 + OVERALLSOLD - RANGESTART_7).div(FACTOR_7);
			}
			
		 
		if(OVERALLSOLD >= RANGESTART_8 && OVERALLSOLD <= RANGEEND_8)
			{
			PRICE = PRICE_8 - (1 + OVERALLSOLD - RANGESTART_8).div(FACTOR_8);
			}
		
		 
		if(OVERALLSOLD >= RANGESTART_9 && OVERALLSOLD <= RANGEEND_9)
			{
			PRICE = PRICE_9 - (1 + OVERALLSOLD - RANGESTART_9).div(FACTOR_9);
			}
		
		 
		if(OVERALLSOLD >= RANGESTART_10 && OVERALLSOLD <= RANGEEND_10)
			{
			PRICE = PRICE_10 - (1 + OVERALLSOLD - RANGESTART_10).div(FACTOR_10);
			}	
		
		 
		if(OVERALLSOLD >= RANGESTART_11 && OVERALLSOLD <= RANGEEND_11)
			{
			PRICE = PRICE_11 - (1 + OVERALLSOLD - RANGESTART_11).div(FACTOR_11);
			}
		}
		
	
   }

	 
   function submitEther(address recipient) payable {
     if (msg.value == 0) {
       throw;
     }

     if (!recipient.send(msg.value)) {
       throw;
     }
    
   }


   

  struct MessageQueue {
           string message; 
  		   string from;
           uint expireTimestamp;  
           uint startTimestamp;
           address sender; 
       }

	 
     uint256 public constant maxSpendToken = 3600;  

     MessageQueue[] public mQueue;
 
	
 
      function addMessageToQueue(string msg_from, string name_from, uint spendToken) {
        if(balances[msg.sender]>=spendToken && spendToken>=10)
        {
           if(spendToken>maxSpendToken) 
               {
                   spendToken=maxSpendToken;
               }
           
		   UniCoinSize=UniCoinSize+spendToken;
           
           balances[msg.sender] = balances[msg.sender].sub(spendToken);
          
		   
  		  uint expireTimestamp=now;
		  if(mQueue.length>0)
			{
			 if(mQueue[mQueue.length-1].expireTimestamp>now)
			 	{
			 	expireTimestamp = mQueue[mQueue.length-1].expireTimestamp;
				}
			} 
		
		 
		 
           mQueue.push(MessageQueue({
                   message: msg_from, 
  				   from: name_from,
                   expireTimestamp: expireTimestamp.add(spendToken)+60,   
                   startTimestamp: expireTimestamp,
                   sender: msg.sender
               }));
    
        
		 
        }
		else {
		      throw;
		      }
      }
	  
	
    function feedUnicorn(uint spendToken) {
	
   	 	if(balances[msg.sender] < spendToken)
        	{ throw; }
       	 	UniCoinSize=UniCoinSize.add(spendToken);
        	balances[msg.sender] = balances[msg.sender].sub(spendToken);
			
		
	 } 
	
	
   function getQueueLength() public constant returns (uint256 result) {
	 return mQueue.length;
   }
   function getMessage(uint256 i) public constant returns (string, string, uint, uint, address){
     return (mQueue[i].message,mQueue[i].from,mQueue[i].expireTimestamp,mQueue[i].startTimestamp,mQueue[i].sender );
   }
   function getPrice() constant returns (uint256 result) {
     return PRICE;
   }
   function getSupply() constant returns (uint256 result) {
     return totalSupply;
   }
   function getSold() constant returns (uint256 result) {
     return OVERALLSOLD;
   }
   function getUniCoinSize() constant returns (uint256 result) {    
     return UniCoinSize; 
   } 
    function getAddress() constant returns (address) {
     return this;
   }
    


  
    

   
    
   function aSetStart(uint256 nstart) onlyOwner {
     start=nstart;
   }
   function aSetEnd(uint256 nend) onlyOwner {
     end=nend;
   }
   function aSetLaunch(uint256 nlaunch) onlyOwner {
     launch=nlaunch;
   }
    

    
   function aDeleteMessage(uint256 i,string f,string m) onlyOwner{
     mQueue[i].message=m;
	 mQueue[i].from=f; 
		 }
   
    
   function aPurgeMessages() onlyOwner{
   delete mQueue; 
   }

 }