 

pragma solidity ^0.4.25;
 contract Token{
     uint256 public totalSupply;
     
    function balanceOf(address _owner) public  view returns (uint256 balance);

    function  transfer(address _to, uint256 _value) public  returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)  public returns   
    (bool success);

    function approve(address _spender, uint256 _value) public  returns (bool success);

    function allowance(address _owner, address _spender) public view returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
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

contract StandardToken is Token {
    using SafeMath for uint256;
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public  returns 
    (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value); 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner) public  view  returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public  returns (bool success)   
    {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)  public  view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract QaMzyeToken is StandardToken { 

  
 string public name = "QaMzyeToken";

   
 string public symbol = "QMY";

   
 uint8 public decimals = 18;

   
 uint256 public INITIAL_SUPPLY = 520000000 * (10 ** 18);

    

 constructor() public 
 {
 
      totalSupply = INITIAL_SUPPLY;
    
      balances[msg.sender] = INITIAL_SUPPLY;
   
      emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  
  }

 

     
    
    function  approveAndCall (address  _spender, uint256  _value, bytes memory _extraData) public  returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
      if(
          !_spender.call(abi.encodeWithSelector(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")),msg.sender, _value, this, _extraData))
        ) { revert();}
        return true;
    }

}