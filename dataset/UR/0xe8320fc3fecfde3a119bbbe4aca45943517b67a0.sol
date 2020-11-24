 

pragma solidity ^0.4.11;


 
 
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
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

 
 

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

    struct Curve {
        bytes32 hash;
         
        uint256 limit;
         
         
        uint256 slopeFactor;
         
        uint256 collectMinimum;
    }

    address public contribution;

    Curve[] public curves;
    uint256 public currentIndex;
    uint256 public revealedCurves;
    bool public allRevealed;

     
     
    modifier onlyContribution {
        require(msg.sender == contribution);
        _;
    }

    function DynamicCeiling(address _owner, address _contribution) {
        owner = _owner;
        contribution = _contribution;
    }

     
     
     
     
     
     
    function setHiddenCurves(bytes32[] _curveHashes) public onlyOwner {
        require(curves.length == 0);

        curves.length = _curveHashes.length;
        for (uint256 i = 0; i < _curveHashes.length; i = i.add(1)) {
            curves[i].hash = _curveHashes[i];
        }
    }


     
     
     
     
     
    function revealCurve(uint256 _limit, uint256 _slopeFactor, uint256 _collectMinimum,
                         bool _last, bytes32 _salt) public {
        require(!allRevealed);

        require(curves[revealedCurves].hash == calculateHash(_limit, _slopeFactor, _collectMinimum,
                                                             _last, _salt));

        require(_limit != 0 && _slopeFactor != 0 && _collectMinimum != 0);
        if (revealedCurves > 0) {
            require(_limit >= curves[revealedCurves.sub(1)].limit);
        }

        curves[revealedCurves].limit = _limit;
        curves[revealedCurves].slopeFactor = _slopeFactor;
        curves[revealedCurves].collectMinimum = _collectMinimum;
        revealedCurves = revealedCurves.add(1);

        if (_last) allRevealed = true;
    }

     
    function revealMulti(uint256[] _limits, uint256[] _slopeFactors, uint256[] _collectMinimums,
                         bool[] _lasts, bytes32[] _salts) public {
         
        require(_limits.length != 0 &&
                _limits.length == _slopeFactors.length &&
                _limits.length == _collectMinimums.length &&
                _limits.length == _lasts.length &&
                _limits.length == _salts.length);

        for (uint256 i = 0; i < _limits.length; i = i.add(1)) {
            revealCurve(_limits[i], _slopeFactors[i], _collectMinimums[i],
                        _lasts[i], _salts[i]);
        }
    }

     
    function moveTo(uint256 _index) public onlyOwner {
        require(_index < revealedCurves &&        
                _index == currentIndex.add(1));   
        currentIndex = _index;
    }

     
     
    function toCollect(uint256 collected) public onlyContribution returns (uint256) {
        if (revealedCurves == 0) return 0;

         
        if (collected >= curves[currentIndex].limit) {   
            uint256 nextIndex = currentIndex.add(1);
            if (nextIndex >= revealedCurves) return 0;   
            currentIndex = nextIndex;
            if (collected >= curves[currentIndex].limit) return 0;   
        }

         
        uint256 difference = curves[currentIndex].limit.sub(collected);

         
        uint256 collect = difference.div(curves[currentIndex].slopeFactor);

         
        if (collect <= curves[currentIndex].collectMinimum) {
            if (difference > curves[currentIndex].collectMinimum) {
                return curves[currentIndex].collectMinimum;
            } else {
                return difference;
            }
        } else {
            return collect;
        }
    }

     
     
     
     
     
    function calculateHash(uint256 _limit, uint256 _slopeFactor, uint256 _collectMinimum,
                           bool _last, bytes32 _salt) public constant returns (bytes32) {
        return keccak256(_limit, _slopeFactor, _collectMinimum, _last, _salt);
    }

     
     
     
    function nCurves() public constant returns (uint256) {
        return curves.length;
    }

}


 

 
 
 
 
 
 
 


 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

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
        creationBlock = getBlockNumber();
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
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           if (parentSnapShotBlock >= getBlockNumber()) throw;

            
           if ((_to == 0) || (_to == address(this))) throw;

            
            
           var previousBalanceFrom = balanceOfAt(_from, getBlockNumber());
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               if (!TokenController(controller).onTransfer(_from, _to, _amount))
               throw;
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, getBlockNumber());
           if (previousBalanceTo + _amount < previousBalanceTo) throw;  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, getBlockNumber());
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
        return totalSupplyAt(getBlockNumber());
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
        if (_snapshotBlock == 0) _snapshotBlock = getBlockNumber();
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
        uint curTotalSupply = getValueAt(totalSupplyHistory, getBlockNumber());
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
        uint curTotalSupply = getValueAt(totalSupplyHistory, getBlockNumber());
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
        || (checkpoints[checkpoints.length -1].fromBlock < getBlockNumber())) {
               Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(getBlockNumber());
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


 
 
 

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
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


 


contract SNT is MiniMeToken {
     
    function SNT(address _tokenFactory)
            MiniMeToken(
                _tokenFactory,
                0x0,                      
                0,                        
                "Status Network Token",   
                18,                       
                "SNT",                    
                true                      
            ) {}
}


 

 
 
 
 
 
 
 
 


contract StatusContribution is Owned, TokenController {
    using SafeMath for uint256;

    uint256 constant public failSafeLimit = 300000 ether;
    uint256 constant public maxGuaranteedLimit = 30000 ether;
    uint256 constant public exchangeRate = 10000;
    uint256 constant public maxGasPrice = 50000000000;
    uint256 constant public maxCallFrequency = 100;

    MiniMeToken public SGT;
    MiniMeToken public SNT;
    uint256 public startBlock;
    uint256 public endBlock;

    address public destEthDevs;

    address public destTokensDevs;
    address public destTokensReserve;
    uint256 public maxSGTSupply;
    address public destTokensSgt;
    DynamicCeiling public dynamicCeiling;

    address public sntController;

    mapping (address => uint256) public guaranteedBuyersLimit;
    mapping (address => uint256) public guaranteedBuyersBought;

    uint256 public totalGuaranteedCollected;
    uint256 public totalNormalCollected;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    mapping (address => uint256) public lastCallBlock;

    bool public paused;

    modifier initialized() {
        require(address(SNT) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(getBlockNumber() >= startBlock &&
                getBlockNumber() <= endBlock &&
                finalizedBlock == 0 &&
                address(SNT) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function StatusContribution() {
        paused = false;
    }


     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function initialize(
        address _snt,
        address _sntController,

        uint256 _startBlock,
        uint256 _endBlock,

        address _dynamicCeiling,

        address _destEthDevs,

        address _destTokensReserve,
        address _destTokensSgt,
        address _destTokensDevs,

        address _sgt,
        uint256 _maxSGTSupply
    ) public onlyOwner {
         
        require(address(SNT) == 0x0);

        SNT = MiniMeToken(_snt);
        require(SNT.totalSupply() == 0);
        require(SNT.controller() == address(this));
        require(SNT.decimals() == 18);   

        require(_sntController != 0x0);
        sntController = _sntController;

        require(_startBlock >= getBlockNumber());
        require(_startBlock < _endBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;

        require(_dynamicCeiling != 0x0);
        dynamicCeiling = DynamicCeiling(_dynamicCeiling);

        require(_destEthDevs != 0x0);
        destEthDevs = _destEthDevs;

        require(_destTokensReserve != 0x0);
        destTokensReserve = _destTokensReserve;

        require(_destTokensSgt != 0x0);
        destTokensSgt = _destTokensSgt;

        require(_destTokensDevs != 0x0);
        destTokensDevs = _destTokensDevs;

        require(_sgt != 0x0);
        SGT = MiniMeToken(_sgt);

        require(_maxSGTSupply >= MiniMeToken(SGT).totalSupply());
        maxSGTSupply = _maxSGTSupply;
    }

     
     
     
     
     
     
     
    function setGuaranteedAddress(address _th, uint256 _limit) public initialized onlyOwner {
        require(getBlockNumber() < startBlock);
        require(_limit > 0 && _limit <= maxGuaranteedLimit);
        guaranteedBuyersLimit[_th] = _limit;
        GuaranteedAddress(_th, _limit);
    }

     
     
    function () public payable notPaused {
        proxyPayment(msg.sender);
    }


     
     
     

     
     
     
     
    function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
        require(_th != 0x0);
        if (guaranteedBuyersLimit[_th] > 0) {
            buyGuaranteed(_th);
        } else {
            buyNormal(_th);
        }
        return true;
    }

    function onTransfer(address, address, uint256) public returns (bool) {
        return false;
    }

    function onApprove(address, address, uint256) public returns (bool) {
        return false;
    }

    function buyNormal(address _th) internal {
        require(tx.gasprice <= maxGasPrice);

         
        address caller;
        if (msg.sender == address(SNT)) {
            caller = _th;
        } else {
            caller = msg.sender;
        }

         
        require(!isContract(caller));

        require(getBlockNumber().sub(lastCallBlock[caller]) >= maxCallFrequency);
        lastCallBlock[caller] = getBlockNumber();

        uint256 toCollect = dynamicCeiling.toCollect(totalNormalCollected);

        uint256 toFund;
        if (msg.value <= toCollect) {
            toFund = msg.value;
        } else {
            toFund = toCollect;
        }

        totalNormalCollected = totalNormalCollected.add(toFund);
        doBuy(_th, toFund, false);
    }

    function buyGuaranteed(address _th) internal {
        uint256 toCollect = guaranteedBuyersLimit[_th];

        uint256 toFund;
        if (guaranteedBuyersBought[_th].add(msg.value) > toCollect) {
            toFund = toCollect.sub(guaranteedBuyersBought[_th]);
        } else {
            toFund = msg.value;
        }

        guaranteedBuyersBought[_th] = guaranteedBuyersBought[_th].add(toFund);
        totalGuaranteedCollected = totalGuaranteedCollected.add(toFund);
        doBuy(_th, toFund, true);
    }

    function doBuy(address _th, uint256 _toFund, bool _guaranteed) internal {
        assert(msg.value >= _toFund);   
        assert(totalCollected() <= failSafeLimit);

        if (_toFund > 0) {
            uint256 tokensGenerated = _toFund.mul(exchangeRate);
            assert(SNT.generateTokens(_th, tokensGenerated));
            destEthDevs.transfer(_toFund);
            NewSale(_th, _toFund, tokensGenerated, _guaranteed);
        }

        uint256 toReturn = msg.value.sub(_toFund);
        if (toReturn > 0) {
             
             
             
            if (msg.sender == address(SNT)) {
                _th.transfer(toReturn);
            } else {
                msg.sender.transfer(toReturn);
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     


     
     
     
     
    function finalize() public initialized {
        require(getBlockNumber() >= startBlock);
        require(msg.sender == owner || getBlockNumber() > endBlock);
        require(finalizedBlock == 0);

         
        require(dynamicCeiling.allRevealed());

         
        if (getBlockNumber() <= endBlock) {
            var (,lastLimit,,) = dynamicCeiling.curves(dynamicCeiling.revealedCurves().sub(1));
            require(totalNormalCollected >= lastLimit);
        }

        finalizedBlock = getBlockNumber();
        finalizedTime = now;

        uint256 percentageToSgt;
        if (SGT.totalSupply() >= maxSGTSupply) {
            percentageToSgt = percent(10);   
        } else {

             
             
             
             
             
            percentageToSgt = percent(10).mul(SGT.totalSupply()).div(maxSGTSupply);
        }

        uint256 percentageToDevs = percent(20);   


         
         
         
        uint256 percentageToContributors = percent(41).add(percent(10).sub(percentageToSgt));

        uint256 percentageToReserve = percent(29);


         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        uint256 totalTokens = SNT.totalSupply().mul(percent(100)).div(percentageToContributors);


         

         
         
         
         
         
        assert(SNT.generateTokens(
            destTokensReserve,
            totalTokens.mul(percentageToReserve).div(percent(100))));

         
         
         
         
         
        assert(SNT.generateTokens(
            destTokensSgt,
            totalTokens.mul(percentageToSgt).div(percent(100))));


         
         
         
         
         
        assert(SNT.generateTokens(
            destTokensDevs,
            totalTokens.mul(percentageToDevs).div(percent(100))));

        SNT.changeController(sntController);

        Finalized();
    }

    function percent(uint256 p) internal returns (uint256) {
        return p.mul(10**16);
    }

     
     
     
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) return false;
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }


     
     
     

     
    function tokensIssued() public constant returns (uint256) {
        return SNT.totalSupply();
    }

     
    function totalCollected() public constant returns (uint256) {
        return totalNormalCollected.add(totalGuaranteedCollected);
    }


     
     
     

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }


     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (SNT.controller() == address(this)) {
            SNT.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }


     
    function pauseContribution() onlyOwner {
        paused = true;
    }

     
    function resumeContribution() onlyOwner {
        paused = false;
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(address indexed _th, uint256 _amount, uint256 _tokens, bool _guaranteed);
    event GuaranteedAddress(address indexed _th, uint256 _limit);
    event Finalized();
}


 

 
 
 
 
 
 

 
 
 
 



contract ContributionWallet {

     
    address public multisig;
    uint256 public endBlock;
    StatusContribution public contribution;

     
     
     
     
    function ContributionWallet(address _multisig, uint256 _endBlock, address _contribution) {
        require(_multisig != 0x0);
        require(_contribution != 0x0);
        require(_endBlock != 0 && _endBlock <= 4000000);
        multisig = _multisig;
        endBlock = _endBlock;
        contribution = StatusContribution(_contribution);
    }

     
    function () public payable {}

     
    function withdraw() public {
        require(msg.sender == multisig);               
        require(block.number > endBlock ||             
                contribution.finalizedBlock() != 0);   
        multisig.transfer(this.balance);
    }

}


 

 
 
 
 
 


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



contract DevTokensHolder is Owned {
    using SafeMath for uint256;

    uint256 collectedTokens;
    StatusContribution contribution;
    MiniMeToken snt;

    function DevTokensHolder(address _owner, address _contribution, address _snt) {
        owner = _owner;
        contribution = StatusContribution(_contribution);
        snt = MiniMeToken(_snt);
    }


     
    function collectTokens() public onlyOwner {
        uint256 balance = snt.balanceOf(address(this));
        uint256 total = collectedTokens.add(balance);

        uint256 finalizedTime = contribution.finalizedTime();

        require(finalizedTime > 0 && getTime() > finalizedTime.add(months(6)));

        uint256 canExtract = total.mul(getTime().sub(finalizedTime)).div(months(24));

        canExtract = canExtract.sub(collectedTokens);

        if (canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens = collectedTokens.add(canExtract);
        assert(snt.transfer(owner, canExtract));

        TokensWithdrawn(owner, canExtract);
    }

    function months(uint256 m) internal returns (uint256) {
        return m.mul(30 days);
    }

    function getTime() internal returns (uint256) {
        return now;
    }


     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(snt));
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensWithdrawn(address indexed _holder, uint256 _amount);
}


 

 
 
 
 
 
 
 


contract SGTExchanger is TokenController, Owned {
    using SafeMath for uint256;

    mapping (address => uint256) public collected;
    uint256 public totalCollected;
    MiniMeToken public sgt;
    MiniMeToken public snt;
    StatusContribution public statusContribution;

    function SGTExchanger(address _sgt, address _snt, address _statusContribution) {
        sgt = MiniMeToken(_sgt);
        snt = MiniMeToken(_snt);
        statusContribution = StatusContribution(_statusContribution);
    }

     
     
    function collect() public {
        uint256 finalizedBlock = statusContribution.finalizedBlock();

        require(finalizedBlock != 0);
        require(getBlockNumber() > finalizedBlock);

        uint256 total = totalCollected.add(snt.balanceOf(address(this)));

        uint256 balance = sgt.balanceOfAt(msg.sender, finalizedBlock);

         
        uint256 amount = total.mul(balance).div(sgt.totalSupplyAt(finalizedBlock));

         
        amount = amount.sub(collected[msg.sender]);

        require(amount > 0);   

        totalCollected = totalCollected.add(amount);
        collected[msg.sender] = collected[msg.sender].add(amount);

        assert(snt.transfer(msg.sender, amount));

        TokensCollected(msg.sender, amount);
    }

    function proxyPayment(address) public payable returns (bool) {
        throw;
    }

    function onTransfer(address, address, uint256) public returns (bool) {
        return false;
    }

    function onApprove(address, address, uint256) public returns (bool) {
        return false;
    }

     
     
     

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(snt));
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensCollected(address indexed _holder, uint256 _amount);

}

 

 
 
 
 
 
 
 


contract SNTPlaceHolder is TokenController, Owned {
    using SafeMath for uint256;

    MiniMeToken public snt;
    StatusContribution public contribution;
    uint256 public activationTime;
    address public sgtExchanger;

     
     
     
     
     
     
    function SNTPlaceHolder(address _owner, address _snt, address _contribution, address _sgtExchanger) {
        owner = _owner;
        snt = MiniMeToken(_snt);
        contribution = StatusContribution(_contribution);
        sgtExchanger = _sgtExchanger;
    }

     
     
     

    function changeController(address _newController) public onlyOwner {
        snt.changeController(_newController);
        ControllerChanged(_newController);
    }


     
     
     

     
    function proxyPayment(address) public payable returns (bool) {
        return false;
    }

    function onTransfer(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }

    function onApprove(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }

    function transferable(address _from) internal returns (bool) {
         
        if (activationTime == 0) {
            uint256 f = contribution.finalizedTime();
            if (f > 0) {
                activationTime = f.add(1 weeks);
            } else {
                return false;
            }
        }
        return (getTime() > activationTime) || (_from == sgtExchanger);
    }


     
     
     

     
    function getTime() internal returns (uint256) {
        return now;
    }


     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (snt.controller() == address(this)) {
            snt.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event ControllerChanged(address indexed _newController);
}