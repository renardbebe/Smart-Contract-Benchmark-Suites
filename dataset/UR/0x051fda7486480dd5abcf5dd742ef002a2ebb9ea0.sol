 

pragma solidity ^0.4.11;

 
 
contract Owned {

     
     
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
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

contract ATTContribution is Owned, TokenController {
    using SafeMath for uint256;

    uint256 constant public exchangeRate = 600;    
    uint256 constant public maxGasPrice = 50000000000;   

    uint256 public maxFirstRoundTokenLimit = 20000000 ether;  

    uint256 public maxIssueTokenLimit = 70000000 ether;  

    MiniMeToken public  ATT;             

    address public attController;

    address public destEthFoundation;
    address public destTokensAngel;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public totalNormalTokenGenerated;
    uint256 public totalNormalEtherCollected;

    uint256 public totalIssueTokenGenerated;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    bool public paused;

    modifier initialized() {
        require(address(ATT) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTime &&
              time() <= endTime &&
              finalizedBlock == 0 &&
              address(ATT) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function ATTContribution() {
        paused = false;
    }


     
     
     
     
     
     
     
     
     
    function initialize(
        address _att,
        address _attController,
        uint _startTime,
        uint _endTime,
        address _destEthFoundation,
        address _destTokensAngel
    ) public onlyOwner {
       
      require(address(ATT) == 0x0);

      ATT = MiniMeToken(_att);
      require(ATT.totalSupply() == 0);
      require(ATT.controller() == address(this));
      require(ATT.decimals() == 18);   

      startTime = _startTime;
      endTime = _endTime;

      assert(startTime < endTime);

      require(_attController != 0x0);
      attController = _attController;

      require(_destEthFoundation != 0x0);
      destEthFoundation = _destEthFoundation;

      require(_destTokensAngel != 0x0);
      destTokensAngel = _destTokensAngel;
  }

   
   
  function () public payable notPaused {
      proxyPayment(msg.sender);
  }


   
   
   

   
   
   
   
  function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
      require(_th != 0x0);

      buyNormal(_th);

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
      if (msg.sender == address(ATT)) {
          caller = _th;
      } else {
          caller = msg.sender;
      }

       
      require(!isContract(caller));

      doBuy(_th, msg.value);
  }

  function doBuy(address _th, uint256 _toFund) internal {
      require(tx.gasprice <= maxGasPrice);

      assert(msg.value >= _toFund);   
      assert(totalNormalTokenGenerated < maxFirstRoundTokenLimit);

      uint256 endOfFirstWeek = startTime.add(1 weeks);
      uint256 endOfSecondWeek = startTime.add(2 weeks);
      uint256 finalExchangeRate = exchangeRate;
      if (now < endOfFirstWeek)
      {
           
          finalExchangeRate = exchangeRate.mul(110).div(100);
      } else if (now < endOfSecondWeek)
      {
           
          finalExchangeRate = exchangeRate.mul(105).div(100);
      }

      if (_toFund > 0) {
          uint256 tokensGenerating = _toFund.mul(finalExchangeRate);

          uint256 tokensToBeGenerated = totalNormalTokenGenerated.add(tokensGenerating);
          if (tokensToBeGenerated > maxFirstRoundTokenLimit)
          {
              tokensGenerating = maxFirstRoundTokenLimit - totalNormalTokenGenerated;
              _toFund = tokensGenerating.div(finalExchangeRate);
          }

          assert(ATT.generateTokens(_th, tokensGenerating));
          destEthFoundation.transfer(_toFund);

          totalNormalTokenGenerated = totalNormalTokenGenerated.add(tokensGenerating);

          totalNormalEtherCollected = totalNormalEtherCollected.add(_toFund);

          NewSale(_th, _toFund, tokensGenerating);
      }

      uint256 toReturn = msg.value.sub(_toFund);
      if (toReturn > 0) {
           
           
           
          if (msg.sender == address(ATT)) {
              _th.transfer(toReturn);
          } else {
              msg.sender.transfer(toReturn);
          }
      }
  }

  function issueTokenToGuaranteedAddress(address _th, uint256 _amount, bytes data) onlyOwner initialized notPaused contributionOpen {
      require(totalIssueTokenGenerated.add(_amount) <= maxIssueTokenLimit);

      assert(ATT.generateTokens(_th, _amount));

      totalIssueTokenGenerated = totalIssueTokenGenerated.add(_amount);

      NewIssue(_th, _amount, data);
  }

  function adjustLimitBetweenIssueAndNormal(uint256 _amount, bool _isAddToNormal) onlyOwner initialized contributionOpen {
      if(_isAddToNormal)
      {
          require(totalIssueTokenGenerated.add(_amount) <= maxIssueTokenLimit);
          maxIssueTokenLimit = maxIssueTokenLimit.sub(_amount);
          maxFirstRoundTokenLimit = maxFirstRoundTokenLimit.add(_amount);
      } else {
          require(totalNormalTokenGenerated.add(_amount) <= maxFirstRoundTokenLimit);
          maxFirstRoundTokenLimit = maxFirstRoundTokenLimit.sub(_amount);
          maxIssueTokenLimit = maxIssueTokenLimit.add(_amount);
      }
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   


   
   
   
   
  function finalize() public onlyOwner initialized {
      require(time() >= startTime);
       
      require(finalizedBlock == 0);

      finalizedBlock = getBlockNumber();
      finalizedTime = now;

      uint256 tokensToSecondRound = 90000000 ether;

      uint256 tokensToReserve = 90000000 ether;

      uint256 tokensToAngelAndOther = 30000000 ether;

       

       
      tokensToSecondRound = tokensToSecondRound.add(maxFirstRoundTokenLimit).sub(totalNormalTokenGenerated);
      
      tokensToSecondRound = tokensToSecondRound.add(maxIssueTokenLimit).sub(totalIssueTokenGenerated);

      uint256 totalTokens = 300000000 ether;

      require(totalTokens == ATT.totalSupply().add(tokensToSecondRound).add(tokensToReserve).add(tokensToAngelAndOther));

      assert(ATT.generateTokens(0xb1, tokensToSecondRound));

      assert(ATT.generateTokens(0xb2, tokensToReserve));

      assert(ATT.generateTokens(destTokensAngel, tokensToAngelAndOther));

       

      ATT.changeController(attController);

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

  function time() constant returns (uint) {
      return block.timestamp;
  }

   
   
   

   
  function tokensIssued() public constant returns (uint256) {
      return ATT.totalSupply();
  }

   
   
   

   
  function getBlockNumber() internal constant returns (uint256) {
      return block.number;
  }

   
   
   

   
   
   
   
  function claimTokens(address _token) public onlyOwner {
      if (ATT.controller() == address(this)) {
          ATT.claimTokens(_token);
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
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event NewIssue(address indexed _th, uint256 _amount, bytes data);
  event Finalized();
}