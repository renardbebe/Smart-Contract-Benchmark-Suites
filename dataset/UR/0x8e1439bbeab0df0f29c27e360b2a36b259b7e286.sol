 

pragma solidity ^0.4.24;
 
contract TokenERC20 {
     
    string public name;
     
    string public symbol;
     
    uint256 public totalSupply;
     
    uint8 public decimals = 18;

     
    mapping (address => uint256) public balanceOf;

     
    mapping(address => mapping(address => uint256)) allowance;


    mapping (address => uint256) public freezeOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

     
    event Freeze(address indexed from, uint256 value);

     
    event Unfreeze(address indexed from, uint256 value);

    constructor(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimalUnits) public {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {

         
        require(_to != 0x0);

         
        require(balanceOf[_from] >= _value);

         
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

         
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {

        _transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function freeze(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);             
        require(_value > 0);
        balanceOf[msg.sender] -= _value;                       
        freezeOf[msg.sender] += _value;
        Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) returns (bool success) {
        require(freezeOf[msg.sender]>= _value);             
        require(_value > 0);
        freezeOf[msg.sender] -= _value;                       
        balanceOf[msg.sender] += _value;
        Unfreeze(msg.sender, _value);
        return true;
    }



}