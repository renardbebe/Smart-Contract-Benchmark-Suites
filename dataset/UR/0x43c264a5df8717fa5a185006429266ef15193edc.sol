 

pragma solidity ^0.4.19;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  
 
}


contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
   

 
   
  function approve(address _spender, uint256 _value) public returns (bool) {
 
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
 
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }
 
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  

 
   
  function  transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
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
  
  
   function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    if(b==0) return 1;
    assert(b>=0);
    uint256 c = a ** b;
    assert(c>=a );
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
  
function compoundInterest(uint256 depo, uint256 stage2, uint256 start, uint256 current)  internal pure returns (uint256)  {
            if(current<start || start<stage2 || current<stage2) return depo;

            uint256 ret=depo; uint256 g; uint256 d;
            stage2=stage2/1 days;
            start=start/1 days;
            current=current/1 days;
    
			uint256 dpercent=100;
			uint256 i=start;
			
			if(i-stage2>365) dpercent=200;
			if(i-stage2>730) dpercent=1000;			
			
			while(i<current)
			{

				g=i-stage2;			
				if(g>265 && g<=365) 
				{		
				    d=365-g;
					if(d>=(current-start))  d=(current-start);
					ret=fracExp(ret, dpercent, d, 8);
				    i+=d;
					dpercent=200;
				}
				if(g>630 && g<=730) 
				{				
					d=730-g;	
					if(d>=(current-start))  d=(current-start);					
					ret=fracExp(ret, dpercent, d, 8);
					i+=d;
					dpercent=1000;					
				}
				else if(g>730) dpercent=1000;				
				else if(g>365) dpercent=200;
				
				if(i+100<current) ret=fracExp(ret, dpercent, 100, 8);
				else return fracExp(ret, dpercent, current-i, 8);
				i+=100;
				
			}

			return ret;
			
			
    
    
	}


function fracExp(uint256 depo, uint256 percent, uint256 period, uint256 p)  internal pure returns (uint256) {
  uint256 s = 0;
  uint256 N = 1;
  uint256 B = 1;
  

  
  for (uint256 i = 0; i < p; ++i){
    s += depo * N / B / (percent**i);
    N  = N * (period-i);
    B  = B * (i+1);
  }
  return s;
}







}



