 

pragma solidity ^0.4.18;

 

 

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

 

contract Distribution is Controlled, TokenController {

   
  struct Transaction {
    uint256 amount;
    bytes32 paidTxID;
  }

  MiniMeTokenI public token;

  address public reserveWallet;  

  uint256 public totalSupplyCap;  
  uint256 public totalReserve;  

  uint256 public finalizedBlock;

   
  mapping (address => Transaction[]) allTransactions;

   
   
   
   
   
  function Distribution(
    address _token,
    address _reserveWallet,
    uint256 _totalSupplyCap,
    uint256 _totalReserve
  ) public onlyController
  {
     
    assert(address(token) == 0x0);

    token = MiniMeTokenI(_token);
    reserveWallet = _reserveWallet;

    require(_totalReserve < _totalSupplyCap);
    totalSupplyCap = _totalSupplyCap;
    totalReserve = _totalReserve;

    assert(token.totalSupply() == 0);
    assert(token.decimals() == 18);  
  }

  function distributionCap() public constant returns (uint256) {
    return totalSupplyCap - totalReserve;
  }

   
  function finalize() public onlyController {
    assert(token.totalSupply() >= distributionCap());

     
    doMint(reserveWallet, totalReserve);

    finalizedBlock = getBlockNumber();
    token.finalize();  

     
    token.changeController(controller);

    Finalized();
  }

 
 
 

  function proxyMintTokens(
    address _th,
    uint256 _amount,
    bytes32 _paidTxID
  ) public onlyController returns (bool)
  {
    require(_th != 0x0);

    require(_amount + token.totalSupply() <= distributionCap());

    doMint(_th, _amount);
    addTransaction(
      allTransactions[_th],
      _amount,
      _paidTxID);

    Purchase(
      _th,
      _amount,
      _paidTxID);

    return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
    return false;
  }

  function onApprove(address, address, uint256) public returns (bool) {
    return false;
  }

   
   
   

   
   
   
   
  function claimTokens(address _token) public onlyController {
    if (token.controller() == address(this)) {
      token.claimTokens(_token);
    }
    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20Token otherToken = ERC20Token(_token);
    uint256 balance = otherToken.balanceOf(this);
    otherToken.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

   
   
   

   
  function totalTransactionCount(address _owner) public constant returns(uint) {
    return allTransactions[_owner].length;
  }

   
  function getTransactionAtIndex(address _owner, uint index) public constant returns(
    uint256 _amount,
    bytes32 _paidTxID
  ) {
    _amount = allTransactions[_owner][index].amount;
    _paidTxID = allTransactions[_owner][index].paidTxID;
  }

   
   
   
   
  function addTransaction(
    Transaction[] storage transactions,
    uint _amount,
    bytes32 _paidTxID
    ) internal
  {
    Transaction storage newTx = transactions[transactions.length++];
    newTx.amount = _amount;
    newTx.paidTxID = _paidTxID;
  }

  function doMint(address _th, uint256 _amount) internal {
    assert(token.mintTokens(_th, _amount));
  }

 
 
 

   
  function getBlockNumber() internal constant returns (uint256) { return block.number; }


 
 
 
  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event Purchase(
    address indexed _owner,
    uint256 _amount,
    bytes32 _paidTxID
  );
  event Finalized();
}