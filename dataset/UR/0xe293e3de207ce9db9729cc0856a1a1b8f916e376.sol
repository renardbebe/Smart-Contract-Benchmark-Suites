 

pragma solidity ^0.4.13;

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    constructor() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = "MMT_0.2";  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint256 public parentSnapShotBlock;

     
    uint256 public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

 
 
 

     
     
     
     
     
     
     
     
     
     
    constructor(
        address _parentToken,
        uint256 _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
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
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint256 _amount
    ) internal {

        if (_amount == 0) {
            emit Transfer(_from, _to, _amount);     
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

         
        emit Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        if (isContract(_spender)) {
            ApproveAndCallFallBack(_spender).receiveApproval(
                msg.sender,
                _amount,
                this,
                _extraData
            );
        }

        return true;
    }

     
     
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint256 _blockNumber) public view
        returns (uint256) {

         
         
         
         
         
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

     
     
     
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {

         
         
         
         
         
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

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint256 _amount
    ) public onlyController returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint256 previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint256 _amount
    ) onlyController public returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint256 previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block
    ) view internal returns (uint256) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value
    ) internal  {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }

     
     
     
    function isContract(address _addr) view internal returns(bool) {
        uint256 size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(address(this).balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

 
 
 

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

contract ERC677Receiver {
    function tokenFallback(address _from, uint _amount, bytes _data) public;
}

contract ERC677 is MiniMeToken {

     
    constructor(address _parentToken, uint _parentSnapShotBlock, string _tokenName, uint8 _decimalUnits, string _tokenSymbol, bool _transfersEnabled) public MiniMeToken(
        _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {
    }

     
    function transferAndCall(address _to, uint _amount, bytes _data) public returns (bool) {
        require(transfer(_to, _amount));

        emit Transfer(msg.sender, _to, _amount, _data);

         
        if (isContract(_to)) {
            ERC677Receiver(_to).tokenFallback(msg.sender, _amount, _data);
        }

        return true;
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes _data);
}

contract LogiToken is ERC677 {

     
    constructor() public ERC677(
        0x0,                       
        0,                         
        "LogiToken",               
        18,                        
        "LOGI",                    
        false                      
    ) {}
    

     
    uint256 public constant maxSupply = 100 * 1000 * 1000 * 10**uint256(decimals);

     
    mapping(address => uint256) public lockups;

    event LockedTokens(address indexed _holder, uint256 _lockup);

     
    function setLocks(address[] _holders, uint256[] _lockups) public onlyController {
        require(_holders.length == _lockups.length);
        require(_holders.length < 255);
        require(transfersEnabled == false);

        for (uint8 i = 0; i < _holders.length; i++) {
            address holder = _holders[i];
            uint256 lockup = _lockups[i];

             
            require(lockups[holder] == 0);

            lockups[holder] = lockup;

            emit LockedTokens(holder, lockup);
        }
    }

     
    function finishMinting() public onlyController() {
        assert(totalSupply() <= maxSupply);  
        enableTransfers(true);  
        changeController(address(0x0));  
    }

    modifier notLocked(address _addr) {
        require(now >= lockups[_addr]);
        _;
    }

     
    function transfer(address _to, uint256 _amount) public notLocked(msg.sender) returns (bool success) {
        return super.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public notLocked(_from) returns (bool success) {
        return super.transferFrom(_from, _to, _amount);
    }
}

contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}