 

pragma solidity ^ 0.4 .8;


contract ERC20 {

    uint public totalSupply;

    function balanceOf(address who) constant returns(uint256);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function transfer(address to, uint value) returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

}

contract blockoptions is ERC20

{

        
       
      string public name = "blockoptions";
    
       
      string public symbol = "BOPT";
    
       
      uint8 public decimals = 8;    
    
       
      uint public totalSupply=20000000 * 100000000;
      
       uint pre_ico_start;
       uint pre_ico_end;
       uint ico_start;
       uint ico_end;
       mapping(uint => address) investor;
       mapping(uint => uint) weireceived;
       mapping(uint => uint) optsSent;
      
        event preico(uint counter,address investors,uint weiReceived,uint boptsent);
        event ico(uint counter,address investors,uint weiReceived,uint boptsent);
        uint counter=0;
        uint profit_sent=0;
        bool stopped = false;
        
      function blockoptions(){
          owner = msg.sender;
          balances[owner] = totalSupply ;  
          pre_ico_start = now;
          pre_ico_end = pre_ico_start + 7 days;
          
        }
       
      mapping(address => uint) balances;
    
       
      mapping (address => mapping (address => uint)) allowed;
    
       
      address public owner;
      
       
      modifier onlyOwner() {
        if (msg.sender == owner)
          _;
      }
    
       
      function transferOwnership(address newOwner) onlyOwner {
          balances[newOwner] = balances[owner];
          balances[owner]=0;
          owner = newOwner;
      }

         
        function Mul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
           
          assert(a == 0 || c / a == b);
          return c;
        }
    
         
        function Div(uint a, uint b) internal returns (uint) {
           
          assert(b > 0);
          uint c = a / b;
          assert(a == b * c + a % b);
          return c;
        }
    
         
        function Sub(uint a, uint b) internal returns (uint) {
           
          assert(b <= a);
          return a - b;
        }
    
         
        function Add(uint a, uint b) internal returns (uint) {
          uint c = a + b;
           
          assert(c>=a && c>=b);
          return c;
        }
    
       
        function assert(bool assertion) internal {
          if (!assertion) {
            throw;
          }
        }
    
     
      function transfer(address _to, uint _value) returns (bool){

        uint check = balances[owner] - _value;
        if(msg.sender == owner && now>=pre_ico_start && now<=pre_ico_end && check < 1900000000000000)
        {
            return false;
        }
        else if(msg.sender ==owner && now>=pre_ico_end && now<=(pre_ico_end + 16 days) && check < 1850000000000000)
        {
            return false;
        }
        else if(msg.sender == owner && check < 150000000000000 && now < ico_start + 180 days)
        {
            return false;
        }
        else if (msg.sender == owner && check < 100000000000000 && now < ico_start + 360 days)
        {
            return false;
        }
        else if (msg.sender == owner && check < 50000000000000 && now < ico_start + 540 days)
        {
            return false;
        }
         
       else if (_value > 0) {
           
          balances[msg.sender] = Sub(balances[msg.sender],_value);
           
          balances[_to] = Add(balances[_to],_value);
           
          Transfer(msg.sender, _to, _value);
          return true;
        }
        else{
          return false;
        }
      }
      
       
      function transferFrom(address _from, address _to, uint _value) returns (bool) {
    
         
        if (_value > 0) {
           
          var _allowance = allowed[_from][msg.sender];
           
          balances[_to] = Add(balances[_to], _value);
           
          balances[_from] = Sub(balances[_from], _value);
           
          allowed[_from][msg.sender] = Sub(_allowance, _value);
           
          Transfer(_from, _to, _value);
          return true;
        }else{
          return false;
        }
      }
      
       
      function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
      }
      
       
      function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
         
        Approval(msg.sender, _spender, _value);
        return true;
      }
      
       
      function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
      }
      
        
    	function drain() onlyOwner {
    		owner.send(this.balance);
    	}
	
    	function() payable 
    	{   
    	    if(stopped && msg.sender != owner)
    	    revert();
    	     else if(msg.sender == owner)
    	    {
    	        profit_sent = msg.value;
    	    }
    	   else if(now>=pre_ico_start && now<=pre_ico_end)
    	    {
    	        uint check = balances[owner]-((400*msg.value)/10000000000);
    	        if(check >= 1900000000000000)
                pre_ico(msg.sender,msg.value);
    	    }
            else if (now>=ico_start && now<ico_end)
            {
                main_ico(msg.sender,msg.value);
            }
            
        }
       
       function pre_ico(address sender, uint value)payable
       {
          counter = counter+1;
	      investor[counter]=sender;
          weireceived[counter]=value;
          optsSent[counter] = (400*value)/10000000000;
          balances[owner]=balances[owner]-optsSent[counter];
          balances[investor[counter]]+=optsSent[counter];
          preico(counter,investor[counter],weireceived[counter],optsSent[counter]);
       }
       
       function  main_ico(address sender, uint value)payable
       {
           if(now >= ico_start && now <= (ico_start + 7 days))  
           {
              counter = counter+1;
    	      investor[counter]=sender;
              weireceived[counter]=value;
              optsSent[counter] = (250*value)/10000000000;
              balances[owner]=balances[owner]-optsSent[counter];
              balances[investor[counter]]+=optsSent[counter];
              ico(counter,investor[counter],weireceived[counter],optsSent[counter]);
           }
           else if (now >= (ico_start + 7 days) && now <= (ico_start + 14 days))  
           {
              counter = counter+1;
    	      investor[counter]=sender;
              weireceived[counter]=value;
              optsSent[counter] = (220*value)/10000000000;
              balances[owner]=balances[owner]-optsSent[counter];
              balances[investor[counter]]+=optsSent[counter];
              ico(counter,investor[counter],weireceived[counter],optsSent[counter]);
           }
           else if (now >= (ico_start + 14 days) && now <= (ico_start + 31 days))  
           {
              counter = counter+1;
    	      investor[counter]=sender;
              weireceived[counter]=value;
              optsSent[counter] = (200*value)/10000000000;
              balances[owner]=balances[owner]-optsSent[counter];
              balances[investor[counter]]+=optsSent[counter];
              ico(counter,investor[counter],weireceived[counter],optsSent[counter]);
           }
       }
       
       function startICO()onlyOwner
       {
           ico_start = now;
           ico_end=ico_start + 31 days;
           pre_ico_start = 0;
           pre_ico_end = 0;
           
       }
       
      
        function endICO()onlyOwner
       {
          stopped=true;
          if(balances[owner] > 150000000000000)
          {
              uint burnedTokens = balances[owner]-150000000000000;
           totalSupply = totalSupply-burnedTokens;
           balances[owner] = 150000000000000;
          }
       }

        struct distributionStruct
        {
            uint divident;
            bool dividentStatus;
        }   
        mapping(address => distributionStruct) dividentsMap;
        mapping(uint => address)requestor;
   
         event dividentSent(uint requestNumber,address to,uint divi);
         uint requestCount=0;
          
          function distribute()onlyOwner
          {
              for(uint i=1; i <= counter;i++)
              {
                dividentsMap[investor[i]].divident = (balanceOf(investor[i])*profit_sent)/(totalSupply*100000000);
                dividentsMap[investor[i]].dividentStatus = true;
              }
          }
           
          function requestDivident()payable
          {
              requestCount = requestCount + 1;
              requestor[requestCount] = msg.sender;
                  if(dividentsMap[requestor[requestCount]].dividentStatus == true)
                  {   
                      dividentSent(requestCount,requestor[requestCount],dividentsMap[requestor[requestCount]].divident);
                      requestor[requestCount].send(dividentsMap[requestor[requestCount]].divident);
                      dividentsMap[requestor[requestCount]].dividentStatus = false;
                  }
               
          }

}