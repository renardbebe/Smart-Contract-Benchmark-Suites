 

pragma solidity ^0.4.24;


 
interface ERC223 {

     
    function balanceOf(address _owner) external constant returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);



     
    function name() external constant returns  (string _name);
    function symbol() external constant returns  (string _symbol);
    function decimals() external constant returns (uint8 _decimals);
    function totalSupply() external constant returns (uint256 _totalSupply);


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Burn(address indexed burner, uint256 value);
}


 
contract ERC223ReceivingContract {

    TKN internal fallback;

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) external pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

         


    }
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



 
contract C3Coin is ERC223, Ownable {
    using SafeMath for uint;


    string public name = "C3coin";
    string public symbol = "CCC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10e10 * 1e18;


    constructor() public {
        balances[msg.sender] = totalSupply; 
    }


    mapping (address => uint256) public balances;

    mapping(address => mapping (address => uint256)) public allowance;


     
     
    function name() external constant returns (string _name) {
        return name;
    }
     
    function symbol() external constant returns (string _symbol) {
        return symbol;
    }
     
    function decimals() external constant returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() external constant returns (uint256 _totalSupply) {
        return totalSupply;
    }


     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty = hex"00000000";
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }


     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }


    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }


     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = 0;  
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }


     
    function multiTransfer(address[] _addresses, uint256 _amount) public returns (bool) {

        uint256 totalAmount = _amount.mul(_addresses.length);
        require(balances[msg.sender] >= totalAmount);

        for (uint j = 0; j < _addresses.length; j++) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_addresses[j]] = balances[_addresses[j]].add(_amount);
            emit Transfer(msg.sender, _addresses[j], _amount);
        }
        return true;
    }


     
    function multiTransfer(address[] _addresses, uint256[] _amounts) public returns (bool) {

        uint256 totalAmount = 0;

        for(uint j = 0; j < _addresses.length; j++){

            totalAmount = totalAmount.add(_amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);

        for (j = 0; j < _addresses.length; j++) {
            balances[msg.sender] = balances[msg.sender].sub(_amounts[j]);
            balances[_addresses[j]] = balances[_addresses[j]].add(_amounts[j]);
            emit Transfer(msg.sender, _addresses[j], _amounts[j]);
        }
        return true;
    }


     
    function burn(uint256 _value) onlyOwner public {
        _burn(msg.sender, _value);
    }

    function _burn(address _owner, uint256 _value) internal {
        require(_value <= balances[_owner]);
         
         

        balances[_owner] = balances[_owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_owner, _value);
        emit Transfer(_owner, address(0), _value);
    }

     
    function () public payable {
         
    }
}