 

pragma solidity ^0.4.21;

 
 
 
 
 
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y)
            revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) {
            revert();
        }
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        if (x > MAX_UINT256 / y) {
            revert();
        }
        return x * y;
    }
}

 
 
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);

       
    }
}

 
contract Pharamore is ERC20, SafeMath {

    string public name = "Pharamore";

    string public symbol = "MORE";

    uint8 public decimals = 8;

    uint256 public totalSupply = 950000 * 10**8;

    address public owner;

    bool public unlocked = false;

    bool public tokenCreated = false;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;


     
	
    function Pharamore() public {

         
         
        require(tokenCreated == false);
        tokenCreated = true;

        owner = msg.sender;
        balances[owner] = totalSupply;

         
        require(balances[owner] > 0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
     
     
     
	
    function distributeAirdrop(address[] addresses, uint256 amount) onlyOwner public {
         
         
        require(!unlocked);

        uint256 normalizedAmount = amount * 10**8;
		
         
         
		
        require(balances[owner] >= safeMul(addresses.length, normalizedAmount));
        for (uint i = 0; i < addresses.length; i++) {
            balances[owner] = safeSub(balanceOf(owner), normalizedAmount);
            balances[addresses[i]] = safeAdd(balanceOf(addresses[i]), normalizedAmount);
            Transfer(owner, addresses[i], normalizedAmount);
        }
    }

     
    function name() constant public returns (string _name) {
        return name;
    }
     
    function symbol() constant public returns (string _symbol) {
        return symbol;
    }
     
    function decimals() constant public returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() constant public returns (uint256 _totalSupply) {
        return totalSupply;
    }

     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {

         
         
        require(unlocked);

        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) {
                revert();
            }
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value, bytes _data) public  returns (bool success) {

         
         
        require(unlocked);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
     
    function transfer(address _to, uint _value) public returns (bool success) {

         
         
        require(unlocked);

         
         
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) {
            revert();
        }
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) {
            revert();
        }
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

      
      
    function unlockForever() onlyOwner public {
        unlocked = true;
    }

     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        require(unlocked);
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        balances[_from] = safeSub(balanceOf(_from), _value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
         
         
        require(unlocked);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}