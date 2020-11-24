 

pragma solidity ^0.4.23;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
      
         
    }
}

contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);

    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC223Token is ERC223, SafeMath {

    mapping(address => uint) balances;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
  
     
    function name() public view returns (string _name) {
        return name;
    }
     
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
     
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }
  
  
     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) { 
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
     
     
    function transfer(address _to, uint _value) public returns (bool success) {
         
         
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}


contract owned {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract MoeSeed is ERC223Token, owned{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    constructor() public{
        name = "Moe Seed";
        symbol = "MOE";
        decimals = 18;
        totalSupply = 10000000000 * 10 ** decimals;
        balances[msg.sender] = totalSupply;
    }
    
    function changeOwner(address newOwner) onlyOwner public{
        uint balanceOwner = balanceOf(owner);
        balances[owner] = safeSub(balanceOf(owner), balanceOwner);
        balances[newOwner] = safeAdd(balanceOf(newOwner), balanceOwner);
        bytes memory empty;
        emit Transfer(owner, newOwner, balanceOwner, empty);
        emit Transfer(owner, newOwner, balanceOwner);
        transferOwnership(newOwner);
    }
    
    function transferFromOwner(address _from, address _to, uint _value, uint _fee) onlyOwner public{
        bytes memory empty;
        if (balanceOf(_from) < (_value + _fee)) revert();
        balances[_from] = safeSub(balanceOf(_from), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(_from, _to, _value, empty);
        emit Transfer(_from, _to, _value);
        balances[_from] = safeSub(balanceOf(_from), _fee);
        balances[owner] = safeAdd(balanceOf(owner), _fee);
        emit Transfer(_from, owner, _fee, empty);
        emit Transfer(_from, owner, _fee);
    }
}