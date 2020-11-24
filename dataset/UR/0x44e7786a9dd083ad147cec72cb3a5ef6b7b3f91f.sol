 

pragma solidity ^0.4.8;
 
contract owned {

  address public owner;
 
  function owned() { owner = msg.sender; }

  modifier onlyOwner {
    if (msg.sender != owner) { throw; }
    _;
  }

  function changeOwner( address newowner ) onlyOwner {
    owner = newowner;
  }
}

contract OX_TOKEN is owned {
 
  string public constant name = "OX";
  string public constant symbol = "OX"; 
 
  event Receipt( address indexed _to,
                 uint _oxen,
                 uint _paymentwei ); 

  event Transfer( address indexed _from,
                  address indexed _to,
                  uint _ox );

  uint public starttime;
  bool public expanded;
  uint public inCirculation;
  mapping( address => uint ) public oxen;

  function OX_TOKEN() {
    starttime = 0;
    expanded = false;
    inCirculation = 0;
  }

  function closedown() onlyOwner {
    selfdestruct( owner );
  }

  function() payable {}

  function withdraw( uint amount ) onlyOwner {
    if (amount <= this.balance)
      bool result = owner.send( amount );
  }

  function startSale() onlyOwner {
    if (starttime != 0) return;

    starttime = now;  

     
    inCirculation = 200000000;
    oxen[OX_ORG] = inCirculation;
    Transfer( OX_ORG, OX_ORG, inCirculation );
  }

   
   
   
   

  function expand() {
    if (expanded || saleOn()) { return; }

    expanded = true;

     
    uint ext = inCirculation * 1428571428 / 10**9 - inCirculation;
    oxen[OX_ORG] += ext;
    inCirculation += ext;
    Transfer( this, OX_ORG, ext );
  }

  function buyOx() payable {

     
    if (!saleOn() || msg.value < 10**17) {
      throw;  
    }

     
     
     
     
     

    uint tobuy = (msg.value * 3 * (100 + bonus())) / 10**17;

    if (inCirculation + tobuy > 700000000) {
      throw;  
    }

    inCirculation += tobuy;
    oxen[msg.sender] += tobuy;
    Receipt( msg.sender, tobuy, msg.value );
  }

  function transfer( address to, uint ox ) {
    if ( ox > oxen[msg.sender] || saleOn() ) {
      return;
    }

    if (!expanded) { expand(); }

    oxen[msg.sender] -= ox;
    oxen[to] += ox;
    Transfer( msg.sender, to, ox );
  }

  function saleOn() constant returns(bool) {
    return now - starttime < 31 days;
  }

  function bonus() constant returns(uint) {
    uint elapsed = now - starttime;

    if (elapsed < 1 days) return 25;
    if (elapsed < 1 weeks) return 20;
    if (elapsed < 2 weeks) return 15;
    if (elapsed < 3 weeks) return 10;
    if (elapsed < 4 weeks) return 5;
    return 0;
  }

  address public constant OX_ORG = 0x8f256c71a25344948777f333abd42f2b8f32be8e;
  address public constant AUTHOR = 0x8e9342eb769c4039aaf33da739fb2fc8af9afdc1;
}