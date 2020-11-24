 

pragma solidity ^0.4.4;

contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
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
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


contract Fouracoin is StandardToken {
     
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0';        
    uint256 public unitsOneEthCanBuy;      
    address public fundsWallet;            


    function Fouracoin() {
        balances[msg.sender] = 300000000000000000000000000;                
        totalSupply = 300000000000000000000000000;                         
        name = "4A Coin";                                    
        decimals = 18;                             
        symbol = "4AC";
         
        fundsWallet = msg.sender;
    }

    function() payable{

      uint256 ondortmayis = 1526256000;
      uint256 yirmibirmay = 1526860800;
      uint256 yirmisekizmay = 1527465600;
      uint256 dorthaziran = 1528070400;
      uint256 onbirhaziran = 1528675200;
      uint256 onsekizhaziran = 1529280000;
      uint256 yirmibeshaz = 1529884800;

      if(ondortmayis > now) {
        require(balances[fundsWallet] >= msg.value * 100);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 100;
        balances[msg.sender] = balances[msg.sender] + msg.value * 100;
        Transfer(fundsWallet, msg.sender, msg.value * 100);  
        fundsWallet.transfer(msg.value);
      } else if(ondortmayis < now && yirmibirmay > now) {
        require(balances[fundsWallet] >= msg.value * 6000);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 6000;
        balances[msg.sender] = balances[msg.sender] + msg.value * 6000;
        Transfer(fundsWallet, msg.sender, msg.value * 6000);  
        fundsWallet.transfer(msg.value);
      } else if(yirmibirmay < now && yirmisekizmay > now) {
        require(balances[fundsWallet] >= msg.value * 4615);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 4615;
        balances[msg.sender] = balances[msg.sender] + msg.value * 4615;
        Transfer(fundsWallet, msg.sender, msg.value * 4615);  
        fundsWallet.transfer(msg.value);
      }else if(yirmisekizmay < now && dorthaziran > now) {
        require(balances[fundsWallet] >= msg.value * 3750);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 3750;
        balances[msg.sender] = balances[msg.sender] + msg.value * 3750;
        Transfer(fundsWallet, msg.sender, msg.value * 3750);  
        fundsWallet.transfer(msg.value);
      }else if(dorthaziran < now && onbirhaziran > now) {
        require(balances[fundsWallet] >= msg.value * 3157);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 3157;
        balances[msg.sender] = balances[msg.sender] + msg.value * 3157;
        Transfer(fundsWallet, msg.sender, msg.value * 3157);  
        fundsWallet.transfer(msg.value);
      }else if(onbirhaziran < now && onsekizhaziran > now) {
        require(balances[fundsWallet] >= msg.value * 2727);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 2727;
        balances[msg.sender] = balances[msg.sender] + msg.value * 2727;
        Transfer(fundsWallet, msg.sender, msg.value * 2727);  
        fundsWallet.transfer(msg.value);
      }else if(onsekizhaziran < now && yirmibeshaz > now) {
        require(balances[fundsWallet] >= msg.value * 2400);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 2400;
        balances[msg.sender] = balances[msg.sender] + msg.value * 2400;
        Transfer(fundsWallet, msg.sender, msg.value * 2400);  
        fundsWallet.transfer(msg.value);
      }
      else {
        throw;
      }
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}