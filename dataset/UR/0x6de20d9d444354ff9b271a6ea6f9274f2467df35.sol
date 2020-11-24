 

pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


 
 

contract Token {
     
     
     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}


contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);
}


contract Rollback is Owned, ApprovalReceiver {

    event onSetCredit(address account , uint256 amount);
    event onReturned(address who, uint256 tokenAmount, uint256 ethAmount);


    using SafeMath for uint256;
    
    Token public token = Token(0xD850942eF8811f2A866692A623011bDE52a462C1);

    uint256 public totalSetCredit;                   
    uint256 public totalReturnedCredit;              

    struct Credit {
        uint128 total;
        uint128 used;
    }

    mapping(address => Credit)  credits;            

    function Rollback() {
    }

    function() payable {
    }

    function withdrawETH(address _address,uint256 _amount) onlyOwner {
        require(_address != 0);
        _address.transfer(_amount);
    }

    function withdrawToken(address _address, uint256 _amount) onlyOwner {
        require(_address != 0);
        token.transfer(_address, _amount);
    }

    function setCredit(address _account, uint256 _amount) onlyOwner { 

        totalSetCredit += _amount;
        totalSetCredit -= credits[_account].total;        

        credits[_account].total = _amount.toUINT128();
        require(credits[_account].total >= credits[_account].used);
        onSetCredit(_account, _amount);
    }

    function getCredit(address _account) constant returns (uint256 total, uint256 used) {
        return (credits[_account].total, credits[_account].used);
    }    

    function receiveApproval(address _from, uint256 _value, address  , bytes  ) {
        require(msg.sender == address(token));

        require(credits[_from].total >= credits[_from].used);
        uint256 remainedCredit = credits[_from].total - credits[_from].used;

        if(_value > remainedCredit)
            _value = remainedCredit;  

        uint256 balance = token.balanceOf(_from);
        if(_value > balance)
            _value = balance;

        require(_value > 0);

        require(token.transferFrom(_from, this, _value));

        uint256 ethAmount = _value / 4025;
        require(ethAmount > 0);

        credits[_from].used += _value.toUINT128();
        totalReturnedCredit +=_value;

        _from.transfer(ethAmount);
        
        onReturned(_from, _value, ethAmount);
    }
}