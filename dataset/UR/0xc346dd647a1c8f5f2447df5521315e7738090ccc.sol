 

pragma solidity ^0.4.21;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8  public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowances;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


     
    function ERC20Token(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        decimals = _decimals;

        totalSupply = _initialSupply * 10 ** uint256(decimals);   
        balances[msg.sender] = totalSupply;                 
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
         
        require(_to != address(0));
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
         
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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
         
        require(allowances[msg.sender][_spender] + _addedValue > allowances[msg.sender][_spender]);

        allowances[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
}