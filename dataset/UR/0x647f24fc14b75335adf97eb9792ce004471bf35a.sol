 

pragma solidity ^0.4.18;

 
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert_ex(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert_ex(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert_ex(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal   pure  returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function assert_ex(bool assert_exion) internal pure{
        if (!assert_exion) {
          revert();
        }
    }
}


contract Owned {
    address public owner;

    function Owned() public {
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


contract ERC20Interface {

    using SafeMath for uint;
    uint public _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;


    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);



    function totalSupply() constant returns (uint256 totalSupply) {
      totalSupply = _totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint _value) public returns (bool success) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
          revert();
        }

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function addApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function subApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract ERC223ReceivingContract {

    event TokenFallback(address _from, uint _value, bytes _data);

     
    function tokenFallback(address _from, uint _value, bytes _data)public {
        TokenFallback(_from,_value,_data);
    }
}


contract StanderdToken is ERC20Interface, ERC223ReceivingContract, Owned {



     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length != size + 4) {
         revert();
        }
        _;
    }

     
    function transfer(address _to, uint _value) public returns (bool) {
        address _from = msg.sender;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }


    function transferFrom(address _from,address _to, uint _value) public returns (bool) {
         
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}


contract PreviligedToken is Owned {

    using SafeMath for uint;

    mapping (address => uint) previligedBalances;
    mapping (address => mapping (address => uint)) previligedallowed;

    event PreviligedLock(address indexed from, address indexed to, uint value);
    event PreviligedUnLock(address indexed from, address indexed to, uint value);
    event Previligedallowed(address indexed _owner, address indexed _spender, uint _value);

    function previligedBalanceOf(address _owner) public view returns (uint balance) {
        return previligedBalances[_owner];
    }

    function previligedApprove(address _owner, address _spender, uint _value) onlyOwner public returns (bool success) {

         
         
         
         
        if ((_value != 0) && (previligedallowed[_owner][_spender] != 0)) {
          revert();
        }

        previligedallowed[_owner][_spender] = _value;
        Previligedallowed(_owner, _spender, _value);
        return true;
    }

    function getPreviligedallowed(address _owner, address _spender) public view returns (uint remaining) {
        return previligedallowed[_owner][_spender];
    }

    function previligedAddApproval(address _owner, address _spender, uint _addedValue) onlyOwner public returns (bool) {
        previligedallowed[_owner][_spender] = previligedallowed[_owner][_spender].add(_addedValue);
        Previligedallowed(_owner, _spender, previligedallowed[_owner][_spender]);
        return true;
    }

    function previligedSubApproval(address _owner, address _spender, uint _subtractedValue) onlyOwner public returns (bool) {
        uint oldValue = previligedallowed[_owner][_spender];
        if (_subtractedValue > oldValue) {
          previligedallowed[_owner][_spender] = 0;
        } else {
          previligedallowed[_owner][_spender] = oldValue.sub(_subtractedValue);
        }
        Previligedallowed(_owner, _spender, previligedallowed[_owner][_spender]);
        return true;
    }
}


contract MitToken is StanderdToken, PreviligedToken {

    using SafeMath for uint;

    event Burned(address burner, uint burnedAmount);

    function MitToken() public {

        uint initialSupply = 6000000000;

        decimals = 18;
        _totalSupply = initialSupply * 10 ** uint(decimals);   
        balances[msg.sender] = _totalSupply;                 
        name = "MitCoin";                                    
        symbol = "MITC";                                
    }

     
    function mintToken(address _target, uint _mintedAmount) onlyOwner public {
        balances[_target] = balances[_target].add(_mintedAmount);
        _totalSupply = _totalSupply.add(_mintedAmount);

        Transfer(address(0), _target, _mintedAmount);
    }

    function burn(uint _amount) onlyOwner public {
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);

        Burned(burner, _amount);
    }

    function previligedLock(address _to, uint _value) onlyOwner public returns (bool) {
        address _from = msg.sender;
        balances[_from] = balances[_from].sub(_value);
         
        previligedBalances[_to] = previligedBalances[_to].add(_value);
        PreviligedLock(_from, _to, _value);
        return true;
    }

    function previligedUnLock(address _from, uint _value) public returns (bool) {
        address to = msg.sender;  
        require(to != address(0));
        require(_value <= previligedBalances[_from]);
        require(_value <= previligedallowed[_from][msg.sender]);

        previligedBalances[_from] = previligedBalances[_from].sub(_value);
        balances[to] = balances[to].add(_value);
        previligedallowed[_from][msg.sender] = previligedallowed[_from][msg.sender].sub(_value);
        PreviligedUnLock(_from, to, _value);
        return true;
    }
}