contract MMMTokenCoin is StandardToken, Ownable {
    using SafeMath for uint256;
    
    string public constant name = "Make More Money";
    string public constant symbol = "MMM";
    uint32 public constant decimals = 2;
    
	
	 
	uint256 public stage2StartTime;					 
    uint256 globalInterestDate;              
    uint256 globalInterestAmount;            
	mapping(address => uint256) dateOfStart;      
	uint256 public currentDate;						 
	uint256 public debugNow=0;



     
    uint256 public totalSupply=99900000000;			
 uint256 public  softcap;
    uint256 public  step0Rate=100000;        
    uint256 public  currentRate=100000;   
    uint256 public constant tokensForOwner=2000000000;    
    uint256 public tokensFromEther=0;
    uint public saleStatus=0;       
    address multisig=0x8216A5958f05ad61898e3A6F97ae5118C0e4b1A6;
     
    mapping(address => uint256) boughtWithEther;                 
    mapping(address => uint256) boughtWithOther;    			 
    mapping(address => uint256) bountyAndRefsWithEther;  		 
  
    

		
		
     
    event RefundEther(address indexed to, uint256 tokens, uint256 eth); 
    event DateUpdated(uint256 cdate);    
    event DebugLog(string what, uint256 param);
    event Sale(address indexed to, uint256 amount);
    event Step0Finished();
    event RateSet(uint256 newRate);	
    event Burn(address indexed who, uint256 amount);
    

    bool bDbgEnabled=false;
	
	
	
    function MMMTokenCoin() public   {  
         
        currentDate=(getNow()/1 days)*1 days;
        stage2StartTime=getNow()+61 days;
        
        balances[owner]=tokensForOwner;
        globalInterestAmount=0;
        
        if(bDbgEnabled) softcap=20000;
        else  softcap=50000000;
    }
	
	
	function debugSetNow(uint256 n) public
	{
	    require(bDbgEnabled);
		debugNow=n;
	}
	
	
	  
     
     
	function getNow() public view returns (uint256)
	{
	    
	    if(!bDbgEnabled) return now;
	    
	    if(debugNow==0) return now;
		else return debugNow;
 
	}
   
     
   
    
    function updateDate(address _owner) private {
        if(currentDate<stage2StartTime) dateOfStart[_owner]=stage2StartTime;
        else dateOfStart[_owner]=currentDate;
    }
    

	
     
    function balanceOf(address _owner) public constant returns (uint256 balance) 
    { 
        
         return balanceWithInterest(_owner);
    }   
   
	
     
		
		
    function balanceWithInterest(address _owner)  private constant returns (uint256 ret)
    {
        if( _owner==owner || saleStatus!=2) return balances[_owner]; 
        return balances[_owner].compoundInterest(stage2StartTime, dateOfStart[_owner], currentDate);
    }
    
    
    
    
    


     
		 
  function transfer(address _to, uint256 _value)  public returns (bool) {
    if(msg.sender==owner) {
    	 
    	 
        if(saleStatus==0) {
            	transferFromOwner(_to, _value,1);
            	tokensFromEther=tokensFromEther.add(_value);
				bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add(_value);
        	}
        	else transferFromOwner(_to, _value,0);
        	
        	increaseGlobalInterestAmount(_value);
        	return true;   
    }
    
    balances[msg.sender] = balanceWithInterest(msg.sender).sub(_value);

    emit Transfer(msg.sender, _to, _value);
    if(_to==address(this)) {
		 
        uint256 left; left=processRefundEther(msg.sender, _value);
        balances[msg.sender]=balances[msg.sender].add(left);
    }
    else {
        balances[_to] = balanceWithInterest(_to).add(_value);
        updateDate(_to);
    }
    
    if(_to==owner) 
    {
    	 
        require(saleStatus!=0);
        decreaseGlobalInterestAmount(_value);
    }
    
    updateDate(msg.sender);
    return true;
  }
  
  
   
	  
  
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
           require(_to!=owner);
    uint256 _allowance = allowed[_from][msg.sender];

     allowed[_from][msg.sender] = _allowance.sub(_value);

    if(_from==owner) {
        if(saleStatus==0) {
            transferFromOwner(_to, _value,1);
            tokensFromEther=tokensFromEther.add(_value);
			bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add(_value);			
        }
        else transferFromOwner(_to, _value,0);
      
        increaseGlobalInterestAmount(_value);
        return true;
    }
     
     
    balances[_from] = balanceWithInterest(_from).sub(_value);

     emit Transfer(_from, _to, _value);

    if(_to==address(this)) {
		 
        uint256 left; left=processRefundEther(_from, _value);
        balances[_from]=balances[_from].add(left);
    }
    else {
        balances[_to] = balanceWithInterest(_to).add(_value);
        updateDate(_to);
    }
    
    if(_to==owner) 
    {
        require(saleStatus!=0);
        decreaseGlobalInterestAmount(_value);
    }

    updateDate(_from);

    return true;
  }
  
  
  
     
	  
	  
	  
  function burn(uint256 _amount) public 
  {
	  	require(_amount>0);
        balances[msg.sender]=balanceOf(msg.sender).sub(_amount);
		decreaseGlobalInterestAmount(_amount);
        emit Burn(msg.sender, _amount);
  }
   
    
   
     

 	function setRate(uint256 r) public {
		require(saleStatus!=0);
		currentRate=r;
		emit RateSet(currentRate);
	}

     
    
    function newDay() public   returns (bool b)
    {
        
       uint256 g; uint256 newDate;
       require(getNow()>=stage2StartTime);
       require(getNow()>=currentDate);
       newDate=(getNow()/1 days)*1 days;
        if(getNow()>=stage2StartTime && saleStatus==0)
        {
            if(tokensForOwner.sub(balances[owner])>=softcap) saleStatus=2;
            else saleStatus=1;
         
            emit Step0Finished();
        }
      
	    
	  
       g=globalInterestAmount.compoundInterest(stage2StartTime, globalInterestDate, newDate);
       if(g<=totalSupply && saleStatus==2) {
             currentDate=(getNow()/1 days)*1 days; 
             globalInterestAmount=g;
             globalInterestDate=currentDate;
             emit DateUpdated(currentDate);
             return true;
       }
       else if(saleStatus==1) currentDate=(getNow()/1 days)*1 days; 
       
       return false;
    }
    
    
     
     
    function sendEtherToMultisig() public  returns(uint256 e) {
        uint256 req;
        require(msg.sender==owner || msg.sender==multisig);
        require(saleStatus!=0);

        if(saleStatus==2) {
        	 
        	req=tokensFromEther.mul(1 ether).div(step0Rate).div(2);

        	if(bDbgEnabled) emit DebugLog("This balance is", this.balance);
        	if(req>=this.balance) return 0;
    	}
    	else if(saleStatus==1) {
    		require(getNow()-stage2StartTime>15768000);
    		req=0; 
    	}
        uint256 amount;
        amount=this.balance.sub(req);
        multisig.transfer(amount);
        return amount;
        
    }
    
	


	
	
	 
	
     
	
    function processRefundEther(address _to, uint256 _value) private returns (uint256 left)
    {
        require(saleStatus!=0);
        require(_value>0);
        uint256 Ether=0; uint256 bounty=0;  uint256 total=0;

        uint256 rate2=saleStatus;

        
        if(_value>=boughtWithEther[_to]) {Ether=Ether.add(boughtWithEther[_to]); _value=_value.sub(boughtWithEther[_to]); }
        else {Ether=Ether.add(_value); _value=_value.sub(Ether);}
        boughtWithEther[_to]=boughtWithEther[_to].sub(Ether);
        
        if(rate2==2) {        
            if(_value>=bountyAndRefsWithEther[_to]) {bounty=bounty.add(bountyAndRefsWithEther[_to]); _value=_value.sub(bountyAndRefsWithEther[_to]); }
            else { bounty=bounty.add(_value); _value=_value.sub(bounty); }
            bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].sub(bounty);
        }
        total=Ether.add(bounty);
      
        tokensFromEther=tokensFromEther.sub(total);
       uint256 eth=total.mul(1 ether).div(step0Rate).div(rate2);
         _to.transfer(eth);
        if(bDbgEnabled) emit DebugLog("Will refund ", eth);

        emit RefundEther(_to, total, eth);
        decreaseGlobalInterestAmount(total);
        return _value;
    }
    
    
	

	      
	
	function getRefundInfo(address _to) public returns (uint256, uint256, uint256)
	{
	    return  ( boughtWithEther[_to],  boughtWithOther[_to],  bountyAndRefsWithEther[_to]);
	    
	}
	
    
     
    
    function refundToOtherProcess(address _to, uint256 _value) public onlyOwner returns (uint256 o) {
        require(saleStatus!=0);
         
        uint256 maxValue=0;
        require(_value<=maxValue);
        
        uint256 Other=0; uint256 bounty=0; 



        
        if(_value>=boughtWithOther[_to]) {Other=Other.add(boughtWithOther[_to]); _value=_value.sub(boughtWithOther[_to]); }
        else {Other=Other.add(_value); _value=_value.sub(Other);}
        boughtWithOther[_to]=boughtWithOther[_to].sub(Other);

       
        balances[_to]=balanceOf(_to).sub(Other).sub(bounty);
        updateDate(_to);
        decreaseGlobalInterestAmount(Other.add(bounty));
        return _value;
        
        
    }
    
 
     
		  
    
    function createTokensFromEther()  private   {
               
        assert(msg.value >= 1 ether / 1000);
       
         uint256 tokens = currentRate.mul(msg.value).div(1 ether);


        transferFromOwner(msg.sender, tokens,2);
      
       if(saleStatus==0) {
           boughtWithEther[msg.sender]=boughtWithEther[msg.sender].add(tokens);
            tokensFromEther=tokensFromEther.add(tokens);
       }
      
    }
	
	
     
    
    function createTokensFromOther(address _to, uint256 howMuch, address referer) public  onlyOwner   { 
      
        require(_to!=address(this));
         transferFromOwner(_to, howMuch,2);
         if(referer!=0 && referer!=address(this) && referer!=0x0000000000000000000000000000000000000000 && howMuch.div(10)>0) {
             transferFromOwner(referer, howMuch.div(10),1);
	         if(saleStatus==0) {
	             	tokensFromEther=tokensFromEther.add( howMuch.div(10));
	 				bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add( howMuch.div(10));
	         	}
         }
         if(saleStatus==0) boughtWithOther[_to]= boughtWithOther[_to].add(howMuch);
    }

	    
	
	function transferFromOwner(address _to, uint256 _amount, uint t) private {
	   require(_to!=address(this) && _to!=address(owner) );
        balances[owner]=balances[owner].sub(_amount); 
        balances[_to]=balanceOf(_to).add(_amount);
        updateDate(_to);

        increaseGlobalInterestAmount(_amount);
	    
	   
	     if(t==2) emit Sale(_to, _amount);
        emit Transfer(owner, _to, _amount);	     
	}
	

    function increaseGlobalInterestAmount(uint256 c) private 
    {
        globalInterestAmount=globalInterestAmount.add(c);
		
    }
    
    function decreaseGlobalInterestAmount(uint256 c) private
    {
        if(c<globalInterestAmount) {
            globalInterestAmount=globalInterestAmount.sub(c);
        }
            
        
    }
    
    function() external payable {
        createTokensFromEther();
    }

    
}