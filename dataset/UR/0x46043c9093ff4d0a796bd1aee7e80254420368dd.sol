 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint32 _value, address _token, bytes _extraData) public; }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}    
    contract x32323 is owned {
        function TokenERC20(
            uint32 initialSupply,
            string tokenName,
            uint8 decimalUnits,
            string tokenSymbol,
            address centralMinter
        ) {
        if(centralMinter != 0 ) owner = centralMinter;
        }
        
         
        string public name;
        string public symbol;
        uint8 public decimals = 0;
         
        uint32 public totalSupply;

         
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

         
        event Transfer(address indexed from, address indexed to, uint32 value);

         
        event Burn(address indexed from, uint32 value);



             
        function TokenERC20(
            uint32 initialSupply,
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply =  23000000 ;   
            balanceOf[msg.sender] = totalSupply;                 
            name = "測試";                                    
            symbol = "測試";                                
        }

         
    
        mapping (address => bool) public frozenAccount;
        event FrozenFunds(address target, bool frozen);

        function freezeAccount(address target, bool freeze) onlyOwner {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
    
        function _transfer(address _from, address _to, uint32 _value) internal {
             
            require(_to != 0x0);
             
            require(balanceOf[_from] >= _value);
             
            require(balanceOf[_to] + _value > balanceOf[_to]);
             
            uint previousBalances = balanceOf[_from] + balanceOf[_to];
             
            balanceOf[_from] -= _value;
             
            balanceOf[_to] += _value;
            Transfer(_from, _to , _value);
             
            assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        }

         
        function transfer(address _to, uint32 _value) public {
            require(!frozenAccount[msg.sender]);
            _transfer(msg.sender, _to, _value);
        }

         
        function transferFrom(address _from, address _to, uint32 _value) public returns (bool success) {
            require(_value <= allowance[_from][msg.sender]);      
            allowance[_from][msg.sender] -= _value;
            _transfer(_from, _to, _value);
            return true;
        }

         
        function approve(address _spender, uint32 _value) public
            returns (bool success) {
            allowance[msg.sender][_spender] = _value;
            return true;
        }

         
        function approveAndCall(address _spender, uint32 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
            }
        }

          
        function burn(uint32 _value) public returns (bool success) {
            require(balanceOf[msg.sender] >= _value);    
            balanceOf[msg.sender] -= _value;             
            totalSupply -= _value;                       
            Burn(msg.sender,  _value);
            return true;
        }

         
        function burnFrom(address _from, uint32 _value) public returns (bool success) {
            require(balanceOf[_from] >= _value);                 
            require(_value <= allowance[_from][msg.sender]);     
            balanceOf[_from] -= _value;                          
            allowance[_from][msg.sender] -= _value;              
            totalSupply -= _value;                               
            Burn(_from,  _value);
            return true;
        }
    }