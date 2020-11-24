 

pragma solidity ^0.4.22;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract iERC20v1{
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

    modifier mustBeValidValue(uint256 _value) {
        require(_value >= 0 && _value <= totalSupply);
        _;
    }
    
    modifier mustBeContract(address _spender) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(_spender) }
        require(codeSize > 0);
        _;
    }
     
    constructor(
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
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public mustBeValidValue(_value) {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public mustBeValidValue(_value) returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addValue) public mustBeValidValue(_addValue)
        returns (bool success) {
        
        require(allowance[msg.sender][_spender] + _addValue >= allowance[msg.sender][_spender]);
        require(balanceOf[msg.sender] >= allowance[msg.sender][_spender] + _addValue);
        allowance[msg.sender][_spender] += _addValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    
      
    function decreaseApproval(address _spender, uint256 _subValue) public mustBeValidValue(_subValue)
        returns (bool success) {
        
        uint oldValue = allowance[msg.sender][_spender];
        if (_subValue > oldValue)
           allowance[msg.sender][_spender] = 0;
        else
           allowance[msg.sender][_spender] = oldValue - _subValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

     
    function increaseApproveAndCall(address _spender, uint256 _addValue, bytes _extraData)
        public
        mustBeValidValue(_addValue)
        mustBeContract(_spender)
        returns (bool success) {
        
        if (increaseApproval(_spender, _addValue)) {
            tokenRecipient spender = tokenRecipient(_spender);
            spender.receiveApproval(msg.sender, allowance[msg.sender][_spender], this, _extraData);
            return true;
        }
    }
    
      
    function decreaseApproveAndCall(address _spender, uint256 _subValue, bytes _extraData)
        public
        mustBeValidValue(_subValue)
        mustBeContract(_spender)
        returns (bool success) {
   
        if (decreaseApproval(_spender, _subValue)) {
            tokenRecipient spender = tokenRecipient(_spender);
            spender.receiveApproval(msg.sender, allowance[msg.sender][_spender], this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public mustBeValidValue(_value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public mustBeValidValue(_value) returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}