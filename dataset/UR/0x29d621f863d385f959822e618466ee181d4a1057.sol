 

pragma solidity ^0.4.11;

 

contract ERC20Token {
   
   
  function totalSupply() constant returns (uint256 balance);

   
   
  function balanceOf(address _owner) constant returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Controlled {
   
   
  modifier onlyController { if (msg.sender != controller) throw; _; }

  address public controller;

  function Controlled() { controller = msg.sender;}

   
   
  function changeController(address _newController) onlyController {
    controller = _newController;
  }
}

contract Burnable is Controlled {
   
   
   
  modifier onlyControllerOrBurner(address target) {
    assert(msg.sender == controller || (msg.sender == burner && msg.sender == target));
    _;
  }

  modifier onlyBurner {
    assert(msg.sender == burner);
    _;
  }
  address public burner;

  function Burnable() { burner = msg.sender;}

   
   
  function changeBurner(address _newBurner) onlyBurner {
    burner = _newBurner;
  }
}

contract MiniMeTokenI is ERC20Token, Burnable {

      string public name;                 
      uint8 public decimals;              
      string public symbol;               
      string public version = 'MMT_0.1';  

 
 
 


     
     
     
     
     
     
     
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) returns (bool success);

 
 
 

     
     
     
     
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) constant returns (uint);

     
     
     
    function totalSupplyAt(uint _blockNumber) constant returns(uint);

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) returns(address);

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) returns (bool);


     
     
     
     
    function destroyTokens(address _owner, uint _amount) returns (bool);

 
 
 

     
     
    function enableTransfers(bool _transfersEnabled);

 
 
 

     
     
     
     
    function claimTokens(address _token);

 
 
 

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}

contract ReferalsTokenHolder is Controlled {
  MiniMeTokenI public msp;
  mapping (address => bool) been_spread;

  function ReferalsTokenHolder(address _msp) {
    msp = MiniMeTokenI(_msp);
  }

  function spread(address[] _addresses, uint256[] _amounts) public onlyController {
    require(_addresses.length == _amounts.length);

    for (uint256 i = 0; i < _addresses.length; i++) {
      address addr = _addresses[i];
      if (!been_spread[addr]) {
        uint256 amount = _amounts[i];
        assert(msp.transfer(addr, amount));
        been_spread[addr] = true;
      }
    }
  }

 
 
 

   
   
   
   
  function claimTokens(address _token) onlyController {
    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20Token token = ERC20Token(_token);
    uint balance = token.balanceOf(this);
    token.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}