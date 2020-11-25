 

pragma solidity ^0.4.25;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }   

contract TokenERC20 {
 
    string public name ;
    string public symbol ;
    uint8 public decimals = 18;   
    uint256 public totalSupply;  
    address public owner;

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;

      
    event Transfer(address indexed from, address indexed to, uint256 value);

      
    event Burn(address indexed from, uint256 value);

       
    event AddSupply(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   

        balanceOf[msg.sender] = totalSupply;     

        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);     
        require(balanceOf[_from] >= _value);         
        require(balanceOf[_to] + _value > balanceOf[_to]);   

        uint previousBalances = balanceOf[_from] + balanceOf[_to];   
        balanceOf[_from] -= _value; 
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);    
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);   
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value); 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        emit Approval(msg.sender, _spender, _value);
        allowance[msg.sender][_spender] = _value;    
        return true;
    }

    function increaseApproval (address _spender, uint _value)public 
        returns (bool success) {
        require(allowance[msg.sender][_spender] + _value >=allowance[msg.sender][_spender]);
        allowance[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender,allowance[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval (address _spender, uint _value)public 
        returns (bool success) {
        if (_value > allowance[msg.sender][_spender]) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] -= _value;
        }
        emit Approval(msg.sender, _spender,allowance[msg.sender][_spender]);
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);         
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

      
    function addSupply(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender]+_value>balanceOf[msg.sender]); 
        require(totalSupply+_value>totalSupply);         
        require(owner == msg.sender);
        balanceOf[msg.sender] += _value;
        totalSupply += _value;
        emit AddSupply(msg.sender, _value);
        return true;
    }
}