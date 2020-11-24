 

pragma solidity ^0.4.15;

contract TokenFactoryInterface {

    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        string _tokenSymbol
      ) public returns (ProofToken newToken);
}

contract Controllable {
  address public controller;


   
  function Controllable() public {
    controller = msg.sender;
  }

   
  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

   
  function transferControl(address newController) public onlyController {
    if (newController != address(0)) {
      controller = newController;
    }
  }

}

contract ApproveAndCallReceiver {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
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
}

contract ProofToken is Controllable {

  using SafeMath for uint256;
  ProofTokenInterface public parentToken;
  TokenFactoryInterface public tokenFactory;

  string public name;
  string public symbol;
  string public version;
  uint8 public decimals;

  struct Checkpoint {
    uint128 fromBlock;
    uint128 value;
  }

  uint256 public parentSnapShotBlock;
  uint256 public creationBlock;
  bool public transfersEnabled;
  bool public masterTransfersEnabled;

  mapping(address => Checkpoint[]) balances;
  mapping (address => mapping (address => uint)) allowed;

  Checkpoint[] totalSupplyHistory;

  bool public mintingFinished = false;
  bool public presaleBalancesLocked = false;

  uint256 public constant TOTAL_PRESALE_TOKENS = 112386712924725508802400;
  address public constant MASTER_WALLET = 0x740C588C5556e523981115e587892be0961853B8;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed cloneToken);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);




  function ProofToken(
    address _tokenFactory,
    address _parentToken,
    uint256 _parentSnapShotBlock,
    string _tokenName,
    string _tokenSymbol
    ) public {
      tokenFactory = TokenFactoryInterface(_tokenFactory);
      parentToken = ProofTokenInterface(_parentToken);
      parentSnapShotBlock = _parentSnapShotBlock;
      name = _tokenName;
      symbol = _tokenSymbol;
      decimals = 18;
      transfersEnabled = false;
      masterTransfersEnabled = false;
      creationBlock = block.number;
      version = '0.1';
  }

  function() public payable {
    revert();
  }


   
  function totalSupply() public constant returns (uint) {
    return totalSupplyAt(block.number);
  }

   
  function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
     
     
     
     
     
    if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
        if (address(parentToken) != 0) {
            return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
        } else {
            return 0;
        }

     
    } else {
        return getValueAt(totalSupplyHistory, _blockNumber);
    }
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balanceOfAt(_owner, block.number);
  }

   
  function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {
     
     
     
     
     
    if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
        if (address(parentToken) != 0) {
            return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
        } else {
             
            return 0;
        }

     
    } else {
        return getValueAt(balances[_owner], _blockNumber);
    }
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    return doTransfer(msg.sender, _to, _amount);
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(allowed[_from][msg.sender] >= _amount);
    allowed[_from][msg.sender] -= _amount;
    return doTransfer(_from, _to, _amount);
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    require(transfersEnabled);

     
     
     
     
    require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
    approve(_spender, _amount);

    ApproveAndCallReceiver(_spender).receiveApproval(
        msg.sender,
        _amount,
        this,
        _extraData
    );

    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


  function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {

    if (msg.sender != MASTER_WALLET) {
      require(transfersEnabled);
    } else {
      require(masterTransfersEnabled);
    }

    require(transfersEnabled);
    require(_amount > 0);
    require(parentSnapShotBlock < block.number);
    require((_to != 0) && (_to != address(this)));

     
     
    var previousBalanceFrom = balanceOfAt(_from, block.number);
    require(previousBalanceFrom >= _amount);

     
     
    updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

     
     
    var previousBalanceTo = balanceOfAt(_to, block.number);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    updateValueAtNow(balances[_to], previousBalanceTo + _amount);

     
    Transfer(_from, _to, _amount);
    return true;
  }


  function mint(address _owner, uint _amount) public onlyController canMint returns (bool) {
    uint curTotalSupply = totalSupply();
    uint previousBalanceTo = balanceOf(_owner);

    require(curTotalSupply + _amount >= curTotalSupply);  
    require(previousBalanceTo + _amount >= previousBalanceTo);  

    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
    Transfer(0, _owner, _amount);
    return true;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }


   
  function importPresaleBalances(address[] _addresses, uint256[] _balances) public onlyController returns (bool) {
    require(presaleBalancesLocked == false);

    for (uint256 i = 0; i < _addresses.length; i++) {
      updateValueAtNow(balances[_addresses[i]], _balances[i]);
      Transfer(0, _addresses[i], _balances[i]);
    }

    updateValueAtNow(totalSupplyHistory, TOTAL_PRESALE_TOKENS);
    return true;
  }

   
  function lockPresaleBalances() public onlyController returns (bool) {
    presaleBalancesLocked = true;
    return true;
  }

   
  function finishMinting() public onlyController returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

   
  function enableTransfers(bool _value) public onlyController {
    transfersEnabled = _value;
  }

  function enableMasterTransfers(bool _value) public onlyController {
    masterTransfersEnabled = _value;
  }


  function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {

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

  function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
  ) internal
  {
      if ((checkpoints.length == 0) || (checkpoints[checkpoints.length-1].fromBlock < block.number)) {
              Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
              newCheckPoint.fromBlock = uint128(block.number);
              newCheckPoint.value = uint128(_value);
          } else {
              Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
              oldCheckPoint.value = uint128(_value);
          }
  }

   
  function min(uint a, uint b) internal constant returns (uint) {
      return a < b ? a : b;
  }

   
  function createCloneToken(
        uint _snapshotBlock,
        string _cloneTokenName,
        string _cloneTokenSymbol
    ) public returns(address) {

      if (_snapshotBlock == 0) {
        _snapshotBlock = block.number;
      }

      if (_snapshotBlock > block.number) {
        _snapshotBlock = block.number;
      }

      ProofToken cloneToken = tokenFactory.createCloneToken(
          this,
          _snapshotBlock,
          _cloneTokenName,
          _cloneTokenSymbol
        );


      cloneToken.transferControl(msg.sender);

       
      NewCloneToken(address(cloneToken));
      return address(cloneToken);
    }

}

contract ControllerInterface {

    function proxyPayment(address _owner) public payable returns(bool);
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}

contract ProofTokenInterface is Controllable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public constant returns (uint);
  function totalSupplyAt(uint _blockNumber) public constant returns(uint);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  function approve(address _spender, uint256 _amount) public returns (bool success);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function mint(address _owner, uint _amount) public returns (bool);
  function importPresaleBalances(address[] _addresses, uint256[] _balances, address _presaleAddress) public returns (bool);
  function lockPresaleBalances() public returns (bool);
  function finishMinting() public returns (bool);
  function enableTransfers(bool _value) public;
  function enableMasterTransfers(bool _value) public;
  function createCloneToken(uint _snapshotBlock, string _cloneTokenName, string _cloneTokenSymbol) public returns (address);

}