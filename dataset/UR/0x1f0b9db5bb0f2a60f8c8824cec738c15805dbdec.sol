 

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

    contract Nexium { 
         
        string public name;
        string public symbol;
        uint8 public decimals;

         
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint)) public allowance;
        mapping (address => mapping (address => uint)) public spentAllowance;

         
        event Transfer(address indexed from, address indexed to, uint256 value);

         
        function Nexium() {
            balanceOf[msg.sender] = 100000000000;               
            name = 'Nexium';                                    
            symbol = 'NxC';                                
            decimals = 3;                             
        }

         
        function transfer(address _to, uint256 _value) {
            if (balanceOf[msg.sender] < _value) throw;            
            if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
            balanceOf[msg.sender] -= _value;                      
            balanceOf[_to] += _value;                             
            Transfer(msg.sender, _to, _value);                    
        }

         

        function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
            allowance[msg.sender][_spender] = _value;     
            tokenRecipient spender = tokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this, _extraData);
			
			return true;
        }

         

        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
            if (balanceOf[_from] < _value) throw;                  
            if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
            if (spentAllowance[_from][msg.sender] + _value > allowance[_from][msg.sender]) throw;    
            balanceOf[_from] -= _value;                           
            balanceOf[_to] += _value;                             
            spentAllowance[_from][msg.sender] += _value;
            Transfer(msg.sender, _to, _value); 
			
			return true;
        } 

         
        function () {
            throw;      
        }        
    }