 

pragma solidity ^0.4.11;

contract owned {

        address public owner;

        function owned() {
                owner = msg.sender;
        }

        modifier onlyOwner {
                if (msg.sender == owner)
                _;
        }


}

contract tokenRecipient {
        function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract IERC20Token {

         
        function totalSupply() constant returns (uint256 totalSupply);

         
         
        function balanceOf(address _owner) constant returns (uint256 balance);

         
         
         
         
        function transfer(address _to, uint256 _value) returns (bool success);

         
         
         
         
         
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

         
         
         
         
        function approve(address _spender, uint256 _value) returns (bool success);

         
         
         
        function allowance(address _owner, address _spender) constant returns (uint256 remaining);

        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
        event Burn(address indexed from, uint256 value);
}

contract Hedge is IERC20Token, owned{

         
        string public standard = "Hedge v1.0";
        string public name = "Hedge";
        string public symbol = "HDG";
        uint8 public decimals = 18;
        uint256 public initialSupply = 50000000 * 10 ** 18;
        uint256 public tokenFrozenUntilBlock;
        uint256 public timeLock = block.timestamp + 180 days;  

         
        uint256 supply = initialSupply;
        mapping (address => uint256) balances;
        mapping (address => mapping (address => uint256)) allowances;
        mapping (address => bool) restrictedAddresses;

        event TokenFrozen(uint256 _frozenUntilBlock, string _reason);

         
        function Hedge() {
                restrictedAddresses[0x0] = true;                         
                restrictedAddresses[address(this)] = true;       
                balances[msg.sender] = 50000000 * 10 ** 18;
        }

         
        function totalSupply() constant returns (uint256 totalSupply) {
                return supply;
        }

         
        function balanceOf(address _owner) constant returns (uint256 balance) {
                return balances[_owner];
        }

         function transferOwnership(address newOwner) onlyOwner {
                require(transfer(newOwner, balances[msg.sender]));
                owner = newOwner;
        }

         
        function transfer(address _to, uint256 _value) returns (bool success) {
                require (block.number >= tokenFrozenUntilBlock) ;        
                require (!restrictedAddresses[_to]) ;                 
                require (balances[msg.sender] >= _value);            
                require (balances[_to] + _value >= balances[_to]) ;   
                require (!(msg.sender == owner && block.timestamp < timeLock && (balances[msg.sender]-_value) < 10000000 * 10 ** 18));

                balances[msg.sender] -= _value;                      
                balances[_to] += _value;                             
                Transfer(msg.sender, _to, _value);                   
                return true;
        }

         
        function approve(address _spender, uint256 _value) returns (bool success) {
                require (block.number > tokenFrozenUntilBlock);  
                allowances[msg.sender][_spender] = _value;           
                Approval(msg.sender, _spender, _value);              
                return true;
        }

         
        function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
                tokenRecipient spender = tokenRecipient(_spender);               
                approve(_spender, _value);                                       
                spender.receiveApproval(msg.sender, _value, this, _extraData);   
                return true;
        }

         
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
                require (block.number > tokenFrozenUntilBlock);  
                require (!restrictedAddresses[_to]);                 
                require(balances[_from] >= _value);                 
                require (balances[_to] + _value >= balances[_to]);   
                require (_value <= allowances[_from][msg.sender]);   
                require (!(_from == owner && block.timestamp < timeLock && (balances[_from]-_value) < 10000000 * 10 ** 18));
                balances[_from] -= _value;                           
                balances[_to] += _value;                             
                allowances[_from][msg.sender] -= _value;             
                Transfer(_from, _to, _value);                        
                return true;
        }

        function burn(uint256 _value) returns (bool success) {
                require(balances[msg.sender] >= _value);                  
                balances[msg.sender] -= _value;                           
                supply-=_value;
                Burn(msg.sender, _value);
                return true;
        }

        function burnFrom(address _from, uint256 _value) returns (bool success) {
                require(balances[_from] >= _value);                 
                require(_value <= allowances[_from][msg.sender]);     
                balances[_from] -= _value;                          
                allowances[_from][msg.sender] -= _value;              
                supply -= _value;                               
                Burn(_from, _value);
                return true;
        }

         
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowances[_owner][_spender];
        }



         
        function freezeTransfersUntil(uint256 _frozenUntilBlock, string _reason) onlyOwner {
                tokenFrozenUntilBlock = _frozenUntilBlock;
                TokenFrozen(_frozenUntilBlock, _reason);
        }

        function unfreezeTransfersUntil(string _reason) onlyOwner {
                tokenFrozenUntilBlock = 0;
                TokenFrozen(0, _reason);
        }

         
        function editRestrictedAddress(address _newRestrictedAddress) onlyOwner {
                restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
        }

        function isRestrictedAddress(address _queryAddress) constant returns (bool answer){
                return restrictedAddresses[_queryAddress];
        }
}