 

pragma solidity ^0.4.17;


contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = 0x53315fa129e1cCcC51d8575105755505750F5A38;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) internal balances;
    
     
    function balanceOf(address _who) public view returns(uint256) {
        return balances[_who];
    }
    
     
    function transfer(address _to, uint256 _value) public returns(bool) {
        assert(balances[msg.sender] >= _value && _value > 0 && _to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
}


contract StandardToken is BasicToken, ERC20 {
    
    mapping (address => mapping (address => uint256)) internal allowances;
    
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        assert(allowances[_from][msg.sender] >= _value && _to != 0x0 && balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        assert(_spender != 0x0 && _value >= 0);
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}


contract SaveCoin is StandardToken, Ownable {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

     function SaveCoin() public{
        totalSupply =  1000000000e18;
        decimals =  18;
        name =   "Save Coin";
        symbol =  "SAVE";
        balances[msg.sender] = totalSupply; 
        Transfer (address(this), owner, totalSupply); 
     }


     function transfer(address _to, uint256 _value) public returns(bool) {
        require(_value > 0 && balances[msg.sender] >= _value && _to != 0x0);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Transfer(msg.sender, _to, _value);
        return true;
     }


     function transferFrom(address _owner, address _recipient, uint256 _value) public returns(bool){
         require(_value > 0 && balances[_owner] >= _value && allowances[_owner][msg.sender] >= _value && _recipient != 0x0);
         allowances[_owner][msg.sender]= allowances [_owner][msg.sender].sub(_value);
         balances[_owner] = balances [_owner].sub(_value);
         balances[_recipient] = balances[_recipient].add(_value);
         Transfer(_owner, _recipient, _value);   
         return true;
     }


     function approve(address _spender, uint256 _value) public returns(bool) {
         require(_spender != 0x0 && _value > 0x0);
         allowances[msg.sender][_spender] = 0;
         allowances[msg.sender][_spender] = _value;
         Approval(msg.sender, _spender, _value);
         return true;
     }


     function balanceOf(address _who) public constant returns(uint256) {
        return balances[_who];
     }

    function allowance(address _owner, address _spender) public constant returns(uint256) {
        return allowances[_owner][_spender];
     }

}