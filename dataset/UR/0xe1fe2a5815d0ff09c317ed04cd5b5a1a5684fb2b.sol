 

pragma solidity ^0.4.2;

    contract owned {
        address public owner;
        constructor() public {
            owner = msg.sender;
        }
        modifier onlyOwner {
            require( msg.sender == owner);
            _;
        }
        function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
        }
    }

    contract OeroToken is owned {
        string  public name = "OERO";
        string  public symbol = "OEUR";
        string  public standard = "OERO v1.0";
        uint8 public decimals = 2;
        uint256 public totalSupply;

        event Transfer(
            address indexed _from,
            address indexed _to,
            uint256 _value
        );

        event Approval(
            address indexed _owner,
            address indexed _spender,
            uint256 _value
        );

        mapping(address => uint256) public balanceOf;
        mapping(address => mapping(address => uint256)) public allowance;

        constructor() public {
            balanceOf[msg.sender] = 100000000;
            totalSupply = 100000000;
        }

        function transfer(address _to, uint256 _value) public returns (bool success) {
            require(balanceOf[msg.sender] >= _value);
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

        function approve(address _spender, uint256 _value) public returns (bool success) {
            allowance[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }

        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(_value <= balanceOf[_from]);
            require(_value <= allowance[_from][msg.sender]);
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            allowance[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }

        function mintToken(address _to, uint256 _value) public onlyOwner  {
            balanceOf[_to] += _value;
            totalSupply += _value;
        }
        
        function burn(uint256 _value) public onlyOwner returns (bool success){
             require(balanceOf[msg.sender] >= _value);
             balanceOf[msg.sender] -= _value;
             totalSupply -= _value;
             return true;
        }
    }