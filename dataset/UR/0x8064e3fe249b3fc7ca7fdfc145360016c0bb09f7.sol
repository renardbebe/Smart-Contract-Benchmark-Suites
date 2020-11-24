 

pragma solidity 0.4.15;

 
 
contract Owned {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
    function changeOwner(address _newOwner) onlyOwner {
        if(msg.sender == owner) {
            owner = _newOwner;
        }
    }
}


 
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
}


contract DynamicCeiling is Owned {
    using SafeMath for uint256;

    struct Ceiling {
        bytes32 hash;
        uint256 limit;
        uint256 slopeFactor;
        uint256 collectMinimum;
    }

    address public saleAddress;

    Ceiling[] public ceilings;
    
    uint256 public currentIndex;
    uint256 public revealedCeilings;
    bool public allRevealed;

    modifier onlySaleAddress {
        require(msg.sender == saleAddress);
        _;
    }

    function DynamicCeiling(address _owner, address _saleAddress) {
        owner = _owner;
        saleAddress = _saleAddress;
    }

     
     
     
     
     
     
    function setHiddenCeilings(bytes32[] _ceilingHashes) public onlyOwner {
        require(ceilings.length == 0);

        ceilings.length = _ceilingHashes.length;
        for (uint256 i = 0; i < _ceilingHashes.length; i = i.add(1)) {
            ceilings[i].hash = _ceilingHashes[i];
        }
    }

     
     
     
     
     
    function revealCeiling(
        uint256 _limit, 
        uint256 _slopeFactor, 
        uint256 _collectMinimum,
        bool _last, 
        bytes32 _salt) 
        public 
        {
        require(!allRevealed);
        require(
            ceilings[revealedCeilings].hash == 
            calculateHash(
                _limit, 
                _slopeFactor, 
                _collectMinimum, 
                _last, 
                _salt
            )
        );

        require(_limit != 0 && _slopeFactor != 0 && _collectMinimum != 0);
        if (revealedCeilings > 0) {
            require(_limit >= ceilings[revealedCeilings.sub(1)].limit);
        }

        ceilings[revealedCeilings].limit = _limit;
        ceilings[revealedCeilings].slopeFactor = _slopeFactor;
        ceilings[revealedCeilings].collectMinimum = _collectMinimum;
        revealedCeilings = revealedCeilings.add(1);

        if (_last) {
            allRevealed = true;
        }
    }

     
    function revealMulti(
        uint256[] _limits,
        uint256[] _slopeFactors,
        uint256[] _collectMinimums,
        bool[] _lasts, 
        bytes32[] _salts) 
        public 
        {
         
        require(
            _limits.length != 0 &&
            _limits.length == _slopeFactors.length &&
            _limits.length == _collectMinimums.length &&
            _limits.length == _lasts.length &&
            _limits.length == _salts.length
        );

        for (uint256 i = 0; i < _limits.length; i = i.add(1)) {
            
            revealCeiling(
                _limits[i],
                _slopeFactors[i],
                _collectMinimums[i],
                _lasts[i],
                _salts[i]
            );
        }
    }

     
    function moveToNextCeiling() public onlyOwner {

        currentIndex = currentIndex.add(1);
    }

     
     
    function availableAmountToCollect(uint256  totallCollected) public onlySaleAddress returns (uint256) {
    
        if (revealedCeilings == 0) {
            return 0;
        }

        if (totallCollected >= ceilings[currentIndex].limit) {  
            uint256 nextIndex = currentIndex.add(1);

            if (nextIndex >= revealedCeilings) {
                return 0; 
            }
            currentIndex = nextIndex;
            if (totallCollected >= ceilings[currentIndex].limit) {
                return 0;  
            }
        }        
        uint256 remainedFromCurrentCeiling = ceilings[currentIndex].limit.sub(totallCollected);
        uint256 reminderWithSlopeFactor = remainedFromCurrentCeiling.div(ceilings[currentIndex].slopeFactor);

        if (reminderWithSlopeFactor > ceilings[currentIndex].collectMinimum) {
            return reminderWithSlopeFactor;
        }
        
        if (remainedFromCurrentCeiling > ceilings[currentIndex].collectMinimum) {
            return ceilings[currentIndex].collectMinimum;
        } else {
            return remainedFromCurrentCeiling;
        }
    }

     
     
     
     
     
     
    function calculateHash(
        uint256 _limit, 
        uint256 _slopeFactor, 
        uint256 _collectMinimum,
        bool _last, 
        bytes32 _salt) 
        public 
        constant 
        returns (bytes32) 
        {
        return keccak256(
            _limit,
            _slopeFactor, 
            _collectMinimum,
            _last,
            _salt
        );
    }

     
     
     
    function nCeilings() public constant returns (uint256) {
        return ceilings.length;
    }

}

 
contract Trustee is Owned {
    using SafeMath for uint256;

     
    SHP public shp;

    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 transferred;
        bool revokable;
    }

     
    mapping (address => Grant) public grants;

     
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event UnlockGrant(address indexed _holder, uint256 _value);
    event RevokeGrant(address indexed _holder, uint256 _refund);

     
     
    function Trustee(SHP _shp) {
        require(_shp != address(0));
        shp = _shp;
    }

     
     
     
     
     
     
     
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end, bool _revokable)
        public onlyOwner {
        require(_to != address(0));
        require(_value > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(totalVesting.add(_value) <= shp.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            transferred: 0,
            revokable: _revokable
        });

         
        totalVesting = totalVesting.add(_value);

        NewGrant(msg.sender, _to, _value);
    }

     
     
    function revoke(address _holder) public onlyOwner {
        Grant grant = grants[_holder];

        require(grant.revokable);

         
        uint256 refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

        totalVesting = totalVesting.sub(refund);
        shp.transfer(msg.sender, refund);

        RevokeGrant(_holder, refund);
    }

     
     
     
     
    function vestedTokens(address _holder, uint256 _time) public constant returns (uint256) {
        Grant grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function calculateVestedTokens(Grant _grant, uint256 _time) private constant returns (uint256) {
         
        if (_time < _grant.cliff) {
            return 0;
        }

         
        if (_time >= _grant.end) {
            return _grant.value;
        }

         
         return _grant.value.mul(_time.sub(_grant.start)).div(_grant.end.sub(_grant.start));
    }

     
     
    function unlockVestedTokens() public {
        Grant grant = grants[msg.sender];
        require(grant.value != 0);

         
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            return;
        }

         
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            return;
        }

        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        shp.transfer(msg.sender, transferable);

        UnlockGrant(msg.sender, transferable);
    }
}

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

 
 
 
contract MiniMeToken is Controlled {

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
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
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

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
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
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
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
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
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

     
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function ()  payable {
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
    ) returns (MiniMeToken) 
    {
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

contract SHP is MiniMeToken {
     
    function SHP(address _tokenFactory)
            MiniMeToken(
                _tokenFactory,
                0x0,                              
                0,                                
                "Sharpe Platform Token",          
                18,                               
                "SHP",                            
                true                              
            ) {}
}

contract AffiliateUtility is Owned {
    using SafeMath for uint256;
    
    uint256 public tierTwoMin;
    uint256 public tierThreeMin;

    uint256 public constant TIER1_PERCENT = 3;
    uint256 public constant TIER2_PERCENT = 4;
    uint256 public constant TIER3_PERCENT = 5;
    
    mapping (address => Affiliate) private affiliates;

    event AffiliateReceived(address affiliateAddress, address investorAddress, bool valid);

    struct Affiliate {
        address etherAddress;
        bool isPresent;
    }

    function AffiliateUtility(uint256 _tierTwoMin, uint256 _tierThreeMin) {
        setTiers(_tierTwoMin, _tierThreeMin);
    }

     
     
     
    function setTiers(uint256 _tierTwoMin, uint256 _tierThreeMin) onlyOwner {
        tierTwoMin = _tierTwoMin;
        tierThreeMin = _tierThreeMin;
    }

     
     
     
    function addAffiliate(address _investor, address _affiliate) onlyOwner {
        affiliates[_investor] = Affiliate(_affiliate, true);
    }

     
     
     
     
     
    function applyAffiliate(
        address _investor, 
        uint256 _contributorTokens, 
        uint256 _contributionValue
    )
        public 
        returns(uint256, uint256) 
    {
        if (getAffiliate(_investor) == address(0)) {
            return (0, 0);
        }

        uint256 contributorBonus = _contributorTokens.div(100);
        uint256 affiliateBonus = 0;

        if (_contributionValue < tierTwoMin) {
            affiliateBonus = _contributorTokens.mul(TIER1_PERCENT).div(100);
        } else if (_contributionValue >= tierTwoMin && _contributionValue < tierThreeMin) {
            affiliateBonus = _contributorTokens.mul(TIER2_PERCENT).div(100);
        } else {
            affiliateBonus = _contributorTokens.mul(TIER3_PERCENT).div(100);
        }

        return(affiliateBonus, contributorBonus);
    }

     
     
     
    function getAffiliate(address _investor) constant returns(address) {
        return affiliates[_investor].etherAddress;
    }

     
     
     
    function isAffiliateValid(address _investor) constant public returns(bool) {
        Affiliate memory affiliate = affiliates[_investor];
        AffiliateReceived(affiliate.etherAddress, _investor, affiliate.isPresent);
        return affiliate.isPresent;
    }
}

contract SCD is MiniMeToken {
     
    function SCD(address _tokenFactory)
            MiniMeToken(
                _tokenFactory,
                0x0,                              
                0,                                
                "Sharpe Crypto-Derivative",       
                18,                               
                "SCD",                            
                true                              
            ) {}
}


contract TokenSale is Owned, TokenController {
    using SafeMath for uint256;
    
    SHP public shp;
    AffiliateUtility public affiliateUtility;
    Trustee public trustee;

    address public etherEscrowAddress;
    address public bountyAddress;
    address public trusteeAddress;
    address public apiAddress;

    uint256 public founderTokenCount = 0;
    uint256 public reserveTokenCount = 0;

    uint256 constant public CALLER_EXCHANGE_RATE = 2000;
    uint256 constant public RESERVE_EXCHANGE_RATE = 1500;
    uint256 constant public FOUNDER_EXCHANGE_RATE = 1000;
    uint256 constant public BOUNTY_EXCHANGE_RATE = 500;
    uint256 constant public MAX_GAS_PRICE = 50000000000;

    bool public paused;
    bool public closed;

    mapping(address => bool) public approvedAddresses;

    event Contribution(uint256 etherAmount, address _caller);
    event NewSale(address indexed caller, uint256 etherAmount, uint256 tokensGenerated);
    event SaleClosed(uint256 when);
    
    modifier notPaused() {
        require(!paused);
        _;
    }

    modifier notClosed() {
        require(!closed);
        _;
    }

    modifier onlyApi() {
        require(msg.sender == apiAddress);
        _;
    }

    modifier isValidated() {
        require(msg.sender != 0x0);
        require(msg.value > 0);
        require(!isContract(msg.sender)); 
        require(tx.gasprice <= MAX_GAS_PRICE);
        _;
    }

    modifier isApproved() {
        require(approvedAddresses[msg.sender]);
        _;
    }

     
     
    function approveAddress(address _addr) public onlyApi {
        approvedAddresses[_addr] = true;
    }

     
     
     
    function doBuy(
        address _caller,
        uint256 etherAmount
    )
        internal
    {

        Contribution(etherAmount, _caller);

        uint256 callerTokens = etherAmount.mul(CALLER_EXCHANGE_RATE);
        uint256 callerTokensWithDiscount = applyDiscount(etherAmount, callerTokens);

        uint256 reserveTokens = etherAmount.mul(RESERVE_EXCHANGE_RATE);
        uint256 founderTokens = etherAmount.mul(FOUNDER_EXCHANGE_RATE);
        uint256 bountyTokens = etherAmount.mul(BOUNTY_EXCHANGE_RATE);
        uint256 vestingTokens = founderTokens.add(reserveTokens);

        founderTokenCount = founderTokenCount.add(founderTokens);
        reserveTokenCount = reserveTokenCount.add(reserveTokens);

        payAffiliate(callerTokensWithDiscount, msg.value, msg.sender);

        shp.generateTokens(_caller, callerTokensWithDiscount);
        shp.generateTokens(bountyAddress, bountyTokens);
        shp.generateTokens(trusteeAddress, vestingTokens);

        NewSale(_caller, etherAmount, callerTokensWithDiscount);
        NewSale(trusteeAddress, etherAmount, vestingTokens);
        NewSale(bountyAddress, etherAmount, bountyTokens);

        etherEscrowAddress.transfer(etherAmount);
        updateCounters(etherAmount);
    }

     
     
     
    function applyDiscount(uint256 _etherAmount, uint256 _contributorTokens) internal constant returns (uint256);

     
     
    function updateCounters(uint256 _etherAmount) internal;
    
     
     
     
     
     
    function TokenSale (
        address _etherEscrowAddress,
        address _bountyAddress,
        address _trusteeAddress,
        address _affiliateUtilityAddress,
        address _apiAddress
    ) {
        etherEscrowAddress = _etherEscrowAddress;
        bountyAddress = _bountyAddress;
        trusteeAddress = _trusteeAddress;
        apiAddress = _apiAddress;
        affiliateUtility = AffiliateUtility(_affiliateUtilityAddress);
        trustee = Trustee(_trusteeAddress);
        paused = true;
        closed = false;
    }

     
     
     
     
    function payAffiliate(uint256 _tokens, uint256 _etherValue, address _caller) internal {
        if (affiliateUtility.isAffiliateValid(_caller)) {
            address affiliate = affiliateUtility.getAffiliate(_caller);
            var (affiliateBonus, contributorBonus) = affiliateUtility.applyAffiliate(_caller, _tokens, _etherValue);
            shp.generateTokens(affiliate, affiliateBonus);
            shp.generateTokens(_caller, contributorBonus);
        }
    }

     
     
    function setShp(address _shp) public onlyOwner {
        shp = SHP(_shp);
    }

     
     
     
    function transferOwnership(address _tokenController, address _trusteeOwner) public onlyOwner {
        require(closed);
        require(_tokenController != 0x0);
        require(_trusteeOwner != 0x0);
        shp.changeController(_tokenController);
        trustee.changeOwner(_trusteeOwner);
    }

     
     
     
    function isContract(address _caller) internal constant returns (bool) {
        uint size;
        assembly { size := extcodesize(_caller) }
        return size > 0;
    }

     
    function pauseContribution() public onlyOwner {
        paused = true;
    }

     
    function resumeContribution() public onlyOwner {
        paused = false;
    }

     
     
     

     
    function proxyPayment(address) public payable returns (bool) {
        return false;
    }

    function onTransfer(address, address, uint256) public returns (bool) {
        return false;
    }

    function onApprove(address, address, uint256) public returns (bool) {
        return false;
    }
}


contract SharpeCrowdsale is TokenSale {

    uint256 public totalEtherPaid = 0;
    uint256 public minContributionInWei;
    address public saleAddress;
    
    DynamicCeiling public dynamicCeiling;

    modifier amountValidated() {
        require(msg.value >= minContributionInWei);
        _;
    }

     
     
     
     
     
     
    function SharpeCrowdsale( 
        address _etherEscrowAddress,
        address _bountyAddress,
        address _trusteeAddress,
        address _affiliateUtilityAddress,
        address _apiAddress,
        uint256 _minContributionInWei) 
        TokenSale (
        _etherEscrowAddress,
        _bountyAddress,
        _trusteeAddress,
        _affiliateUtilityAddress,
        _apiAddress) 
    {
        minContributionInWei = _minContributionInWei;
        saleAddress = address(this);
    }

    function setDynamicCeilingAddress(address _dynamicCeilingAddress) public onlyOwner {
        dynamicCeiling = DynamicCeiling(_dynamicCeilingAddress);
    }

    function () 
        public 
        payable
        notPaused
        notClosed
        isValidated 
        amountValidated
        isApproved
    {
        uint256 contribution = msg.value;
        uint256 remaining = dynamicCeiling.availableAmountToCollect(totalEtherPaid);
        uint256 refund = 0;

        if (remaining == 0) {
            revert();
        }

        if (contribution > remaining) {
            contribution = remaining;
            refund = msg.value.sub(contribution);
        }
        doBuy(msg.sender, contribution);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

     
     
     
    function applyDiscount(uint256 _etherAmount, uint256 _contributorTokens) internal constant returns (uint256) {
        return _contributorTokens;
    }

     
     
    function updateCounters(uint256 _etherAmount) internal {
        totalEtherPaid = totalEtherPaid.add(_etherAmount);
    }

     
    function closeSale() public onlyOwner {
        closed = true;
        SaleClosed(now);
    }
}