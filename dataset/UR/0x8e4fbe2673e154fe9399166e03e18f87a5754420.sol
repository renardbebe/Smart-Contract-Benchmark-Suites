 

 
 
pragma solidity ^0.4.18;

 

library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns(uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal constant returns(uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns(uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}


 

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

 
contract BubbleToneToken is ERC20 {
    using SafeMath for uint;
    string public name = "Universal Bonus Token | t.me/bubbletonebot";
    string public symbol = "UBT";
    uint public decimals = 18;  

     
    address public owner;
    
     
    event Burn(address indexed _from, uint _value);
    event Mint(address indexed _to, uint _value);
    event ManagerAdded(address _manager);
    event ManagerRemoved(address _manager);
    event Defrosted(uint timestamp);
    event Frosted(uint timestamp);

     
    bool public tokensAreFrozen = true;

     
    mapping(address => bool) public isManager;


     
    modifier onlyOwner { 
        require(msg.sender == owner); 
        _; 
    }

     
    modifier onlyManagers { 
        require(isManager[msg.sender]); 
        _; 
    }


    
    function BubbleToneToken(address _owner) public {
       owner = _owner;
       isManager[_owner] = true;
    }

    
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

    
    function transfer(address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        require(_to != address(0) && _to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }



   
    function addManager(address _manager) onlyOwner external {
        require(!isManager[_manager]);
        isManager[_manager] = true;
        ManagerAdded(_manager);
    }

   
    function removeManager(address _manager) onlyOwner external {
        require(isManager[_manager]);
        isManager[_manager] = false;
        ManagerRemoved(_manager);
    }

    
    function unfreeze() external onlyOwner {
       tokensAreFrozen = false;
       Defrosted(now);
    }


    
    function freeze() external onlyOwner {
       tokensAreFrozen = true;
       Frosted(now);
    }



     
    function batchMint(
        address[] _holders, 
        uint[] _amount) 
        external
        onlyManagers {
        require(_holders.length == _amount.length);
        for (uint i = 0; i < _holders.length; i++) {
            require(_mint(_holders[i], _amount[i]));
        }
    }

    
    function burnTokens(address _holder, uint _value) external onlyManagers {
        require(balances[_holder] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_holder] = balances[_holder].sub(_value);
        Burn(_holder, _value);
    }



     
    function withdraw(address _token, uint _amount) 
        external
        onlyOwner 
        returns (bool success) {
        return ERC20(_token).transfer(owner, _amount);
    }

    
    function _mint(address _holder, uint _value) private returns (bool) {
        require(_value > 0);
        require(_holder != address(0) && _holder != address(this));
        balances[_holder] = balances[_holder].add(_value);
        totalSupply = totalSupply.add(_value);
        Transfer(address(0), _holder, _value);
        return true;
    }

}