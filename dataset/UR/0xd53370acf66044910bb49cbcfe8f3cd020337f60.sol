 

pragma solidity ^0.4.18;

 

 

contract ApproveAndCallFallBack {
  function receiveApproval(
    address _from,
    uint256 _amount,
    address _token,
    bytes _data) public;
}

 

contract Controlled {
   
   
  modifier onlyController {
    require(msg.sender == controller);
    _;
  }

  address public controller;

  function Controlled() public { controller = msg.sender; }

   
   
  function changeController(address _newController) public onlyController {
    controller = _newController;
  }
}

 

 
 
contract Burnable is Controlled {
  address public burner;

   
   
   
  modifier onlyControllerOrBurner(address target) {
    assert(msg.sender == controller || (msg.sender == burner && msg.sender == target));
    _;
  }

  modifier onlyBurner {
    assert(msg.sender == burner);
    _;
  }

   
  function Burnable() public { burner = msg.sender;}

   
   
  function changeBurner(address _newBurner) public onlyBurner {
    burner = _newBurner;
  }
}

 

 
 
contract ERC20Token {
   
  function totalSupply() public view returns (uint256 balance);

   
   
  function balanceOf(address _owner) public view returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
 
contract MiniMeTokenI is ERC20Token, Burnable {

  string public name;                 
  uint8 public decimals;              
  string public symbol;               
  string public version = "MMT_0.1";  

 
 
 

   
   
   
   
   
   
   
  function approveAndCall(
    address _spender,
    uint256 _amount,
    bytes _extraData) public returns (bool success);

 
 
 

   
   
   
   
  function balanceOfAt(
    address _owner,
    uint _blockNumber) public constant returns (uint);

   
   
   
  function totalSupplyAt(uint _blockNumber) public constant returns(uint);

 
 
 

   
   
   
   
  function mintTokens(address _owner, uint _amount) public returns (bool);


   
   
   
   
  function destroyTokens(address _owner, uint _amount) public returns (bool);

 
 
 
  function finalize() public;

 
 
 

   
   
   
   
  function claimTokens(address _token) public;

 
 
 

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}

 

 
contract TokenController {
     
     
     
  function proxyMintTokens(
    address _owner, 
    uint _amount,
    bytes32 _paidTxID) public returns(bool);

     
     
     
     
     
     
  function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
  function onApprove(address _owner, address _spender, uint _amount) public
    returns(bool);
}

 

 
 
 
 
contract MiniMeToken is MiniMeTokenI {

   
   
   
  struct Checkpoint {

     
    uint128 fromBlock;

     
    uint128 value;
  }

   
   
  MiniMeToken public parentToken;

   
   
  uint public parentSnapShotBlock;

   
  uint public creationBlock;

   
   
   
  mapping (address => Checkpoint[]) balances;

   
  mapping (address => mapping (address => uint256)) allowed;

   
  Checkpoint[] totalSupplyHistory;


  bool public finalized;

  modifier notFinalized() {
    require(!finalized);
    _;
  }

 
 
 

   
   
   
   
   
   
   
   
   
  function MiniMeToken(
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol
  ) public
  {
    name = _tokenName;                                  
    decimals = _decimalUnits;                           
    symbol = _tokenSymbol;                              
    parentToken = MiniMeToken(_parentToken);
    parentSnapShotBlock = _parentSnapShotBlock;
    creationBlock = block.number;
  }

 
 
 

   
   
   
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    return doTransfer(msg.sender, _to, _amount);
  }

   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
     
    require(allowed[_from][msg.sender] >= _amount);
    allowed[_from][msg.sender] -= _amount;

    return doTransfer(_from, _to, _amount);
  }

   
   
   
   
   
   
  function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
    if (_amount == 0) {
      return true;
    }

    require(parentSnapShotBlock < block.number);

     
    require((_to != 0) && (_to != address(this)));

     
     
    var previousBalanceFrom = balanceOfAt(_from, block.number);
    if (previousBalanceFrom < _amount) {
      return false;
    }

     
     
    if (isContract(controller)) {
      require(TokenController(controller).onTransfer(_from, _to, _amount));
    }

     
     
    updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

     
     
    var previousBalanceTo = balanceOfAt(_to, block.number);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    updateValueAtNow(balances[_to], previousBalanceTo + _amount);

     
    Transfer(_from, _to, _amount);

    return true;
  }

   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balanceOfAt(_owner, block.number);
  }

   
   
   
   
   
   
  function approve(address _spender, uint256 _amount) public returns (bool success) {

     
     
     
     
    require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

     
    if (isContract(controller)) {
      require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
    }

    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
   
   
   
   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
   
   
   
   
   
   
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
    require(approve(_spender, _amount));

    ApproveAndCallFallBack(_spender).receiveApproval(
      msg.sender,
      _amount,
      this,
      _extraData
    );

    return true;
  }

   
   
  function totalSupply() public view returns (uint) {
    return totalSupplyAt(block.number);
  }

 
 
 

   
   
   
   
  function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {

     
     
     
     
     
    if ((balances[_owner].length == 0) ||
        (balances[_owner][0].fromBlock > _blockNumber)) {
      if (address(parentToken) != 0) {
        return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
      } else {
         
        return 0;
      }

         
     } else {
      return getValueAt(balances[_owner], _blockNumber);
     }
  }

   
   
   
  function totalSupplyAt(uint _blockNumber) public view returns(uint) {

     
     
     
     
     
    if ((totalSupplyHistory.length == 0) ||
        (totalSupplyHistory[0].fromBlock > _blockNumber)) {
      if (address(parentToken) != 0) {
        return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
      } else {
        return 0;
      }

         
     } else {
      return getValueAt(totalSupplyHistory, _blockNumber);
     }
  }

 
 
 

   
   
   
   
  function mintTokens(address _owner, uint _amount) public onlyController notFinalized returns (bool) {
    uint curTotalSupply = totalSupply();
    require(curTotalSupply + _amount >= curTotalSupply);  
    uint previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
    Transfer(0, _owner, _amount);
    return true;
  }

   
   
   
   
  function destroyTokens(address _owner, uint _amount) public onlyControllerOrBurner(_owner) returns (bool) {
    uint curTotalSupply = totalSupply();
    require(curTotalSupply >= _amount);
    uint previousBalanceFrom = balanceOf(_owner);
    require(previousBalanceFrom >= _amount);
    updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
    updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
    Transfer(_owner, 0, _amount);
    return true;
  }

 
 
 

   
   
   
   
  function getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view returns (uint) {
    if (checkpoints.length == 0)
      return 0;

     
    if (_block >= checkpoints[checkpoints.length-1].fromBlock)
      return checkpoints[checkpoints.length-1].value;
    if (_block < checkpoints[0].fromBlock)
      return 0;

     
    uint min = 0;
    uint max = checkpoints.length-1;
    while (max > min) {
      uint mid = (max + min + 1) / 2;
      if (checkpoints[mid].fromBlock<=_block) {
        min = mid;
      } else {
        max = mid-1;
      }
    }
    return checkpoints[min].value;
  }

   
   
   
   
  function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
    if ((checkpoints.length == 0) ||
      (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
      Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
      newCheckPoint.fromBlock = uint128(block.number);
      newCheckPoint.value = uint128(_value);
    } else {
      Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
      oldCheckPoint.value = uint128(_value);
    }
  }

   
   
   
  function isContract(address _addr) internal view returns(bool) {
    uint size;
    if (_addr == 0)
      return false;
    assembly {
      size := extcodesize(_addr)
    }
    return size>0;
  }

   
  function min(uint a, uint b) pure internal returns (uint) {
    return a < b ? a : b;
  }

 
 
 

   
   
   
   
  function claimTokens(address _token) public onlyController {
    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20Token otherToken = ERC20Token(_token);
    uint balance = otherToken.balanceOf(this);
    otherToken.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

  function finalize() public onlyController notFinalized {
    finalized = true;
  }

 
 
 

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
  event Transfer(address indexed _from, address indexed _to, uint256 _amount);
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _amount
  );

}

 

contract SEN is MiniMeToken {
  function SEN() public MiniMeToken(
    0x0,                 
    0,                   
    "Consensus Token",   
    18,                  
    "SEN"               
  )
  {}
}