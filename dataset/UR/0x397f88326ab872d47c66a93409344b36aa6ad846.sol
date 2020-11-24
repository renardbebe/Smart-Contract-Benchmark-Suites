 

pragma solidity ^0.5.2;

contract VirtuDollar {
     
    string public name = "Virtu Dollar";
    string public symbol = "V$";
    string public standard = "Virtu Dollar v1.0";
    uint8 public decimals = 18;

     
    uint256 public VDollars;

     
    mapping( address => uint256) public balanceOf;

     
    mapping(address => mapping(address => uint256)) public allowance;

     
    address owner;

     
    constructor(uint256 _initialSupply) public {
         
        owner = msg.sender;
         
        balanceOf[owner] = _initialSupply * 10 ** uint256(decimals);
         
        VDollars = balanceOf[owner];
    }

     
    function transfer (address _to, uint256 _value) public returns (bool success) {
         
        require(balanceOf[msg.sender] >= _value);
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
         
        emit Transfer(msg.sender, _to, _value);
         
        return true;
    }

     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= balanceOf[_from]);
         
        require(_value <= allowance[_from][msg.sender]);
         
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
         
        allowance[_from][msg.sender] -= _value;
         
        emit Transfer(_from, _to, _value);
         
        return true;
    }

     
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        allowance[msg.sender][_spender] = _value;
         
        emit Approval(msg.sender, _spender, _value);
         
        return true;
    }

     
    event Burn (
        address indexed _from,
        uint256 _value
    );

     
    function burn (uint256 _value) public returns (bool success) {
         
        require(balanceOf[msg.sender] >= _value);
         
        balanceOf[msg.sender] -= _value;
         
        VDollars -= _value;
         
        emit Burn(msg.sender, _value);
         
        return true;
    }

     
    function burnFrom (address _from, uint256 _value) public returns (bool success) {
         
        require(balanceOf[_from] >= _value);
         
        require(allowance[_from][msg.sender] >= _value);
         
        balanceOf[_from] -= _value;
         
        allowance[_from][msg.sender] -= _value;
         
        VDollars -= _value;
         
        emit Burn(_from, _value);
         
        return true;
    }

     
    event Mint(
        address indexed _from,
        uint256 _value
    );

     
    function mint (uint256 _value) public returns (bool success) {
         
        require(msg.sender == owner);
         
        balanceOf[owner] += _value;
         
        VDollars += _value;
         
        emit Mint(msg.sender, _value);
         
        return true;
    }
}