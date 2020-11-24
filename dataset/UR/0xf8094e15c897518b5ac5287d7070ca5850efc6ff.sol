 

pragma solidity ^0.4.11;


library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
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

contract Ownable {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract Pausable is Ownable {
  bool public stopped;
  event onEmergencyChanged(bool isStopped);

  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }

  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }

   
  function emergencyStop() external onlyOwner {
    stopped = true;
    onEmergencyChanged(stopped);
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
    onEmergencyChanged(stopped);
  }

}

contract ERC20Basic {
  function totalSupply() constant returns (uint);
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {

  mapping(address => uint) balances;

  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool);
  function approveAndCall(address spender, uint256 value, bytes extraData) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);

  function doTransfer(address _from, address _to, uint _amount) internal returns(bool);
}

contract GrantsControlled {
    modifier onlyGrantsController { if (msg.sender != grantsController) throw; _; }

    address public grantsController;

    function GrantsControlled() { grantsController = msg.sender;}

    function changeGrantsController(address _newController) onlyGrantsController {
        grantsController = _newController;
    }
}

contract LimitedTransferToken is ERC20 {
   
  modifier canTransfer(address _sender, uint _value) {
   if (_value > transferableTokens(_sender, uint64(now))) throw;
   _;
  }

   
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) returns (bool) {
   return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) returns (bool) {
   return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    return balanceOf(holder);
  }
}

contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract MiniMeToken is ERC20, Controlled {
    using SafeMath for uint;

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

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           if (parentSnapShotBlock >= block.number) throw;

            
           if ((_to == 0) || (_to == address(this))) throw;

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               if (!TokenController(controller).onTransfer(_from, _to, _amount))
               throw;
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom.sub(_amount));

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           updateValueAtNow(balances[_to], previousBalanceTo.add(_amount));

            
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
            if (!TokenController(controller).onApprove(msg.sender, _spender, _amount))
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
        if (!approve(_spender, _amount)) throw;

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
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        updateValueAtNow(totalSupplyHistory, curTotalSupply.add(_amount));
        var previousBalanceTo = balanceOf(_owner);
        updateValueAtNow(balances[_owner], previousBalanceTo.add(_amount));
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        if (curTotalSupply < _amount) throw;
        updateValueAtNow(totalSupplyHistory, curTotalSupply.sub(_amount));
        var previousBalanceFrom = balanceOf(_owner);
        if (previousBalanceFrom < _amount) throw;
        updateValueAtNow(balances[_owner], previousBalanceFrom.sub(_amount));
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

     
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function ()  payable {
        if (isContract(controller)) {
            if (! TokenController(controller).proxyPayment.value(msg.value)(msg.sender))
                throw;
        } else {
            throw;
        }
    }

     
     
     

     
     
     
     
     
    function claimTokens(address _token, address _claimer) onlyController {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ClaimedTokens(_token, _claimer, balance);
    }


 
 
 
    event ClaimedTokens(address indexed _token, address indexed _claimer, uint _amount);
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

contract VestedToken is LimitedTransferToken, GrantsControlled {
  using SafeMath for uint;

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

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

   
  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
  ) onlyGrantsController public {

     
    if (_cliff < _start || _vesting < _cliff) {
      throw;
    }

    if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) throw;    

    uint count = grants[_to].push(
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

    NewTokenGrant(msg.sender, _to, _value, count - 1);
  }

   
  function revokeTokenGrant(address _holder, uint _grantId) public {
    TokenGrant grant = grants[_holder][_grantId];

    if (!grant.revokable) {  
      throw;
    }

    if (grant.granter != msg.sender) {  
      throw;
    }

    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

    uint256 nonVested = nonVestedTokens(grant, uint64(now));

     
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

     
     
    doTransfer(_holder, receiver, nonVested);

    Transfer(_holder, receiver, nonVested);
  }

   
    function revokeAllTokenGrants(address _holder) {
        var grandsCount = tokenGrantsCount(_holder);
        for (uint i = 0; i < grandsCount; i++) {
          revokeTokenGrant(_holder, 0);
        }
    }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return balanceOf(holder);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

     
     
    return SafeMath.min256(vestedTransferable, super.transferableTokens(holder, time));
  }

   
  function tokenGrantsCount(address _holder) constant returns (uint index) {
    return grants[_holder].length;
  }

   
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) constant returns (uint256)
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

   
  function tokenGrant(address _holder, uint _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant grant = grants[_holder][_grantId];

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
      date = SafeMath.max64(grants[holder][i].vesting, date);
    }
  }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}


contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract District0xNetworkToken is MiniMeToken, VestedToken {
    function District0xNetworkToken(address _controller, address _tokenFactory)
        MiniMeToken(
            _tokenFactory,
            0x0,                         
            0,                           
            "district0x Network Token",  
            18,                          
            "DNT",                       
            true                         
            )
    {
        changeController(_controller);
        changeGrantsController(_controller);
    }
}

contract HasNoTokens is Ownable {

  District0xNetworkToken public district0xNetworkToken;

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    throw;
  }

  function isTokenSaleToken(address tokenAddr) returns(bool);

   
  function reclaimToken(address tokenAddr) external onlyOwner {
    require(!isTokenSaleToken(tokenAddr));
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(msg.sender, balance);
  }
}


contract District0xContribution is Pausable, HasNoTokens, TokenController {
    using SafeMath for uint;

    District0xNetworkToken public district0xNetworkToken;
    address public multisigWallet;                                       
    address public founder1;                                             
    address public founder2;                                             
    address public earlySponsor;                                         
    address[] public advisers;                                           

    uint public constant FOUNDER1_STAKE = 119000000 ether;               
    uint public constant FOUNDER2_STAKE = 79000000 ether;                
    uint public constant EARLY_CONTRIBUTOR_STAKE = 5000000 ether;        
    uint public constant ADVISER_STAKE = 5000000 ether;                  
    uint public constant ADVISER_STAKE2 = 1000000 ether;                 
    uint public constant COMMUNITY_ADVISERS_STAKE = 5000000 ether;       
    uint public constant CONTRIB_PERIOD1_STAKE = 600000000 ether;        
    uint public constant CONTRIB_PERIOD2_STAKE = 140000000 ether;        
    uint public constant CONTRIB_PERIOD3_STAKE = 40000000 ether;         

    uint public minContribAmount = 0.01 ether;                           
    uint public maxGasPrice = 50000000000;                               

    uint public constant TEAM_VESTING_CLIFF = 24 weeks;                  
    uint public constant TEAM_VESTING_PERIOD = 96 weeks;                 

    uint public constant EARLY_CONTRIBUTOR_VESTING_CLIFF = 12 weeks;     
    uint public constant EARLY_CONTRIBUTOR_VESTING_PERIOD = 24 weeks;    

    bool public tokenTransfersEnabled = false;                           
                                                                         
                                                                         
    struct Contributor {
        uint amount;                         
        bool isCompensated;                  
        uint amountCompensated;              
                                             
    }

    uint public softCapAmount;                                  
    uint public afterSoftCapDuration;                           
    uint public hardCapAmount;                                  
    uint public startTime;                                      
    uint public endTime;                                        
    bool public isEnabled;                                      
    bool public softCapReached;                                 
    bool public hardCapReached;                                 
    uint public totalContributed;                               
    address[] public contributorsKeys;                          
    mapping (address => Contributor) public contributors;

    event onContribution(uint totalContributed, address indexed contributor, uint amount,
        uint contributorsCount);
    event onSoftCapReached(uint endTime);
    event onHardCapReached(uint endTime);
    event onCompensated(address indexed contributor, uint amount);

    modifier onlyMultisig() {
        require(multisigWallet == msg.sender);
        _;
    }

    function District0xContribution(
        address _multisigWallet,
        address _founder1,
        address _founder2,
        address _earlySponsor,
        address[] _advisers
    ) {
        require(_advisers.length == 5);
        multisigWallet = _multisigWallet;
        founder1 = _founder1;
        founder2 = _founder2;
        earlySponsor = _earlySponsor;
        advisers = _advisers;
    }

     
    function isContribPeriodRunning() constant returns (bool) {
        return !hardCapReached &&
               isEnabled &&
               startTime <= now &&
               endTime > now;
    }

    function contribute()
        payable
        stopInEmergency
    {
        contributeWithAddress(msg.sender);
    }

     
     
     
     
     
    function contributeWithAddress(address contributor)
        payable
        stopInEmergency
    {
        require(tx.gasprice <= maxGasPrice);
        require(msg.value >= minContribAmount);
        require(isContribPeriodRunning());

        uint contribValue = msg.value;
        uint excessContribValue = 0;

        uint oldTotalContributed = totalContributed;

        totalContributed = oldTotalContributed.add(contribValue);

        uint newTotalContributed = totalContributed;

         
        if (newTotalContributed >= softCapAmount &&
            oldTotalContributed < softCapAmount)
        {
            softCapReached = true;
            endTime = afterSoftCapDuration.add(now);
            onSoftCapReached(endTime);
        }
         
        if (newTotalContributed >= hardCapAmount &&
            oldTotalContributed < hardCapAmount)
        {
            hardCapReached = true;
            endTime = now;
            onHardCapReached(endTime);

             
            excessContribValue = newTotalContributed.sub(hardCapAmount);
            contribValue = contribValue.sub(excessContribValue);

            totalContributed = hardCapAmount;
        }

        if (contributors[contributor].amount == 0) {
            contributorsKeys.push(contributor);
        }

        contributors[contributor].amount = contributors[contributor].amount.add(contribValue);

        multisigWallet.transfer(contribValue);
        if (excessContribValue > 0) {
            msg.sender.transfer(excessContribValue);
        }
        onContribution(newTotalContributed, contributor, contribValue, contributorsKeys.length);
    }

     
     
     
     
     
     
     
    function compensateContributors(uint offset, uint limit)
        onlyOwner
    {
        require(isEnabled);
        require(endTime < now);

        uint i = offset;
        uint compensatedCount = 0;
        uint contributorsCount = contributorsKeys.length;

        uint ratio = CONTRIB_PERIOD1_STAKE
            .mul(1000000000000000000)
            .div(totalContributed);

        while (i < contributorsCount && compensatedCount < limit) {
            address contributorAddress = contributorsKeys[i];
            if (!contributors[contributorAddress].isCompensated) {
                uint amountContributed = contributors[contributorAddress].amount;
                contributors[contributorAddress].isCompensated = true;

                contributors[contributorAddress].amountCompensated =
                    amountContributed.mul(ratio).div(1000000000000000000);

                district0xNetworkToken.transfer(contributorAddress, contributors[contributorAddress].amountCompensated);
                onCompensated(contributorAddress, contributors[contributorAddress].amountCompensated);

                compensatedCount++;
            }
            i++;
        }
    }

     
     
     
     
     
     
     
     
     
    function setContribPeriod(
        uint _softCapAmount,
        uint _afterSoftCapDuration,
        uint _hardCapAmount,
        uint _startTime,
        uint _endTime
    )
        onlyOwner
    {
        require(_softCapAmount > 0);
        require(_hardCapAmount > _softCapAmount);
        require(_afterSoftCapDuration > 0);
        require(_startTime > now);
        require(_endTime > _startTime);
        require(!isEnabled);

        softCapAmount = _softCapAmount;
        afterSoftCapDuration = _afterSoftCapDuration;
        hardCapAmount = _hardCapAmount;
        startTime = _startTime;
        endTime = _endTime;

        district0xNetworkToken.revokeAllTokenGrants(founder1);
        district0xNetworkToken.revokeAllTokenGrants(founder2);
        district0xNetworkToken.revokeAllTokenGrants(earlySponsor);

        for (uint j = 0; j < advisers.length; j++) {
            district0xNetworkToken.revokeAllTokenGrants(advisers[j]);
        }

        uint64 vestingDate = uint64(startTime.add(TEAM_VESTING_PERIOD));
        uint64 cliffDate = uint64(startTime.add(TEAM_VESTING_CLIFF));
        uint64 earlyContribVestingDate = uint64(startTime.add(EARLY_CONTRIBUTOR_VESTING_PERIOD));
        uint64 earlyContribCliffDate = uint64(startTime.add(EARLY_CONTRIBUTOR_VESTING_CLIFF));
        uint64 startDate = uint64(startTime);

        district0xNetworkToken.grantVestedTokens(founder1, FOUNDER1_STAKE, startDate, cliffDate, vestingDate, true, false);
        district0xNetworkToken.grantVestedTokens(founder2, FOUNDER2_STAKE, startDate, cliffDate, vestingDate, true, false);
        district0xNetworkToken.grantVestedTokens(earlySponsor, EARLY_CONTRIBUTOR_STAKE, startDate, earlyContribCliffDate, earlyContribVestingDate, true, false);
        district0xNetworkToken.grantVestedTokens(advisers[0], ADVISER_STAKE, startDate, cliffDate, vestingDate, true, false);
        district0xNetworkToken.grantVestedTokens(advisers[1], ADVISER_STAKE, startDate, cliffDate, vestingDate, true, false);
        district0xNetworkToken.grantVestedTokens(advisers[2], ADVISER_STAKE2, startDate, cliffDate, vestingDate, true, false);
        district0xNetworkToken.grantVestedTokens(advisers[3], ADVISER_STAKE2, startDate, cliffDate, vestingDate, true, false);

         
         
        district0xNetworkToken.grantVestedTokens(advisers[4], COMMUNITY_ADVISERS_STAKE, startDate, startDate, startDate, true, false);
    }

     
     
    function enableContribPeriod()
        onlyMultisig
    {
        require(startTime > now);
        isEnabled = true;
    }

     
     
     
     
    function setMinContribAmount(uint _minContribAmount)
        onlyOwner
    {
        require(_minContribAmount > 0);
        require(startTime > now);
        minContribAmount = _minContribAmount;
    }

     
     
     
     
    function setMaxGasPrice(uint _maxGasPrice)
        onlyOwner
    {
        require(_maxGasPrice > 0);
        require(startTime > now);
        maxGasPrice = _maxGasPrice;
    }

     
     
     
     
    function setDistrict0xNetworkToken(address _district0xNetworkToken)
        onlyOwner
    {
        require(_district0xNetworkToken != 0x0);
        require(!isEnabled);
        district0xNetworkToken = District0xNetworkToken(_district0xNetworkToken);
        if (district0xNetworkToken.totalSupply() == 0) {
            district0xNetworkToken.generateTokens(this, FOUNDER1_STAKE
                .add(FOUNDER2_STAKE)
                .add(EARLY_CONTRIBUTOR_STAKE)
                .add(ADVISER_STAKE.mul(2))
                .add(ADVISER_STAKE2.mul(2))
                .add(COMMUNITY_ADVISERS_STAKE)
                .add(CONTRIB_PERIOD1_STAKE));

            district0xNetworkToken.generateTokens(multisigWallet, CONTRIB_PERIOD2_STAKE
                .add(CONTRIB_PERIOD3_STAKE));
        }
    }

     
     
    function enableDistrict0xNetworkTokenTransfers()
        onlyOwner
    {
        require(endTime < now);
        tokenTransfersEnabled = true;
    }

     
     
     
    function claimTokensFromTokenDistrict0xNetworkToken(address _token)
        onlyMultisig
    {
        district0xNetworkToken.claimTokens(_token, multisigWallet);
    }

     
    function kill(address _to) onlyMultisig external {
        suicide(_to);
    }

    function()
        payable
        stopInEmergency
    {
        contributeWithAddress(msg.sender);
    }

     
    function proxyPayment(address _owner) payable public returns (bool) {
        throw;
    }

     
    function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
        return tokenTransfersEnabled || _from == address(this) || _to == address(this);
    }

    function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
        return tokenTransfersEnabled;
    }

    function isTokenSaleToken(address tokenAddr) returns(bool) {
        return district0xNetworkToken == tokenAddr;
    }

     

     
    function getContribPeriod()
        constant
        returns (bool[3] boolValues, uint[8] uintValues)
    {
        boolValues[0] = isEnabled;
        boolValues[1] = softCapReached;
        boolValues[2] = hardCapReached;

        uintValues[0] = softCapAmount;
        uintValues[1] = afterSoftCapDuration;
        uintValues[2] = hardCapAmount;
        uintValues[3] = startTime;
        uintValues[4] = endTime;
        uintValues[5] = totalContributed;
        uintValues[6] = contributorsKeys.length;
        uintValues[7] = CONTRIB_PERIOD1_STAKE;

        return (boolValues, uintValues);
    }

     
    function getConfiguration()
        constant
        returns (bool, address, address, address, address, address[] _advisers, bool, uint)
    {
        _advisers = new address[](advisers.length);
        for (uint i = 0; i < advisers.length; i++) {
            _advisers[i] = advisers[i];
        }
        return (stopped, multisigWallet, founder1, founder2, earlySponsor, _advisers, tokenTransfersEnabled,
            maxGasPrice);
    }

     
    function getContributor(address contributorAddress)
        constant
        returns(uint, bool, uint)
    {
        Contributor contributor = contributors[contributorAddress];
        return (contributor.amount, contributor.isCompensated, contributor.amountCompensated);
    }

     
    function getUncompensatedContributors(uint offset, uint limit)
        constant
        returns (uint[] contributorIndexes)
    {
        uint contributorsCount = contributorsKeys.length;

        if (limit == 0) {
            limit = contributorsCount;
        }

        uint i = offset;
        uint resultsCount = 0;
        uint[] memory _contributorIndexes = new uint[](limit);

        while (i < contributorsCount && resultsCount < limit) {
            if (!contributors[contributorsKeys[i]].isCompensated) {
                _contributorIndexes[resultsCount] = i;
                resultsCount++;
            }
            i++;
        }

        contributorIndexes = new uint[](resultsCount);
        for (i = 0; i < resultsCount; i++) {
            contributorIndexes[i] = _contributorIndexes[i];
        }
        return contributorIndexes;
    }

    function getNow()
        constant
        returns(uint)
    {
        return now;
    }
}