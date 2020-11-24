 

pragma solidity ^0.4.21;

 

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

 

 

 
 
 
 
 
 
 



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           uint previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           uint previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 

contract DTXToken is MiniMeToken {

  function DTXToken(address _tokenFactory) public MiniMeToken (
    _tokenFactory,
    0x0,                     
    0,                       
    "DaTa eXchange Token",  
    18,                      
    "DTX",                  
    true                    
    )
  {}

}

 

 
contract ERC20Token {
   
   
  function totalSupply() constant public returns (uint256 balance);

   
   
  function balanceOf(address _owner) constant public returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
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

 

contract TokenSale is TokenController, Controlled {

  using SafeMath for uint256;

   
  uint256 public startPresaleTime;
  uint256 public endPresaleTime;
  uint256 public startDayOneTime;
  uint256 public endDayOneTime;
  uint256 public startTime;
  uint256 public endTime;

   
  uint256 constant public TOKENS_PER_ETHER_EARLYSALE = 6400;
  uint256 constant public TOKENS_PER_ETHER_PRESALE = 6000;
  uint256 constant public TOKENS_PER_ETHER_DAY_ONE = 4400;
  uint256 constant public TOKENS_PER_ETHER = 4000;

   
  uint256 constant public MAX_TOKENS = 225000000 * 10**18;

   
  uint256 constant public HARD_CAP = 108000000 * 10**18;

   
  uint256 public lockedTokens;

   
  uint256 public totalIssued;

   
  uint256 public totalVested;

   
  uint256 public totalIssuedEarlySale;

   
  DTXToken public tokenContract;

   
  address public vaultAddress;

   
  bool public paused;

   
  bool public finalized;

   
  bool public transferable;

   
  mapping(address => Vesting) vestedAllowances;

  struct Vesting {
    uint256 amount;
    uint256 cliff;
  }

   
  function TokenSale(
    uint256 _startPresaleTime,
    uint256 _endPresaleTime,
    uint256 _startDayOneTime,
    uint256 _endDayOneTime,
    uint256 _startTime,
    uint256 _endTime,
    address _vaultAddress,
    address _tokenAddress
  ) public {
     
    require(_startPresaleTime > now);
    require(_endPresaleTime > now);
    require(_startDayOneTime > now);
    require(_endDayOneTime > now);
    require(_startTime > now);
    require(_endTime > now);
     
    require(_endPresaleTime >= _startPresaleTime);
    require(_endDayOneTime >= _startDayOneTime);
    require(_endTime >= _startTime);
     
    require(_startTime >= _endDayOneTime);
    require(_startDayOneTime >= _endPresaleTime);
     
    startPresaleTime = _startPresaleTime;
    endPresaleTime = _endPresaleTime;
    startDayOneTime = _startDayOneTime;
    endDayOneTime = _endDayOneTime;
    startTime = _startTime;
    endTime = _endTime;
     
    require(_vaultAddress != 0x0);
    vaultAddress = _vaultAddress;
     
    require(_tokenAddress != 0x0);
    tokenContract = DTXToken(_tokenAddress);
     
    lockedTokens = MAX_TOKENS.div(100).mul(30);
     
    paused = false;
    finalized = false;
    transferable = false;
  }

   
   
   
   
  function () public payable notPaused {
    doPayment(msg.sender);
  }

   
   
  function proxyPayment(address _owner) public payable notPaused returns(bool success) {
    return doPayment(_owner);
  }

   
   
  function onTransfer(address _from, address  , uint  ) public returns(bool success) {
    if ( _from == controller || _from == address(this) ) {
      return true;
    }
    return transferable;
  }

   
   
  function onApprove(address _owner, address  , uint  ) public returns(bool success) {
    if ( _owner == controller || _owner == address(this) ) {
      return true;
    }
    return transferable;
  }

   
  function makeTransferable() public onlyController {
    transferable = true;
  }

   
  function updateDates(
    uint256 _startPresaleTime,
    uint256 _endPresaleTime,
    uint256 _startDayOneTime,
    uint256 _endDayOneTime,
    uint256 _startTime,
    uint256 _endTime) public onlyController {
    startPresaleTime = _startPresaleTime;
    endPresaleTime = _endPresaleTime;
    startDayOneTime = _startDayOneTime;
    endDayOneTime = _endDayOneTime;
    startTime = _startTime;
    endTime = _endTime;
  }

   
  function handleEarlySaleBuyers(address[] _recipients, uint256[] _ethAmounts) public onlyController {
     
    require(!finalized);
     
    for (uint256 i = 0; i < _recipients.length; i++) {
       
      uint256 tokensToIssue = TOKENS_PER_ETHER_EARLYSALE.mul(_ethAmounts[i]);
       
      totalIssuedEarlySale = totalIssuedEarlySale.add(tokensToIssue);
       
      require(tokenContract.generateTokens(_recipients[i], tokensToIssue));
    }
  }

   
  function handleExternalBuyers(
    address[] _recipients,
    uint256[] _free,
    uint256[] _locked,
    uint256[] _cliffs
  ) public onlyController {
     
    require(!finalized);
     
    for (uint256 i = 0; i < _recipients.length; i++) {
       
      totalIssued = totalIssued.add(_free[i]);
       
      require(tokenContract.generateTokens(_recipients[i], _free[i]));
       
      vestedAllowances[_recipients[i]] = Vesting(_locked[i], _cliffs[i]);
      totalVested.add(_locked[i]);
      require(lockedTokens.add(totalVested.add(totalIssued.add(totalIssuedEarlySale))) <= MAX_TOKENS);
    }
  }

   
   
   
  function doPayment(address _owner) internal returns(bool success) {
     
    require(msg.value > 0);

     
    require(tokenContract.controller() == address(this));

     
    bool isPresale = startPresaleTime <= now && endPresaleTime >= now;
    bool isDayOne = startDayOneTime <= now && endDayOneTime >= now;
    bool isSale = startTime <= now && endTime >= now;

     
    require(isPresale || isDayOne || isSale);

     
    if (isPresale) {
      require(msg.value >= 10 ether);
    }

     
    uint256 tokensPerEther = TOKENS_PER_ETHER;
    if (isPresale) {
      tokensPerEther = TOKENS_PER_ETHER_PRESALE;
    }
    if (isDayOne) {
      tokensPerEther = TOKENS_PER_ETHER_DAY_ONE;
    }

     
    uint256 tokensToIssue = tokensPerEther.mul(msg.value);

     
    require(totalIssued.add(tokensToIssue) <= HARD_CAP);
    require(tokensToIssue.add(lockedTokens.add(totalVested.add(totalIssued.add(totalIssuedEarlySale)))) <= MAX_TOKENS);

     
    totalIssued = totalIssued.add(tokensToIssue);

     
    vaultAddress.transfer(msg.value);

     
    require(tokenContract.generateTokens(_owner, tokensToIssue));

    return true;
  }

   
  function changeTokenController(address _newController) public onlyController {
    tokenContract.changeController(_newController);
  }

   
   
   
  function finalizeSale() public onlyController {
     
    require(now > endTime || totalIssued >= HARD_CAP);

     
    require(!finalized);

    vestedAllowances[vaultAddress] = Vesting(lockedTokens, now + 3 years);

     
    uint256 leftoverTokens = MAX_TOKENS.sub(lockedTokens).sub(totalIssued).sub(totalIssuedEarlySale).sub(totalVested);

     
    require(tokenContract.generateTokens(vaultAddress, leftoverTokens));
    require(tokenContract.generateTokens(address(this), lockedTokens.add(totalVested)));

    finalized = true;
  }

  function claimLockedTokens(address _owner) public {
    require(vestedAllowances[_owner].cliff > 0 && vestedAllowances[_owner].amount > 0);
    require(now >= vestedAllowances[_owner].cliff);
    uint256 amount = vestedAllowances[_owner].amount;
    vestedAllowances[_owner].amount = 0;
    require(tokenContract.transfer(_owner, amount));
  }

   
  function pauseContribution() public onlyController {
    paused = true;
  }

   
  function resumeContribution() public onlyController {
    paused = false;
  }

  modifier notPaused() {
    require(!paused);
    _;
  }
}