 

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function sendApproval(address _from, uint256 _value, address _token); }

contract MyToken is owned { 
     
    string public name;
    string public symbol;
    uint8 public decimals;
	uint8 public disableconstruction;
     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function MyTokenLoad(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address centralMinter) {
		if(disableconstruction != 2){
            if(centralMinter != 0 ) owner = msg.sender;          
            balanceOf[msg.sender] = initialSupply;               
            name = tokenName;                                    
            symbol = tokenSymbol;                                
            decimals = decimalUnits;                             
		}
    }
    function MyToken(){
        MyTokenLoad(10000000000000,'Kraze',8,'KRZ',0);
		disableconstruction=2;
    }
     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function () {
        throw;      
    }
}