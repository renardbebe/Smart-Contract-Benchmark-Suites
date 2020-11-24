 

 
 
pragma solidity ^0.4.21;

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
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

contract MOSToken is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2 ** 256 - 1;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    address public owner;

    function MOSToken() public {
        totalSupply = 5 * (10 ** 8) * (10 ** 18);
         
        balances[msg.sender] = totalSupply;
         
        name = 'MOSDAO token';
         
        decimals = 18;
         
        symbol = 'MOS';
         
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
         
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        }
        emit Transfer(_from, _to, _value);  
         
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
         
        return true;
    }

    function increaseApprove(address _spender, uint256 _value) public returns (bool) {
        return approve(_spender, SafeMath.add(allowed[msg.sender][_spender], _value));
    }

    function decreaseApprove(address _spender, uint256 _value) public returns (bool) {
        return approve(_spender, SafeMath.sub(allowed[msg.sender][_spender], _value));
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mint(uint256 _value) public returns (bool success) {
        require(owner == msg.sender);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        totalSupply = SafeMath.add(totalSupply, _value);
        emit Transfer(address(0), msg.sender, _value);
         
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply, _value);
        emit Transfer(msg.sender, address(0), _value);
         
        return true;
    }
}