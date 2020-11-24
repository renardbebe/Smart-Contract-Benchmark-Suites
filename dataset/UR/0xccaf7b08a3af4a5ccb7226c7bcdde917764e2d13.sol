 

 
 
 

pragma solidity ^0.4.16;

 
contract Owned {
   
  address public owner = msg.sender;

   
  event NewOwner(address indexed old, address indexed current);

   
  modifier only_owner { require (msg.sender == owner); _; }

   
  function setOwner(address _new) public only_owner { NewOwner(owner, _new); owner = _new; }
}

 
 
 
 
contract Delegated is Owned {
   
  mapping (address => bool) delegates;

   
  modifier only_delegate { require (msg.sender == owner || delegates[msg.sender]); _; }

   
  function delegate(address who) public constant returns (bool) { return who == owner || delegates[who]; }

   
  function addDelegate(address _new) public only_owner { delegates[_new] = true; }
  function removeDelegate(address _old) public only_owner { delete delegates[_old]; }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract FeeRegistrar is Delegated {
   
  address public treasury;
  uint public fee;

   
  mapping(address => address[]) s_paid;


   
  event Paid (address who, address payer);


   

   
   
   
   
   
  function FeeRegistrar (address _treasury, uint _fee) public {
    owner = msg.sender;
    treasury = _treasury;
    fee = _fee;
  }


   

   
   
   
   
   
   
  function payer (address who) public constant returns (uint count, address[] origins) {
    address[] memory m_origins = s_paid[who];

    return (m_origins.length, m_origins);
  }

   
   
   
  function paid (address who) public constant returns (bool) {
    return s_paid[who].length > 0;
  }


   

   
   
   
   
   
   
   
   
   
   
   
   
  function pay (address who) external payable {
     
    require(who != 0x0);
     
    require(msg.value == fee);
     
    require(s_paid[who].length < 10);

    s_paid[who].push(msg.sender);

     
    Paid(who, msg.sender);

     
    treasury.transfer(msg.value);
  }


   

   
   
   
   
   
  function inject (address who, address origin) external only_owner {
     
    s_paid[who].push(origin);
     
    Paid(who, origin);
  }

   
   
   
   
   
   
  function revoke (address who, address origin) payable external only_delegate {
     
     
    require(msg.value == fee);
    bool found;

     
     
     
     
    for (uint i = 0; i < s_paid[who].length; i++) {
      if (s_paid[who][i] != origin) {
        continue;
      }

       
      found = true;

      uint last = s_paid[who].length - 1;

       
       
      s_paid[who][i] = s_paid[who][last];

       
      delete s_paid[who][last];
      s_paid[who].length -= 1;

      break;
    }

     
    require(found);

     
    origin.transfer(msg.value);
  }

   
   
   
   
  function setTreasury (address _treasury) external only_owner {
    treasury = _treasury;
  }
}