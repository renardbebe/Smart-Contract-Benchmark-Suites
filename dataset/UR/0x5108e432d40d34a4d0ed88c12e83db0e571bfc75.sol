 

pragma solidity ^0.4.4;


 
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

contract CrystalReignShard is StandardToken {  
  using SafeMath for uint;
     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0';
    uint256 public unitsOneEthCanBuy;
    uint256 public preSalePrice;
    uint256 public totalEthInWei;
    address public fundsWallet;
    address public dropWallet = 0x88d38F6cb2aF250Ab8f1FA24851ba312b0c48675;
    address public compWallet = 0xCf794896c1788F799dc141015b3aAae0721e7c27;
    address public marketingWallet = 0x49cc71a3a8c7D14Bf6a868717C81b248506402D8;
    uint256 public bonusETH = 0;
    uint256 public bonusCRS = 0;
    uint public start = 1519477200;
    uint public mintCount = 0;

     
     
    function CrystalReignShard() {
        balances[msg.sender] = 16400000000000000000000000;                
        balances[dropWallet] = 16400000000000000000000000;
        balances[compWallet] = 16400000000000000000000000;
        balances[marketingWallet] = 80000000000000000000000;
        totalSupply = 50000000;                         
        name = "Crystal Reign Shard";                                    
        decimals = 18;                                                
        symbol = "CRS";                                              
        unitsOneEthCanBuy = 1000;                                       
        preSalePrice = 1300;
        fundsWallet = msg.sender;                                     
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (now < 1524571200) {
          amount = msg.value * preSalePrice;
        }
        if (balances[fundsWallet] < amount) {
            msg.sender.transfer(msg.value);
            return;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function mint(){
      if (now >= start + (5 years * mintCount) && msg.sender == fundsWallet) {
        balances[dropWallet] += 16400000;
        mintCount++;
        totalSupply += 16400000;
      }
    }

      function tileDrop(address[] winners) returns(bool success){
      if(msg.sender == fundsWallet){
        uint256 amount = 1000000000000000000000;
        for(uint winList = 0; winList < winners.length; winList++){
          winners[winList].transfer(bonusETH.div(64));
          balances[winners[winList]] = balances[winners[winList]] + amount;
          bonusETH -= bonusETH.div(64);
            if (balances[dropWallet] >= amount) {
            balances[dropWallet] = balances[dropWallet] - amount;
            balances[winners[winList]] = balances[winners[winList]] + bonusCRS.div(64);
            bonusCRS -= bonusCRS.div(64);
              }

          Transfer(dropWallet, msg.sender, amount);  
        }

        balances[fundsWallet] = balances[fundsWallet] + bonusCRS;
        bonusCRS = 0;

        Transfer(fundsWallet, msg.sender, bonusETH);  
         
        fundsWallet.transfer(bonusETH);
        bonusETH = 0;
        return true;
        }
        else{
        return false;
        }
        }

        function purchaseETH() payable returns(uint t){ 
          bonusETH +=  (msg.value.div(5)).mul(4);


          Transfer(fundsWallet, msg.sender, (msg.value.div(5)));  
          fundsWallet.transfer(msg.value.div(5));
          return block.timestamp;
        }

        function purchaseCRS(uint256 amount) public returns(bool success){ 
          if(balances[msg.sender] >= amount){
            balances[fundsWallet] = balances[fundsWallet] + amount.div(5);
            bonusCRS += (amount.div(5)).mul(4);
            balances[msg.sender] = balances[msg.sender] - amount;
          }


           

          return true;
          }





}