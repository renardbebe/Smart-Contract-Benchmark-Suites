 

pragma solidity ^0.4.15;

 
contract Controlled {
     
     
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

 
contract ERC20Token {
     
     
    function totalSupply() constant returns (uint256 balance);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MiniMeTokenI is ERC20Token, Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = "MMT_0.1";  

 
 
 

     
     
     
     
     
     
     
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) returns (bool success);

 
 
 

     
     
     
     
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) constant returns (uint);

     
     
     
    function totalSupplyAt(uint _blockNumber) constant returns(uint);

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) returns(address);

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) returns (bool);


     
     
     
     
    function destroyTokens(address _owner, uint _amount) returns (bool);

 
 
 

     
     
    function enableTransfers(bool _transfersEnabled);

 
 
 

     
     
     
     
    function claimTokens(address _token);

 
 
 

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}

 
 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) returns(bool);
}


 
contract ApproveAndCallReceiver {
    function receiveApproval(
        address _from, 
        uint256 _amount, 
        address _token, 
        bytes _data
    );
}

 
 
 
 
 
 
 
 
 

 
 
 
contract MiniMeToken is MiniMeTokenI {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = "MMT_0.1";  

     
     
     
    struct Checkpoint {

         
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

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) {
                return false;
            }
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {

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
            bool onTransfer = TokenController(controller).onTransfer(_from, _to, _amount);
            require(onTransfer);
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
            bool onApprove = TokenController(controller).onApprove(msg.sender, _spender, _amount);
            require(onApprove);
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) returns (bool success) {
        require(approve(_spender, _amount));

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

 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) constant returns (uint) {

         
         
         
         
         
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

     
     
     
    function totalSupplyAt(uint _blockNumber) constant returns(uint) {

         
         
         
         
         
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

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName, 
        uint8 _cloneDecimalUnits, 
        string _cloneTokenSymbol, 
        uint _snapshotBlock, 
        bool _transfersEnabled
    ) returns(address) 
    {

        if (_snapshotBlock == 0) {
            _snapshotBlock = block.number;
        }

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

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }

     
     
     
     
    function destroyTokens(address _owner, uint _amount) onlyController returns (bool) {
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

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0) {
            return 0;
        }

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

         
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

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
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
        bool proxyPayment = TokenController(controller).proxyPayment.value(msg.value)(msg.sender);
        require(proxyPayment);
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

contract DataBrokerDaoToken is MiniMeToken {  

    function DataBrokerDaoToken(address _tokenFactory) MiniMeToken(   
      _tokenFactory,
      0x0,                     
      0,                       
      "DataBroker DAO Token",  
      18,                      
      "DATA",                  
      true                    
      ) 
      {}

}

pragma solidity ^0.4.15;


 
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

contract EarlyTokenSale is TokenController, Controlled {

    using SafeMath for uint256;

     
    uint256 public startFundingTime;       
    uint256 public endFundingTime;
    
     
     
    uint256 constant public maximumFunding = 28125 ether;
    uint256 constant public tokensPerEther = 1200; 
    uint256 constant public maxGasPrice = 50000000000;
    
     
    uint256 constant public maxCallFrequency = 100;
    mapping (address => uint256) public lastCallBlock; 

     
    uint256 public totalCollected;

     
    DataBrokerDaoToken public tokenContract;

     
    address public vaultAddress;

    bool public paused;
    bool public finalized = false;

     
     
     
     
    function EarlyTokenSale(
        uint _startFundingTime, 
        uint _endFundingTime, 
        address _vaultAddress, 
        address _tokenAddress
    ) {
        require(_endFundingTime > now);
        require(_endFundingTime >= _startFundingTime);
        require(_vaultAddress != 0);
        require(_tokenAddress != 0);

        startFundingTime = _startFundingTime;
        endFundingTime = _endFundingTime;
        tokenContract = DataBrokerDaoToken(_tokenAddress);
        vaultAddress = _vaultAddress;
        paused = false;
    }

     
     
     
     
    function () payable notPaused {
        doPayment(msg.sender);
    }

     
     
     
    function proxyPayment(address _owner) payable notPaused returns(bool success) {
        return doPayment(_owner);
    }

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool success) {
        if ( _from == vaultAddress ) {
            return true;
        }
        return false;
    }

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) returns(bool success) {
        if ( _owner == vaultAddress ) {
            return true;
        }
        return false;
    }

     
     
     
     
    function doPayment(address _owner) internal returns(bool success) {
        require(tx.gasprice <= maxGasPrice);

         
         
        require(!isContract(msg.sender));
         
        require(getBlockNumber().sub(lastCallBlock[msg.sender]) >= maxCallFrequency);
        lastCallBlock[msg.sender] = getBlockNumber();

         
        if (msg.sender != controller) {
            require(startFundingTime <= now);
        }
        require(endFundingTime > now);
        require(tokenContract.controller() != 0);
        require(msg.value > 0);
        require(totalCollected.add(msg.value) <= maximumFunding);

         
        totalCollected = totalCollected.add(msg.value);

         
        require(vaultAddress.send(msg.value));

         
        require(tokenContract.generateTokens(_owner, tokensPerEther.mul(msg.value)));
        
        return true;
    }

    function changeTokenController(address _newController) onlyController {
        tokenContract.changeController(_newController);
    }

     
     
     
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) {
            return false;
        }
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

     
     
     
    function finalizeSale() onlyController {
        require(now > endFundingTime || totalCollected >= maximumFunding);
        require(!finalized);

        uint256 reservedTokens = 225000000 * 0.35 * 10**18;      
        if (!tokenContract.generateTokens(vaultAddress, reservedTokens)) {
            revert();
        }

        finalized = true;
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

   
    function pauseContribution() onlyController {
        paused = true;
    }

     
    function resumeContribution() onlyController {
        paused = false;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }
}