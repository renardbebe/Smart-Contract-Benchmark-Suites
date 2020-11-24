 

pragma solidity ^0.4.13;


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

contract MiniMeTokenFactory {

    function MiniMeTokenFactory() {
    }

    
    
    
    
    
    
    
    
    
    
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
    )
    Controlled()
    {
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

    
    
    
    function () payable {
        
        require(false);
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

contract MiniMeMintableToken is MiniMeToken {
  using SafeMath for uint256;

  
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  
  bool public mintingFinished = false;

  
  
  mapping (address => uint256) issuedTokens;

  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  
  function MiniMeMintableToken(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
  )
  MiniMeToken(
    _tokenFactory,
    _parentToken,
    _parentSnapShotBlock,
    _tokenName,
    _decimalUnits,
    _tokenSymbol,
    _transfersEnabled
  )
  {
  }

  
  function mint(address _to, uint256 _amount) onlyController canMint returns (bool) {

    
    generateTokens(_to, _amount);

    
    issuedTokens[_to] = issuedTokens[_to].add(_amount);

    
    Mint(_to, _amount);

    return true;
  }

  
  function finishMinting() onlyController canMint returns (bool) {

    
    
    mintingFinished = true;

    
    MintFinished();

    return true;
  }
}

contract MiniMeVestedToken is MiniMeMintableToken {
  using SafeMath for uint256;

  
  
  uint256 public vestingStartTime = 0;

  
  uint256 public vestingPeriodTime = 42 days;
  uint256 public vestingTotalPeriods = 8;

  
  function MiniMeVestedToken(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
  )
  MiniMeMintableToken(
    _tokenFactory,
    _parentToken,
    _parentSnapShotBlock,
    _tokenName,
    _decimalUnits,
    _tokenSymbol,
    _transfersEnabled
  )
  {
  }





  
  modifier canTransfer(address _sender, uint _value) {
    require(mintingFinished);
    require(_value <= vestedBalanceOf(_sender));
    _;
  }

  
  function transfer(address _to, uint _value)
    canTransfer(msg.sender, _value)
    public
    returns (bool success)
  {
    return super.transfer(_to, _value);
  }

  
  function transferFrom(address _from, address _to, uint _value)
    canTransfer(_from, _value)
    public
    returns (bool success)
  {
    return super.transferFrom(_from, _to, _value);
  }





  
  function setVestingParams(uint256 _vestingStartTime, uint256 _vestingTotalPeriods, uint256 _vestingPeriodTime) onlyController {
    vestingStartTime = _vestingStartTime;
    vestingTotalPeriods = _vestingTotalPeriods;
    vestingPeriodTime = _vestingPeriodTime;
  }

  
  function getVestingPeriodsCompleted(uint256 _vestingStartTime, uint256 _currentTime) public constant returns (uint256) {
      return _currentTime.sub(_vestingStartTime).div(vestingPeriodTime);
  }

  
  function getVestedBalance(uint256 _initialBalance, uint256 _currentBalance, uint256 _vestingStartTime, uint256 _currentTime)
      public constant returns (uint256)
  {
      
      if (_currentTime < _vestingStartTime) {
        return 0;
      }

      
      if (_currentTime >= _vestingStartTime.add(vestingPeriodTime.mul(vestingTotalPeriods))) {
          return _currentBalance;
      }

      
      uint256 vestedPeriodsCompleted = getVestingPeriodsCompleted(_vestingStartTime, _currentTime);

      
      uint256 vestingPeriodsRemaining = vestingTotalPeriods.sub(vestedPeriodsCompleted);
      uint256 unvestedBalance = _initialBalance.mul(vestingPeriodsRemaining).div(vestingTotalPeriods);

      
      return _currentBalance.sub(unvestedBalance);
  }

  
  function vestedBalanceOf(address _owner) public constant returns (uint256 balance) {
    return getVestedBalance(issuedTokens[_owner], balanceOf(_owner), vestingStartTime, block.timestamp);
  }

  
  function finishMinting() onlyController canMint returns (bool) {
    
    vestingStartTime = block.timestamp;

    return super.finishMinting();
  }
}

contract GreyzBTRCoin is MiniMeMintableToken {

  

  string private _kya;

   event DocumentUpdated(string _kya);

  function GreyzBTRCoin(address _tokenFactory)
    MiniMeMintableToken(
      _tokenFactory,
      0x0,
      0,
      "Greyz BTR Coin",
      0,
      "GBTR",
      true
    )
    {}

    
    function getDocument() external view returns (string) {
        return (_kya);
    }

    
    function updateDocument(string kya) external onlyController returns (bool) {
        return _updateDocument(kya);
    }

    
    function _updateDocument(string kya) internal returns (bool) {
        _kya = kya;

        emit DocumentUpdated(kya);

        return true;
    }
}