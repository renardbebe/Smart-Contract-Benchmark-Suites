 

pragma solidity ^0.5.0;


contract EIP20Interface{
     
    function balanceOf(address _owner) public view returns (uint256 balance);
     
    function transfer(address _to, uint256 _value)public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     
    function approve(address _spender, uint256 _value) public returns (bool success);
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract XcoinToken is EIP20Interface {
     
    string public name;
      
    string public symbol;
     
    uint8 public decimals;
      
    uint256 public totalSupply;

    mapping(address=>uint256) balances ;

    mapping(address=>mapping(address=>uint256)) allowances;
    constructor (string memory  _name,string memory  _symbol, uint8  _decimals,uint256  _totalSupply) public{       
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;
    balances[msg.sender] = _totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
     
    function transfer(address _to, uint256 _value)public  returns (bool success){
        require(_value >0 && balances[_to] + _value > balances[_to] && balances[msg.sender] > _value);
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to,_value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint256 allowan = allowances[_from][_to];
        require(allowan > _value && balances[_from] >= _value && _to == msg.sender && balances[_to] + _value>balances[_to]);
        allowances[_from][_to] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_value >0 && balances[msg.sender] > _value);
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
                return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
   
    

}