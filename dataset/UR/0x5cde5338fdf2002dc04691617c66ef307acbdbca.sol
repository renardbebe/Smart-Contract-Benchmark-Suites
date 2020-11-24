 

pragma solidity ^0.4.18;

contract Token {

     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);



     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    
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

  function onePercent(uint256 a) internal constant returns (uint256){
      return div(a,uint256(100));
  }
  
  function power(uint256 a,uint256 b) internal constant returns (uint256){
      return mul(a,10**b);
  }
}

contract StandardToken is Token {
    using SafeMath for uint256;
    uint8 public decimals;                 
    mapping(address=>bool) internal withoutFee;
    uint256 internal maxFee;
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        uint256 fee=getFee(_value);
        if (balances[msg.sender].add(fee) >= _value && _value > 0) {
             
            doTransfer(msg.sender,_to,_value,fee);
            return true;
        }  else { return false; }
    }
    
    function getFee(uint256 _value) private returns (uint256){
        uint256 onePercentOfValue=_value.onePercent();
        uint256 fee=uint256(maxFee).power(decimals);
          
         
        if (_value.add(onePercentOfValue) >= fee) {
            return fee;
         
         
        } if (_value.add(onePercentOfValue) < fee) {
            return onePercentOfValue;
        }
    }
    function doTransfer(address _from,address _to,uint256 _value,uint256 fee) internal {
            balances[_from] =balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);
            if(!withoutFee[_from]){
                doBurn(_from,fee);
            }
    }
    
    function doBurn(address _from,uint256 _value) private returns (bool success){
        require(balanceOf(_from) >= _value);    
        balances[_from] =balances[_from].sub(_value);             
        _totalSupply =_totalSupply.sub(_value);                       
        Burn(_from, _value);
        return true;
    }
    
    function burn(address _from,uint256 _value) public returns (bool success) {
        return doBurn(_from,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        uint256 fee=getFee(_value);  
        uint256 valueWithFee=_value;
        if(!withoutFee[_from]){
            valueWithFee=valueWithFee.add(fee);
        }
        if (balances[_from] >= valueWithFee && allowed[_from][msg.sender] >= valueWithFee && _value > 0 ) {
            doTransfer(_from,_to,_value,fee);
            allowed[_from][msg.sender] =allowed[_from][msg.sender].sub(valueWithFee);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function totalSupply() constant returns (uint totalSupply){
        return _totalSupply;
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public _totalSupply;
}


 
contract FinalTestToken is StandardToken {

    function () {
         
        revert();
    }

     

     
    string public name;                    
    string public symbol;                  
    string public version = 'H1.0';        
    address private _owner;
     
    string public feeInfo = "Each operation costs 1% of the transaction amount, but not more than 250 tokens.";

    function FinalTestToken() {
        _totalSupply = 800000000000000000000000000; 
        _owner=msg.sender;
        balances[msg.sender] =_totalSupply;

         
        allocate(0x98592d09bA9B739BF9D563a601CB3F6c3A238475,20);  
        allocate(0xf088394D9AEec53096A18Fb192C98FD90495416C,20);  
        allocate(0x353c65713fDf8169f14bE74012a59eF9BAB00e9b,5);  

         
        allocate(0x52B8fA840468e2dd978936B54d0DC83392f4B4aC,35);  

         
        allocate(0x7DfE12664C21c00B6A3d1cd09444fC2CC9e7f192,20);  

        maxFee=250;  
        
        name = "Final Test Token";                       
        decimals = 18;                             
        symbol = "FTT";                           
    }

    function allocate(address _address,uint256 percent) private{
        uint256 bal=_totalSupply.onePercent().mul(percent);
         
        withoutFee[_address]=true;
        doTransfer(msg.sender,_address,bal,0);
    }
   
    function setWithoutFee(address _address,bool _withoutFee) public {
        require(_owner==msg.sender);
        withoutFee[_address]=_withoutFee;
    }
    
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}