 

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


contract Exchange is Owned {

    event onExchangeTokenToEther(address who, uint256 tokenAmount, uint256 etherAmount);

    using SafeMath for uint256;

    Token public token = Token(0xD850942eF8811f2A866692A623011bDE52a462C1);

     
    uint256 public rate = 4025;

     
    uint256 public tokenQuota = 402500 ether;

     
     

    bool public tokenToEtherAllowed = true;
     

     


     
     
     
     
    mapping(address => uint256) accountQuotaUsed;

    function Exchange() {
    }

    function () payable {
    }


    function withdrawEther(address _address,uint256 _amount) onlyOwner {
        require(_address != 0);
        _address.transfer(_amount);
    }

    function withdrawToken(address _address, uint256 _amount) onlyOwner {
        require(_address != 0);
        token.transfer(_address, _amount);
    }

    function quotaUsed(address _account) constant returns(uint256 ) {
        return accountQuotaUsed[_account];
    }

     
    function setRate(uint256 _rate) onlyOwner {
        rate = _rate;
    }

     
    function setTokenQuota(uint256 _quota) onlyOwner {
        tokenQuota = _quota;
    }

     
     
     

     
    function setTokenToEtherAllowed(bool _allowed) onlyOwner {
        tokenToEtherAllowed = _allowed;
    }

     
     
     

    function receiveApproval(address _from, uint256 _value, address  , bytes  ) {
        exchangeTokenToEther(_from, _value);
    }

    function exchangeTokenToEther(address _from, uint256 _tokenAmount) internal {
        require(tokenToEtherAllowed);
        require(msg.sender == address(token));
        require(!isContract(_from));

        uint256 quota = tokenQuota.sub(accountQuotaUsed[_from]);                

        if (_tokenAmount > quota)
            _tokenAmount = quota;
        
        uint256 balance = token.balanceOf(_from);
        if (_tokenAmount > balance)
            _tokenAmount = balance;

        require(_tokenAmount>0);     

         
        require(token.transferFrom(_from, this, _tokenAmount));        

        accountQuotaUsed[_from] = _tokenAmount.add(accountQuotaUsed[_from]);
        
        uint256 etherAmount = _tokenAmount / rate;
        require(etherAmount > 0);
        _from.transfer(etherAmount);

         

        onExchangeTokenToEther(_from, _tokenAmount, etherAmount);
    }


     
     
     
     
     
     
     

     
     
     
     

     

     

     
     

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0)
            return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}