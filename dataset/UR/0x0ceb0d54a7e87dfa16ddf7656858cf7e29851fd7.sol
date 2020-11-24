 

pragma solidity ^0.4.8;

contract ERC20 {
  function totalSupply() constant returns (uint);
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract ApproveAndCallReceiver {
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data);
}

contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}
contract AbstractSale {
  function saleFinalized() constant returns (bool);
}

contract SaleWallet {
   
  address public multisig;
  uint public finalBlock;
  AbstractSale public tokenSale;

   
   
   
  function SaleWallet(address _multisig, uint _finalBlock, address _tokenSale) {
    multisig = _multisig;
    finalBlock = _finalBlock;
    tokenSale = AbstractSale(_tokenSale);
  }

   
  function () public payable {}

   
  function withdraw() public {
    if (msg.sender != multisig) throw;                        
    if (block.number > finalBlock) return doWithdraw();       
    if (tokenSale.saleFinalized()) return doWithdraw();       
  }

  function doWithdraw() internal {
    if (!multisig.send(this.balance)) throw;
  }
}

contract Controller {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract ANPlaceholder is Controller {
  address public sale;
  ANT public token;

  function ANPlaceholder(address _sale, address _ant) {
    sale = _sale;
    token = ANT(_ant);
  }

  function changeController(address network) public {
    if (msg.sender != sale) throw;
    token.changeController(network);
    suicide(network);
  }

   
  function proxyPayment(address _owner) payable public returns (bool) {
    throw;
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return true;
  }
}




contract MiniMeToken is ERC20, Controlled {
    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.1';  


     
     
     
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
    ) {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (!transfersEnabled) throw;
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            if (!transfersEnabled) throw;

             
            if (allowed[_from][msg.sender] < _amount) throw;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

            
           if ((_to == 0) || (_to == address(this))) throw;

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               throw;
           }

            
           if (isContract(controller)) {
               if (!Controller(controller).onTransfer(_from, _to, _amount)) throw;
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           if (previousBalanceTo + _amount < previousBalanceTo) throw;  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        if (!transfersEnabled) throw;

         
         
         
         
        if ((_amount!=0) && (allowed[msg.sender][_spender] !=0)) throw;

         
        if (isContract(controller)) {
            if (!Controller(controller).onApprove(msg.sender, _spender, _amount))
                throw;
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
        approve(_spender, _amount);

         
         
         
         
         
         
        ApproveAndCallReceiver(_spender).receiveApproval(
           msg.sender,
           _amount,
           this,
           _extraData
        );
        return true;
    }

     
     
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) constant
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

     
     
     
    function totalSupplyAt(uint _blockNumber) constant returns(uint) {

         
         
         
         
         
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

    function min(uint a, uint b) internal returns (uint) {
      return a < b ? a : b;
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) returns(address) {
        if (_snapshotBlock > block.number) _snapshotBlock = block.number;
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
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        if (curTotalSupply + _amount < curTotalSupply) throw;  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        var previousBalanceTo = balanceOf(_owner);
        if (previousBalanceTo + _amount < previousBalanceTo) throw;  
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        if (curTotalSupply < _amount) throw;
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        var previousBalanceFrom = balanceOf(_owner);
        if (previousBalanceFrom < _amount) throw;
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
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
               Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint oldCheckPoint = checkpoints[checkpoints.length-1];
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

     
     
     
    function ()  payable {
        if (isContract(controller)) {
            if (! Controller(controller).proxyPayment.value(msg.value)(msg.sender))
                throw;
        } else {
            throw;
        }
    }


 
 
 
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) returns (MiniMeToken) {
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


 

 
 
 

 
 
 

contract MiniMeIrrevocableVestedToken is MiniMeToken, SafeMath {
   
  struct TokenGrant {
    address granter;
    uint256 value;
    uint64 cliff;
    uint64 vesting;
    uint64 start;
  }

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint64 start, uint64 cliff, uint64 vesting);

  mapping (address => TokenGrant[]) public grants;

  mapping (address => bool) canCreateGrants;
  address vestingWhitelister;

  modifier canTransfer(address _sender, uint _value) {
    if (_value > spendableBalanceOf(_sender)) throw;
    _;
  }

  modifier onlyVestingWhitelister {
    if (msg.sender != vestingWhitelister) throw;
    _;
  }

  function MiniMeIrrevocableVestedToken (
      address _tokenFactory,
      address _parentToken,
      uint _parentSnapShotBlock,
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol,
      bool _transfersEnabled
  ) MiniMeToken(_tokenFactory, _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {
    vestingWhitelister = msg.sender;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

   
  function transfer(address _to, uint _value)
           canTransfer(msg.sender, _value)
           public
           returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value)
           canTransfer(_from, _value)
           public
           returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function spendableBalanceOf(address _holder) constant public returns (uint) {
    return transferableTokens(_holder, uint64(now));
  }

  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting) public {

     
    if (_cliff < _start) throw;
    if (_vesting < _start) throw;
    if (_vesting < _cliff) throw;

    if (!canCreateGrants[msg.sender]) throw;
    if (tokenGrantsCount(_to) > 20) throw;    

    TokenGrant memory grant = TokenGrant(msg.sender, _value, _cliff, _vesting, _start);
    grants[_to].push(grant);

    if (!transfer(_to, _value)) throw;

    NewTokenGrant(msg.sender, _to, _value, _cliff, _vesting, _start);
  }

  function setCanCreateGrants(address _addr, bool _allowed)
           onlyVestingWhitelister public {
    doSetCanCreateGrants(_addr, _allowed);
  }

  function doSetCanCreateGrants(address _addr, bool _allowed)
           internal {
    canCreateGrants[_addr] = _allowed;
  }

  function changeVestingWhitelister(address _newWhitelister) onlyVestingWhitelister public {
    doSetCanCreateGrants(vestingWhitelister, false);
    vestingWhitelister = _newWhitelister;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

   
  function revokeTokenGrant(address _holder, uint _grantId) public {
    throw;
  }

   
  function tokenGrantsCount(address _holder) constant public returns (uint index) {
    return grants[_holder].length;
  }

  function tokenGrant(address _holder, uint _grantId) constant public returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting) {
    TokenGrant grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;

    vested = vestedTokens(grant, uint64(now));
  }

  function vestedTokens(TokenGrant grant, uint64 time) internal constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal constant returns (uint256)
    {

     
    if (time < cliff) return 0;
    if (time >= vesting) return tokens;

     
     
     

     
    uint256 vestedTokens = safeDiv(
                                  safeMul(
                                    tokens,
                                    safeSub(time, start)
                                    ),
                                  safeSub(vesting, start)
                                  );

    return vestedTokens;
  }

  function nonVestedTokens(TokenGrant grant, uint64 time) internal constant returns (uint256) {
     
     
    return safeSub(grant.value, vestedTokens(grant, time));
  }

   
   
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = tokenGrantsCount(holder);
    for (uint256 i = 0; i < grantIndex; i++) {
      date = max64(grants[holder][i].vesting, date);
    }
    return date;
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return balanceOf(holder);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = safeAdd(nonVested, nonVestedTokens(grants[holder][i], time));
    }

     
    return safeSub(balanceOf(holder), nonVested);
  }
}

 

