 

pragma solidity ^0.4.13;

 

 
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
    require(assertion);
  }
}

 
contract Controller {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

 

 
 
 

contract Controlled {
     
     
    modifier onlyController{ require(msg.sender==controller); _; }


    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}



contract ApproveAndCallReceiver {
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data);
}

 
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
        require (transfersEnabled);
     
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require (transfersEnabled);

             

             
            assert (allowed[_from][msg.sender]>=_amount);

             
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {
           if (_amount == 0) {
               return true;
           }

            
           require((_to!=0)&&(_to!=address(this)));

            

            
            

           var previousBalanceFrom = balanceOfAt(_from, block.number);
           assert(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               assert(Controller(controller).onTransfer(_from,_to,_amount));

           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           
           var previousBalanceTo = balanceOfAt(_to, block.number);
           assert(previousBalanceTo+_amount>=previousBalanceTo); 
           
            
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        require(transfersEnabled);

         
         
         
         

        require((_amount==0)||(allowed[msg.sender][_spender]==0));

         
        if (isContract(controller)) {
            assert(Controller(controller).onApprove(msg.sender,_spender,_amount));

             
             
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
        assert(curTotalSupply+_amount>=curTotalSupply);
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        var previousBalanceTo = balanceOf(_owner);
        assert(previousBalanceTo+_amount>=previousBalanceTo);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        assert(curTotalSupply >= _amount);
        
         

        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        var previousBalanceFrom = balanceOf(_owner);
        assert(previousBalanceFrom >=_amount);

         
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

     
     
     
    function ()  payable {
        require(isContract(controller));
        assert(Controller(controller).proxyPayment.value(msg.value)(msg.sender));
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

  uint256 MAX_GRANTS_PER_ADDRESS = 20;

   
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
    require(_value<=spendableBalanceOf(_sender));
    _;
  }

  modifier onlyVestingWhitelister {
    require(msg.sender==vestingWhitelister);
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

     

    require(_cliff >= _start && _vesting >= _cliff);
    
    require(tokenGrantsCount(_to)<=MAX_GRANTS_PER_ADDRESS);  

    assert(canCreateGrants[msg.sender]);


    TokenGrant memory grant = TokenGrant(msg.sender, _value, _cliff, _vesting, _start);
    grants[_to].push(grant);

    assert(transfer(_to,_value));

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

  function tokenGrantsCount(address _holder) constant public returns (uint index) {
    return grants[_holder].length;
  }

  function tokenGrant(address _holder, uint _grantId) constant public returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting) {
    TokenGrant storage grant = grants[_holder][_grantId];

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


contract GNR is MiniMeIrrevocableVestedToken {
   
  function GNR(
    address _tokenFactory
  ) MiniMeIrrevocableVestedToken(
    _tokenFactory,
    0x0,                     
    0,                       
    "Genaro Network Token",  
    9,                      
    "GNR",                   
    true                     
    ) {}
}

 

contract GRPlaceholder is Controller {
  address public sale;
  GNR public token;

  function GRPlaceholder(address _sale, address _gnr) {
    sale = _sale;
    token = GNR(_gnr);
  }

  function changeController(address network) public {
    require(msg.sender == sale);
    token.changeController(network);
    suicide(network);
  }

   
  function proxyPayment(address) payable public returns (bool) {
    return false;
  }

  function onTransfer(address, address, uint) public returns (bool) {
    return true;
  }

  function onApprove(address, address, uint) public returns (bool) {
    return true;
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
    require(msg.sender == multisig);   
    if (block.number > finalBlock) return doWithdraw();       
    if (tokenSale.saleFinalized()) return doWithdraw();       
  }

  function doWithdraw() internal {
    require(multisig.send(this.balance));
  }
}


contract GenaroTokenSale is Controlled, Controller, SafeMath {
    uint public initialBlock;              
    uint public finalBlock;                
    uint public price;                     

    address public genaroDevMultisig;      
    bytes32 public capCommitment;

    uint public totalCollected = 0;                
    bool public saleStopped = false;               
    bool public saleFinalized = false;             

    mapping (address => bool) public activated;    

    mapping (address => bool) public whitelist;    

    GNR public token;                              
    GRPlaceholder public networkPlaceholder;       
    SaleWallet public saleWallet;                  

    uint constant public dust = 1 ether;          
    uint constant public maxPerPersion = 100 ether;    

    uint public hardCap = 2888 ether;           

    event NewPresaleAllocation(address indexed holder, uint256 gnrAmount);
    event NewBuyer(address indexed holder, uint256 gnrAmount, uint256 etherAmount);
    event CapRevealed(uint value, uint secret, address revealer);

 
 
 
 
 
 

  function GenaroTokenSale (
      uint _initialBlock,
      uint _finalBlock,
      address _genaroDevMultisig,
      uint256 _price,
      bytes32 _capCommitment
  )
  {
      require(_genaroDevMultisig !=0);
      require(_initialBlock >= getBlockNumber());
      require(_initialBlock < _finalBlock);

      require(uint(_capCommitment)!=0);
      

       
      initialBlock = _initialBlock;
      finalBlock = _finalBlock;
      genaroDevMultisig = _genaroDevMultisig;
      price = _price;
      capCommitment = _capCommitment;
  }

   
   
   
   

  function setGNR(address _token, address _networkPlaceholder, address _saleWallet)
           only(genaroDevMultisig)
           public {

    require(_token != 0);
    require(_networkPlaceholder != 0);
    require(_saleWallet != 0);

     
    assert(!activated[this]);

    token = GNR(_token);
    networkPlaceholder = GRPlaceholder(_networkPlaceholder);
    saleWallet = SaleWallet(_saleWallet);
    
    assert(token.controller() == address(this));  
    assert(networkPlaceholder.sale() ==address(this));  
    assert(networkPlaceholder.token() == address(token));  
    assert(saleWallet.finalBlock() == finalBlock);  
    assert(saleWallet.multisig() == genaroDevMultisig);   
    assert(saleWallet.tokenSale() == address(this));   

     
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
    return activated[this] && activated[genaroDevMultisig];
  }

   
   
   
   

  function getPrice(address _owner, uint _blockNumber) constant public returns (uint256) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;

    return (price);
  }

   
   
   
   
   

  function allocatePresaleTokens(address _receiver, uint _amount, uint64 cliffDate, uint64 vestingDate)
           only_before_sale_activation
           only_before_sale
           non_zero_address(_receiver)
           only(genaroDevMultisig)
           public {

    require(_amount<=6.3*(10 ** 15));  

    assert(token.generateTokens(address(this),_amount));
    
     
    token.grantVestedTokens(_receiver, _amount, uint64(now), cliffDate, vestingDate);

    NewPresaleAllocation(_receiver, _amount);
  }

 
 
 
 

  function () public payable {
    return doPayment(msg.sender);
  }

 
 
 

  function addToWhiteList(address _owner) 
           only(controller)
           public{
              whitelist[_owner]=true;
           }

  function removeFromWhiteList(address _owner)
           only(controller)
           public{
              whitelist[_owner]=false;
           }

   
  function isWhitelisted(address _owner) public constant returns (bool) {
    return whitelist[_owner];
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
           maximum_value(maxPerPersion)
           internal {

    assert(totalCollected+msg.value <= hardCap);  

    uint256 boughtTokens = safeDiv(safeMul(msg.value, getPrice(_owner,getBlockNumber())),10**9);  

    assert(saleWallet.send(msg.value));   
    assert(token.generateTokens(_owner,boughtTokens)); 
    
    totalCollected = safeAdd(totalCollected, msg.value);  

    NewBuyer(_owner, boughtTokens, msg.value);
  }

   
   
  function emergencyStopSale()
           only_sale_activated
           only_sale_not_stopped
           only(genaroDevMultisig)
           public {

    saleStopped = true;
  }

   
   
  function restartSale()
           only_during_sale_period
           only_sale_stopped
           only(genaroDevMultisig)
           public {

    saleStopped = false;
  }

  function revealCap(uint256 _cap, uint256 _cap_secure)
           only_during_sale_period
           only_sale_activated
           verify_cap(_cap, _cap_secure)
           public {

    require(_cap <= hardCap);

    hardCap = _cap;
    CapRevealed(_cap, _cap_secure, msg.sender);

    if (totalCollected + dust >= hardCap) {
      doFinalizeSale();
    }
  }

   
   
  function finalizeSale()
           only(genaroDevMultisig)
           public {

    require(getBlockNumber() >= finalBlock  ||  totalCollected >= hardCap);
    doFinalizeSale();
  }

  function doFinalizeSale()
           internal {
     
     
     

     

    token.changeController(genaroDevMultisig);
    saleFinalized = true;   
    saleStopped = true;
  }

   
   
  function deployNetwork(address networkAddress)
           only_finalized_sale
           non_zero_address(networkAddress)
           only(genaroDevMultisig)
           public {

    networkPlaceholder.changeController(networkAddress);
  }

  function setGenaroDevMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(genaroDevMultisig)
           public {

    genaroDevMultisig = _newMultisig;
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
    require(msg.sender == x);
    _;
  }

  modifier verify_cap(uint256 _cap, uint256 _cap_secure) {
    require(isValidCap(_cap,_cap_secure));
    _;
  }

  modifier only_before_sale {
    require(getBlockNumber() < initialBlock);
    _;
  }

  modifier only_during_sale_period {
    require(getBlockNumber() >= initialBlock);
    require(getBlockNumber() < finalBlock);
    _;
  }

  modifier only_after_sale {
    require(getBlockNumber() >= finalBlock);
    _;
  }

  modifier only_sale_stopped {
    require(saleStopped);
    _;
  }

  modifier only_sale_not_stopped {
    require(!saleStopped);
    _;
  }

  modifier only_before_sale_activation {
    require(!isActivated());
    _;
  }

  modifier only_sale_activated {
    require(isActivated());
    _;
  }

  modifier only_finalized_sale {
    require(getBlockNumber() >= finalBlock);
    require(saleFinalized);
    _;
  }

  modifier non_zero_address(address x) {
    require(x != 0);
    _;
  }

  modifier maximum_value(uint256 x) {
    require(msg.value <= x);
    _;
  }

  modifier minimum_value(uint256 x) {
    require(msg.value >= x);
    _;
  }
}