 

 
 
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

 
contract BondToken is ERC20 {
    using SafeMath for uint;
    string public name = "Bond Film Platform";
    string public symbol = "BFP";
    uint public decimals = 18;

     
    address public owner;
    address public controller;
    address public airDropManager;
    
    event LogBuyForInvestor(address indexed investor, uint value, string txHash);
    event Burn(address indexed from, uint value);
    event Mint(address indexed to, uint value);
    
     
    bool public tokensAreFrozen = true;

     
    modifier onlyOwner { 
        require(msg.sender == owner); 
        _; 
    }

     
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

     
    modifier onlyAirDropManager { 
        require(msg.sender == airDropManager); 
        _; 
    }

    
    function BondToken(address _owner, address _controller, address _airDropManager) public {
       owner = _owner;
       controller = _controller;
       airDropManager = _airDropManager; 
    }

    
    function mint(address _holder, uint _value) 
        private
        returns (bool) {
        require(_value > 0);
        balances[_holder] = balances[_holder].add(_value);
        totalSupply = totalSupply.add(_value);
        Transfer(address(0), _holder, _value);
        return true;
    }


    
    function mintTokens(
        address _holder, 
        uint _value) 
        external 
        onlyOwner {
        require(mint(_holder, _value));
        Mint(_holder, _value);
    }

    
    function buyForInvestor(
        address _holder, 
        uint _value, 
        string _txHash
    ) 
        external 
        onlyController {
        require(mint(_holder, _value));
        LogBuyForInvestor(_holder, _value, _txHash);
    }



     
    function batchDrop(
        address[] _to, 
        uint[] _amount) 
        external
        onlyAirDropManager {
        require(_to.length == _amount.length);
        for (uint i = 0; i < _to.length; i++) {
            require(_to[i] != address(0));
            require(mint(_to[i], _amount[i]));
        }
    }


    
    function unfreeze() external onlyOwner {
       tokensAreFrozen = false;
    }


    
    function freeze() external onlyOwner {
       tokensAreFrozen = true;
    }

    
    function burnTokens(address _holder, uint _value) external onlyOwner {
        require(balances[_holder] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_holder] = balances[_holder].sub(_value);
        Burn(_holder, _value);
    }

    
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

    
    function transfer(address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
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

         
    function transferAnyTokens(address tokenAddress, uint tokens) 
        public
        onlyOwner 
        returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}