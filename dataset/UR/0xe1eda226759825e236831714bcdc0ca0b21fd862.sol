 

pragma solidity 0.4.16;

contract PullPayInterface {
  function asyncSend(address _dest) public payable;
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data);
}

contract ControllerInterface {


   
  bool public paused;
  address public nutzAddr;

   
  function babzBalanceOf(address _owner) constant returns (uint256);
  function activeSupply() constant returns (uint256);
  function burnPool() constant returns (uint256);
  function powerPool() constant returns (uint256);
  function totalSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);

  function approve(address _owner, address _spender, uint256 _amountBabz) public;
  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public;
  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public;

   
  function floor() constant returns (uint256);
  function ceiling() constant returns (uint256);

  function purchase(address _sender, uint256 _value, uint256 _price) public returns (uint256);
  function sell(address _from, uint256 _price, uint256 _amountBabz);

   
  function powerBalanceOf(address _owner) constant returns (uint256);
  function outstandingPower() constant returns (uint256);
  function authorizedPower() constant returns (uint256);
  function powerTotalSupply() constant returns (uint256);

  function powerUp(address _sender, address _from, uint256 _amountBabz) public;
  function downTick(address _owner, uint256 _now) public;
  function createDownRequest(address _owner, uint256 _amountPower) public;
  function downs(address _owner) constant public returns(uint256, uint256, uint256);
  function downtime() constant returns (uint256);
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() constant returns (uint256);
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC223Basic is ERC20Basic {
    function transfer(address to, uint value, bytes data) returns (bool);
}

 
contract ERC20 is ERC223Basic {
   
  function activeSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);
  function transferFrom(address _from, address _to, uint _value) returns (bool);
  function approve(address _spender, uint256 _value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Nutz is Ownable, ERC20 {

  event Sell(address indexed seller, uint256 value);

  string public name = "Acebusters Nutz";
   
   
   
   
   
   
  string public symbol = "NTZ";
  uint256 public decimals = 12;

   
  function balanceOf(address _owner) constant returns (uint) {
    return ControllerInterface(owner).babzBalanceOf(_owner);
  }

  function totalSupply() constant returns (uint256) {
    return ControllerInterface(owner).totalSupply();
  }

  function activeSupply() constant returns (uint256) {
    return ControllerInterface(owner).activeSupply();
  }

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256) {
    return ControllerInterface(owner).allowance(_owner, _spender);
  }

   
   
  function floor() constant returns (uint256) {
    return ControllerInterface(owner).floor();
  }

   
   
  function ceiling() constant returns (uint256) {
    return ControllerInterface(owner).ceiling();
  }

  function powerPool() constant returns (uint256) {
    return ControllerInterface(owner).powerPool();
  }


  function _checkDestination(address _from, address _to, uint256 _value, bytes _data) internal {
     
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(_to)
    }
    if(codeLength>0) {
      ERC223ReceivingContract untrustedReceiver = ERC223ReceivingContract(_to);
       
      untrustedReceiver.tokenFallback(_from, _value, _data);
    }
  }



   
   
   

  function powerDown(address powerAddr, address _holder, uint256 _amountBabz) public onlyOwner {
    bytes memory empty;
    _checkDestination(powerAddr, _holder, _amountBabz, empty);
     
    Transfer(powerAddr, _holder, _amountBabz);
  }


  function asyncSend(address _pullAddr, address _dest, uint256 _amountWei) public onlyOwner {
    assert(_amountWei <= this.balance);
    PullPayInterface(_pullAddr).asyncSend.value(_amountWei)(_dest);
  }


   
   
   

  function approve(address _spender, uint256 _amountBabz) public {
    ControllerInterface(owner).approve(msg.sender, _spender, _amountBabz);
    Approval(msg.sender, _spender, _amountBabz);
  }

  function transfer(address _to, uint256 _amountBabz, bytes _data) public returns (bool) {
    ControllerInterface(owner).transfer(msg.sender, _to, _amountBabz, _data);
    Transfer(msg.sender, _to, _amountBabz);
    _checkDestination(msg.sender, _to, _amountBabz, _data);
    return true;
  }

  function transfer(address _to, uint256 _amountBabz) public returns (bool) {
    bytes memory empty;
    return transfer(_to, _amountBabz, empty);
  }

  function transData(address _to, uint256 _amountBabz, bytes _data) public returns (bool) {
    return transfer(_to, _amountBabz, _data);
  }

  function transferFrom(address _from, address _to, uint256 _amountBabz, bytes _data) public returns (bool) {
    ControllerInterface(owner).transferFrom(msg.sender, _from, _to, _amountBabz, _data);
    Transfer(_from, _to, _amountBabz);
    _checkDestination(_from, _to, _amountBabz, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amountBabz) public returns (bool) {
    bytes memory empty;
    return transferFrom(_from, _to, _amountBabz, empty);
  }

  function () public payable {
    uint256 price = ControllerInterface(owner).ceiling();
    purchase(price);
    require(msg.value > 0);
  }

  function purchase(uint256 _price) public payable {
    require(msg.value > 0);
    uint256 amountBabz = ControllerInterface(owner).purchase(msg.sender, msg.value, _price);
    Transfer(owner, msg.sender, amountBabz);
    bytes memory empty;
    _checkDestination(address(this), msg.sender, amountBabz, empty);
  }

  function sell(uint256 _price, uint256 _amountBabz) public {
    require(_amountBabz != 0);
    ControllerInterface(owner).sell(msg.sender, _price, _amountBabz);
    Sell(msg.sender, _amountBabz);
  }

  function powerUp(uint256 _amountBabz) public {
    Transfer(msg.sender, owner, _amountBabz);
    ControllerInterface(owner).powerUp(msg.sender, msg.sender, _amountBabz);
  }

}