 

contract NoxonFund {

    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;  
    uint256 public Entropy;
    uint256 public ownbalance;  

	uint256 public sellPrice;  
    uint256 public buyPrice;  
    
     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    
    
     
    function token()  {
    
        if (owner!=0) throw;
        buyPrice = msg.value;
        balanceOf[msg.sender] = 1;     
        totalSupply = 1;               
        Entropy = 1;
        name = 'noxonfund.com';        
        symbol = '? SHARE';              
        decimals = 0;                  
        owner = msg.sender;
        setPrices();
    }
    

    
      
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;    
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }
	

    function setPrices() {
        ownbalance = this.balance;  
        sellPrice = ownbalance/totalSupply;
        buyPrice = sellPrice*2; 
    }
    
    
   function () returns (uint buyreturn) {
       
        uint256 amount = msg.value / buyPrice;                 
        balanceOf[msg.sender] += amount;                    
       
        totalSupply += amount;
        Entropy += amount;
        
        Transfer(0, msg.sender, amount);
        
        owner.send(msg.value/2);
         
        setPrices();
        return buyPrice;
   }
   

    
    function sell(uint256 amount) {
        setPrices();
        if (balanceOf[msg.sender] < amount ) throw;         
        Transfer(msg.sender, this, amount);                  
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;                    
        msg.sender.send(amount * sellPrice);                
        setPrices();

    }
	
	 
	event newincomelog(uint amount,string description);
	function newIncome(
        string JobDescription
    )
        returns (string result)
    {
        if (msg.value <= 1 ether/100) throw;
        newincomelog(msg.value,JobDescription);
        return JobDescription;
    }
    
    
    
     
    
    uint votecount;
    uint voteno; 
    uint voteyes;
    
    mapping (address => uint256) public voters;
    
    function newProposal(
        string JobDescription
    )
        returns (string result)
    {
        if (msg.sender == owner) {
            votecount = 0;
            newProposallog(JobDescription);
            return "ok";
        } else {
            return "Only admin can do this";
        }
    }
    

    
    
    function ivote(bool myposition) returns (uint result) {
        votecount += balanceOf[msg.sender];
        
        if (voters[msg.sender]>0) throw;
        voters[msg.sender]++;
        votelog(myposition,msg.sender,balanceOf[msg.sender]);
        return votecount;
    }

    
    event newProposallog(string description);
    event votelog(bool position, address voter, uint sharesonhand);
   
    
}