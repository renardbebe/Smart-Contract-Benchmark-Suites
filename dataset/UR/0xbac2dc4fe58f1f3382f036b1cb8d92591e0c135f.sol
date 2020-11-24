 

pragma solidity ^0.4.16;

 

 
 
 

 


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
         
        balanceOf[_from] -= _value;                          
         
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
 
 

contract MiningToken is owned, TokenERC20 {
    uint256 public supplyReady;   
    uint256 public min4payout;    
    uint256 public centsPerMonth; 
    mapping(uint256 => address) public holders;     
    mapping(address => uint256) public indexes;
    uint256 public num_holders=1;
     
    function MiningToken(
        string tokenName,
        string tokenSymbol
    ) TokenERC20(0, tokenName, tokenSymbol) public {
        centsPerMonth=0;
        decimals=0;
        setMinimum(0);
        holders[num_holders++]=(msg.sender);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        if(indexes[_to]==0||holders[indexes[_to]]==0){
            indexes[_to]=num_holders;
            holders[num_holders++]=_to;
        }
        Transfer(_from, _to, _value);
    }
	
	 
    function setMinimum(uint256 d) onlyOwner public{
        min4payout=d*1 ether / 1000;
    }
	
	 
    function setCentsPerMonth(uint256 amount) onlyOwner public {
        centsPerMonth=amount;
    }
	
	 
	 
    function getPayout(uint etherPrice) onlyOwner public {
        require(this.balance>min4payout);
        uint256 perToken=this.balance/totalSupply;
        for (uint i = 1; i < num_holders; i++) {
            address d=holders[i];
            if(d!=0){
                uint bal=balanceOf[d];
                if(bal==0){
                    holders[i]=0;
                }else{
                    uint powercost=((bal*centsPerMonth)/100) *( 1 ether/etherPrice);
                    holders[i].transfer((bal * perToken)-powercost);
                }
            }
        }
        owner.transfer(((totalSupply*centsPerMonth)/100) *( 1 ether/etherPrice));  
    }
	
	 
    function mint(uint256 amt) onlyOwner public {
        balanceOf[owner] += amt;
        totalSupply += amt;
        Transfer(this, msg.sender, amt);
    }
	 
    function mintTo(uint256 amt,address to) onlyOwner public {
        balanceOf[to] += amt;
        totalSupply += amt;
        Transfer(this, to, amt);
        if(indexes[to]==0||holders[indexes[to]]==0){
            indexes[to]=num_holders;
            holders[num_holders++]=to;
        }
    }
	
	
	 
	
     
     
     
     
     
     
     
	
	 
	
    function() payable public{
        
    }
	
	
	 
	 
	
	 
	 
    function selfDestruct() onlyOwner payable public{
        uint256 perToken=this.balance/totalSupply;
        for (uint i = 1; i < num_holders; i++) {
            holders[i].transfer(balanceOf[holders[i]] * perToken);
        }
		 
        selfdestruct(owner);
    }
}