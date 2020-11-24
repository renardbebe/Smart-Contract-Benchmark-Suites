 

pragma solidity ^0.4.19;

pragma solidity ^0.4.19;

 
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

 

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


 

 

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

 

contract Controlled {
    address public controller;

    function Controlled() {
         controller = msg.sender;
    }

     
     
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

 

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) returns(bool);
}

 

 
 
 
 
 
 
 

 
 
 
contract MiniMeToken is Controlled {

    string public name;                
    uint8 public decimals;              
    string public symbol;                
    string public version = "MMT_0.1";  


     
     
     
    struct    Checkpoint {

         
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
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

             if (_amount == 0) {
             Transfer(_from, _to, _amount);     
             return;
             }

             require(parentSnapShotBlock < block.number);

              
             require((_to != 0) && (_to != address(this)));

              
              
             uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
             require(previousBalanceFrom >= _amount);

              
             if (isContract(controller)) {
                 require(TokenController(controller).onTransfer(_from, _to, _amount));
             }

              
              
             updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

              
              
             uint256 previousBalanceTo = balanceOfAt(_to, block.number);
             require(previousBalanceTo + _amount >= previousBalanceTo);  
             updateValueAtNow(balances[_to], previousBalanceTo + _amount);

              
             Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
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
    ) public view returns (uint256 remaining) {
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

     
     
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public view
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

     
     
     
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

         
         
         
         
         
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
        ) returns(address) {
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
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint256 _amount
    ) onlyController returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint256 previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) internal view returns (uint) {
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
    ) internal    {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
                 Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
                 newCheckPoint.fromBlock =    uint128(block.number);
                 newCheckPoint.value = uint128(_value);
             } else {
                 Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
                 oldCheckPoint.value = uint128(_value);
             }
    }

     
     
     
    function isContract(address _addr) internal view returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

     
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function ()    payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) onlyController {
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

 

 
 
 

 
 
 

contract MiniMeIrrevocableVestedToken is MiniMeToken {

    using SafeMath for uint256;

    uint256 MAX_GRANTS_PER_ADDRESS = 20;
     
     
    struct TokenGrant {
    address granter;     
    uint256 value;          
    uint64 cliff;
    uint64 vesting;
    uint64 start;         
    bool revokable;
    bool burnsOnRevoke;     
    }  

    mapping (address => TokenGrant[]) public grants;

    event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint64 start, uint64 cliff, uint64 vesting, uint256 grantId);

    mapping (address => bool) canCreateGrants;
    address vestingWhitelister;

    modifier canTransfer(address _sender, uint _value) {
    require(_value <= spendableBalanceOf(_sender));
    _;
    }

    modifier onlyVestingWhitelister {
    require(msg.sender == vestingWhitelister);
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
    ) public MiniMeToken(_tokenFactory, _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {
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
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
    ) public {

     
    require(_cliff >= _start && _vesting >= _cliff);
    require(canCreateGrants[msg.sender]);

    require(tokenGrantsCount(_to) < MAX_GRANTS_PER_ADDRESS);     

    uint256 count = grants[_to].push(
               TokenGrant(
                   _revokable ? msg.sender : 0,  
                   _value,
                   _cliff,
                   _vesting,
                   _start,
                   _revokable,
                   _burnsOnRevoke
               )
               );

    transfer(_to, _value);

    NewTokenGrant(msg.sender, _to, _value, _cliff, _vesting, _start, count - 1);
    }

    function setCanCreateGrants(address _addr, bool _allowed) onlyVestingWhitelister public {
    doSetCanCreateGrants(_addr, _allowed);
    }

    function doSetCanCreateGrants(address _addr, bool _allowed) internal {
    canCreateGrants[_addr] = _allowed;
    }

    function changeVestingWhitelister(address _newWhitelister) onlyVestingWhitelister public {
    doSetCanCreateGrants(vestingWhitelister, false);
    vestingWhitelister = _newWhitelister;
    doSetCanCreateGrants(vestingWhitelister, true);
    }

     
    function revokeTokenGrant(address _holder, uint256 _grantId) public {
    TokenGrant storage grant = grants[_holder][_grantId];

    require(grant.revokable);
    require(grant.granter == msg.sender);  

    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

    uint256 nonVested = nonVestedTokens(grant, uint64(now));

     
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

    var previousBalanceReceiver = balanceOfAt(receiver, block.number);

     
    updateValueAtNow(balances[receiver], previousBalanceReceiver + nonVested);

    var previousBalance_holder = balanceOfAt(_holder, block.number);

     
    updateValueAtNow(balances[_holder], previousBalance_holder - nonVested);

    Transfer(_holder, receiver, nonVested);
    }

     
    function transferableTokens(address holder, uint64 time) public view returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return balanceOf(holder);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
        nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

     
     
    return Math.min256(vestedTransferable, balanceOf(holder));
    }

     
    function tokenGrantsCount(address _holder) public view returns (uint256 index) {
    return grants[_holder].length;
    }

     
    function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal view returns (uint256)
    {
         
        if (time < cliff) return 0;
        if (time >= vesting) return tokens;

         
         
         

         
        uint256 vestedTokens = SafeMath.div(
                                    SafeMath.mul(
                                       tokens,
                                       SafeMath.sub(time, start)
                                       ),
                                    SafeMath.sub(vesting, start)
                                    );

        return vestedTokens;
    }

     
    function tokenGrant(address _holder, uint256 _grantId) public view returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant storage grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;
    revokable = grant.revokable;
    burnsOnRevoke = grant.burnsOnRevoke;

    vested = vestedTokens(grant, uint64(now));
    }

     
    function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return calculateVestedTokens(
        grant.value,
        uint256(time),
        uint256(grant.start),
        uint256(grant.cliff),
        uint256(grant.vesting)
    );
    }

     
    function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
     
     
    return grant.value.sub(vestedTokens(grant, time));
    }

     
    function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
        date = Math.max64(grants[holder][i].vesting, date);
    }
    }

}

 

