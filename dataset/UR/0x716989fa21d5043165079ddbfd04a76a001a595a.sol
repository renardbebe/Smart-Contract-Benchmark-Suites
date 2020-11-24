 

pragma solidity ^0.4.18;

 
 
 
 
 
contract ERC20 {
     
    uint256 public totalSupply;
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event TransferOfPower(address indexed _from, address indexed _to);
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract COCTokenBase is ERC20 {
     
    string public name;
    string public symbol;
    uint8  public decimals = 18;
    address public administrator;
     

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowances;


     
    event Burn(address indexed from, uint256 value);


     
    function COCTokenBase(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        decimals = _decimals;
        administrator = msg.sender;

        totalSupply = _initialSupply * 10 ** uint256(decimals);   
        balances[administrator] = totalSupply;                 
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);

        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        return _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_value <= allowances[_from][msg.sender]);      
        allowances[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        if (approve(_spender, _value)) {
            TokenRecipient spender = TokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

     
    function burn(uint256 _value) public returns(bool) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns(bool) {
        require(balances[_from] >= _value);                 
        require(_value <= allowances[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowances[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

     
    function transferOfPower(address _to) public returns (bool) {
        require(msg.sender == administrator);
        uint value = balances[msg.sender];
        _transfer(msg.sender, _to, value);
        administrator = _to; 
        TransferOfPower(msg.sender, _to);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
         
        require(allowances[msg.sender][_spender] + _addedValue > allowances[msg.sender][_spender]);

        allowances[msg.sender][_spender] += _addedValue;
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

}


contract COCToken is COCTokenBase {

    function COCToken() COCTokenBase(100000000000, "COC Token", "COC", 18) public {

    }
}