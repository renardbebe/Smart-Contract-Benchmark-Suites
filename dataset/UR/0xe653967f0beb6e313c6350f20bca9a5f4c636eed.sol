 

pragma solidity ^0.4.25;

contract Utils {
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 _z = _x + _y;
        assert(_z >= _x);
        return _z;
    }

    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 _z = _x * _y;
        assert(_x == 0 || _z / _x == _y);
        return _z;
    }
    
    function safeDiv(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_y != 0); 
        uint256 _z = _x / _y;
        assert(_x == _y * _z + _x % _y); 
        return _z;
    }

}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract ERC20Token {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract StandardToken is ERC20Token, Utils, Ownable {

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value > balanceOf[_to]); 
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

}

contract Miss is StandardToken {

    string public constant name = "MISS";
    string public constant symbol = "MISS"; 
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1 * 10**26;
    address public constant OwnerWallet = 0x20543449bb9f520d24C05039868733b1B7Ec1856;
    
    function Miss(){
        balanceOf[OwnerWallet] = totalSupply;
        
        Transfer(0x0, OwnerWallet, balanceOf[OwnerWallet]);
    }
}