contract ANT is MiniMeIrrevocableVestedToken {
   
  function ANT(
    address _tokenFactory
  ) MiniMeIrrevocableVestedToken(
    _tokenFactory,
    0x0,                     
    0,                       
    "Aragon Network Token",  
    18,                      
    "ANT",                   
    true                     
    ) {}
}



 

contract AragonTokenSale is Controller, SafeMath {
    uint public initialBlock;              
    uint public finalBlock;                
    uint public initialPrice;              
    uint public finalPrice;                
    uint8 public priceStages;              
    address public aragonDevMultisig;      
    address public communityMultisig;      
    bytes32 public capCommitment;

    uint public totalCollected = 0;                
    bool public saleStopped = false;               
    bool public saleFinalized = false;             

    mapping (address => bool) public activated;    

    ANT public token;                              
    ANPlaceholder public networkPlaceholder;       
    SaleWallet public saleWallet;                     

    uint constant public dust = 1 finney;          
    uint public hardCap = 1000000 ether;           

    event NewPresaleAllocation(address indexed holder, uint256 antAmount);
    event NewBuyer(address indexed holder, uint256 antAmount, uint256 etherAmount);
    event CapRevealed(uint value, uint secret, address revealer);
 
 
 
 
 
 
 
 
 
 

  function AragonTokenSale (
      uint _initialBlock,
      uint _finalBlock,
      address _aragonDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages,
      bytes32 _capCommitment
  )
      non_zero_address(_aragonDevMultisig)
      non_zero_address(_communityMultisig)
  {
      if (_initialBlock < getBlockNumber()) throw;
      if (_initialBlock >= _finalBlock) throw;
      if (_initialPrice <= _finalPrice) throw;
      if (_priceStages < 2) throw;
      if (_priceStages > _initialPrice - _finalPrice) throw;
      if (uint(_capCommitment) == 0) throw;

       
      initialBlock = _initialBlock;
      finalBlock = _finalBlock;
      aragonDevMultisig = _aragonDevMultisig;
      communityMultisig = _communityMultisig;
      initialPrice = _initialPrice;
      finalPrice = _finalPrice;
      priceStages = _priceStages;
      capCommitment = _capCommitment;
  }

   
   
   
   

  function setANT(address _token, address _networkPlaceholder, address _saleWallet)
           non_zero_address(_token)
           non_zero_address(_networkPlaceholder)
           non_zero_address(_saleWallet)
           only(aragonDevMultisig)
           public {

     
    if (activated[this]) throw;

    token = ANT(_token);
    networkPlaceholder = ANPlaceholder(_networkPlaceholder);
    saleWallet = SaleWallet(_saleWallet);

    if (token.controller() != address(this)) throw;  
    if (networkPlaceholder.sale() != address(this)) throw;  
    if (networkPlaceholder.token() != address(token)) throw;  
    if (token.totalSupply() > 0) throw;  
    if (saleWallet.finalBlock() != finalBlock) throw;  
    if (saleWallet.multisig() != aragonDevMultisig) throw;  
    if (saleWallet.tokenSale() != address(this)) throw;  

     
    doActivateSale(this);
  }

   
   
   
  function activateSale()
           public {
    doActivateSale(msg.sender);
  }

  function doActivateSale(address _entity)
    non_zero_address(token)                
    only_before_sale
    private {
    activated[_entity] = true;
  }

   
   
  function isActivated() constant public returns (bool) {
    return activated[this] && activated[aragonDevMultisig] && activated[communityMultisig];
  }

   
   
   
   
  function getPrice(uint _blockNumber) constant public returns (uint256) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;

    return priceForStage(stageForBlock(_blockNumber));
  }

   
   
   
  function stageForBlock(uint _blockNumber) constant internal returns (uint8) {
    uint blockN = safeSub(_blockNumber, initialBlock);
    uint totalBlocks = safeSub(finalBlock, initialBlock);

    return uint8(safeDiv(safeMul(priceStages, blockN), totalBlocks));
  }

   
   
   
   
  function priceForStage(uint8 _stage) constant internal returns (uint256) {
    if (_stage >= priceStages) return 0;
    uint priceDifference = safeSub(initialPrice, finalPrice);
    uint stageDelta = safeDiv(priceDifference, uint(priceStages - 1));
    return safeSub(initialPrice, safeMul(uint256(_stage), stageDelta));
  }

   
   
   
   
   
  function allocatePresaleTokens(address _receiver, uint _amount, uint64 cliffDate, uint64 vestingDate)
           only_before_sale_activation
           only_before_sale
           non_zero_address(_receiver)
           only(aragonDevMultisig)
           public {

    if (_amount > 10 ** 24) throw;  

    if (!token.generateTokens(address(this), _amount)) throw;
    token.grantVestedTokens(_receiver, _amount, uint64(now), cliffDate, vestingDate);

    NewPresaleAllocation(_receiver, _amount);
  }

 
 
 
 

  function () public payable {
    return doPayment(msg.sender);
  }

 
 
 

 
 
 

  function proxyPayment(address _owner) payable public returns (bool) {
    doPayment(_owner);
    return true;
  }

 
 
 
 
 
 
  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
     
     
    return _from == address(this);
  }

 
 
 
 
 
 
  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
     
    return false;
  }

 
 
 

  function doPayment(address _owner)
           only_during_sale_period
           only_sale_not_stopped
           only_sale_activated
           non_zero_address(_owner)
           minimum_value(dust)
           internal {

    if (totalCollected + msg.value > hardCap) throw;  

    uint256 boughtTokens = safeMul(msg.value, getPrice(getBlockNumber()));  

    if (!saleWallet.send(msg.value)) throw;  
    if (!token.generateTokens(_owner, boughtTokens)) throw;  

    totalCollected = safeAdd(totalCollected, msg.value);  

    NewBuyer(_owner, boughtTokens, msg.value);
  }

   
   
  function emergencyStopSale()
           only_sale_activated
           only_sale_not_stopped
           only(aragonDevMultisig)
           public {

    saleStopped = true;
  }

   
   
  function restartSale()
           only_during_sale_period
           only_sale_stopped
           only(aragonDevMultisig)
           public {

    saleStopped = false;
  }

  function revealCap(uint256 _cap, uint256 _cap_secure)
           only_during_sale_period
           only_sale_activated
           verify_cap(_cap, _cap_secure)
           public {

    if (_cap > hardCap) throw;

    hardCap = _cap;
    CapRevealed(_cap, _cap_secure, msg.sender);

    if (totalCollected + dust >= hardCap) {
      doFinalizeSale(_cap, _cap_secure);
    }
  }

   
   
  function finalizeSale(uint256 _cap, uint256 _cap_secure)
           only_after_sale
           only(aragonDevMultisig)
           public {

    doFinalizeSale(_cap, _cap_secure);
  }

  function doFinalizeSale(uint256 _cap, uint256 _cap_secure)
           verify_cap(_cap, _cap_secure)
           internal {
     
     
     

     
    uint256 aragonTokens = token.totalSupply() * 3 / 7;
    if (!token.generateTokens(aragonDevMultisig, aragonTokens)) throw;
    token.changeController(networkPlaceholder);  

    saleFinalized = true;   
    saleStopped = true;
  }

   
   
  function deployNetwork(address networkAddress)
           only_finalized_sale
           non_zero_address(networkAddress)
           only(communityMultisig)
           public {

    networkPlaceholder.changeController(networkAddress);
  }

  function setAragonDevMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(aragonDevMultisig)
           public {

    aragonDevMultisig = _newMultisig;
  }

  function setCommunityMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(communityMultisig)
           public {

    communityMultisig = _newMultisig;
  }

  function getBlockNumber() constant internal returns (uint) {
    return block.number;
  }

  function computeCap(uint256 _cap, uint256 _cap_secure) constant public returns (bytes32) {
    return sha3(_cap, _cap_secure);
  }

  function isValidCap(uint256 _cap, uint256 _cap_secure) constant public returns (bool) {
    return computeCap(_cap, _cap_secure) == capCommitment;
  }

  modifier only(address x) {
    if (msg.sender != x) throw;
    _;
  }

  modifier verify_cap(uint256 _cap, uint256 _cap_secure) {
    if (!isValidCap(_cap, _cap_secure)) throw;
    _;
  }

  modifier only_before_sale {
    if (getBlockNumber() >= initialBlock) throw;
    _;
  }

  modifier only_during_sale_period {
    if (getBlockNumber() < initialBlock) throw;
    if (getBlockNumber() >= finalBlock) throw;
    _;
  }

  modifier only_after_sale {
    if (getBlockNumber() < finalBlock) throw;
    _;
  }

  modifier only_sale_stopped {
    if (!saleStopped) throw;
    _;
  }

  modifier only_sale_not_stopped {
    if (saleStopped) throw;
    _;
  }

  modifier only_before_sale_activation {
    if (isActivated()) throw;
    _;
  }

  modifier only_sale_activated {
    if (!isActivated()) throw;
    _;
  }

  modifier only_finalized_sale {
    if (getBlockNumber() < finalBlock) throw;
    if (!saleFinalized) throw;
    _;
  }

  modifier non_zero_address(address x) {
    if (x == 0) throw;
    _;
  }

  modifier minimum_value(uint256 x) {
    if (msg.value < x) throw;
    _;
  }
}