 

 

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
    
    contract tokenRecipient { 
        function receiveApproval(address _from, uint256 _value, address _token); 
    }

    contract MyToken is owned { 
         
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public totalSupply;

         
        mapping (address => uint256) public balanceOf;
        mapping (address => bool) public frozenAccount; 
        mapping (address => mapping (address => uint256)) public allowance;
        mapping (address => mapping (address => uint256)) public spentAllowance;

         
        event Transfer(address indexed from, address indexed to, uint256 value);
        event FrozenFunds(address target, bool frozen);

         
        function MyToken(
            uint256 initialSupply, 
            string tokenName, 
            uint8 decimalUnits, 
            string tokenSymbol, 
            address centralMinter 
        ) { 
            if(centralMinter != 0 ) owner = msg.sender;          
            balanceOf[msg.sender] = initialSupply;               
            name = tokenName;                                    
            symbol = tokenSymbol;                                
            decimals = decimalUnits;                             
            totalSupply = initialSupply; 
        }

         
        function transfer(address _to, uint256 _value) {
            if (balanceOf[msg.sender] < _value) throw;            
            if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
            if (frozenAccount[msg.sender]) throw;                 
            balanceOf[msg.sender] -= _value;                      
            balanceOf[_to] += _value;                             
            Transfer(msg.sender, _to, _value);                    
        }

         
        function approveAndCall(address _spender, uint256 _value) returns (bool success) {
            allowance[msg.sender][_spender] = _value;  
            tokenRecipient spender = tokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this); 
            return true;         
        }

         
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
            if (balanceOf[_from] < _value) throw;                  
            if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
            if (spentAllowance[_from][msg.sender] + _value > allowance[_from][msg.sender]) throw;    
            balanceOf[_from] -= _value;                           
            balanceOf[_to] += _value;                             
            spentAllowance[_from][msg.sender] += _value;
            Transfer(_from, _to, _value); 
            return true;
        } 

         
        function () {
            throw;      
        }
        
        function mintToken(address target, uint256 mintedAmount) onlyOwner {
            balanceOf[target] += mintedAmount; 
            totalSupply += mintedAmount; 
            Transfer(0, owner, mintedAmount);
            Transfer(owner, target, mintedAmount);
        }

        function freezeAccount(address target, bool freeze) onlyOwner {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
}