contract MiniMeIrrVesDivToken is MiniMeIrrevocableVestedToken {

    event DividendDeposited(address indexed _depositor, uint256 _blockNumber, uint256 _timestamp, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);
    event DividendClaimed(address indexed _claimer, uint256 _dividendIndex, uint256 _claim);
    event DividendRecycled(address indexed _recycler, uint256 _blockNumber, uint256 _timestamp, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);

    uint256 public RECYCLE_TIME = 1 years;

    function MiniMeIrrVesDivToken (
         address _tokenFactory,
         address _parentToken,
         uint _parentSnapShotBlock,
         string _tokenName,
         uint8 _decimalUnits,
         string _tokenSymbol,
         bool _transfersEnabled
    ) public MiniMeIrrevocableVestedToken(_tokenFactory, _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {}

    struct Dividend {
    uint256 blockNumber;
    uint256 timestamp;
    uint256 amount;
    uint256 claimedAmount;
    uint256 totalSupply;
    bool recycled;
    mapping (address => bool) claimed;
    }

    Dividend[] public dividends;

    mapping (address => uint256) dividendsClaimed;

    modifier validDividendIndex(uint256 _dividendIndex) {
    require(_dividendIndex < dividends.length);
    _;
    }

    function depositDividend() public payable
    onlyController
    {
    uint256 currentSupply = super.totalSupplyAt(block.number);
    uint256 dividendIndex = dividends.length;
    uint256 blockNumber = SafeMath.sub(block.number, 1);
    dividends.push(
         Dividend(
         blockNumber,
         getNow(),
         msg.value,
         0,
         currentSupply,
         false
         )
    );
    DividendDeposited(msg.sender, blockNumber, getNow(), msg.value, currentSupply, dividendIndex);
    }

    function claimDividend(uint256 _dividendIndex) public
    validDividendIndex(_dividendIndex)
    {
    Dividend storage dividend = dividends[_dividendIndex];
    require(dividend.claimed[msg.sender] == false);
    require(dividend.recycled == false);
    uint256 balance = super.balanceOfAt(msg.sender, dividend.blockNumber);
    uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);
    dividend.claimed[msg.sender] = true;
    dividend.claimedAmount = SafeMath.add(dividend.claimedAmount, claim);
    if (claim > 0) {
         msg.sender.transfer(claim);
         DividendClaimed(msg.sender, _dividendIndex, claim);
    }
    }

    function claimDividendAll() public {
    require(dividendsClaimed[msg.sender] < dividends.length);
    for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
         if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
         dividendsClaimed[msg.sender] = SafeMath.add(i, 1);
         claimDividend(i);
         }
    }
    }

    function recycleDividend(uint256 _dividendIndex) public
    onlyController
    validDividendIndex(_dividendIndex)
    {
    Dividend storage dividend = dividends[_dividendIndex];
    require(dividend.recycled == false);
    require(dividend.timestamp < SafeMath.sub(getNow(), RECYCLE_TIME));
    dividends[_dividendIndex].recycled = true;
    uint256 currentSupply = super.totalSupplyAt(block.number);
    uint256 remainingAmount = SafeMath.sub(dividend.amount, dividend.claimedAmount);
    uint256 dividendIndex = dividends.length;
    uint256 blockNumber = SafeMath.sub(block.number, 1);
    dividends.push(
         Dividend(
         blockNumber,
         getNow(),
         remainingAmount,
         0,
         currentSupply,
         false
         )
    );
    DividendRecycled(msg.sender, blockNumber, getNow(), remainingAmount, currentSupply, dividendIndex);
    }

    function getNow() internal constant returns (uint256) {
    return now;
    }
}

 

contract ESCBCoin is MiniMeIrrVesDivToken {
   
  function ESCBCoin (
    address _tokenFactory
  ) public MiniMeIrrVesDivToken(
    _tokenFactory,
    0x0,             
    0,               
    "ESCB token",    
    18,              
    "ESCB",          
    true             
    ) {}
}