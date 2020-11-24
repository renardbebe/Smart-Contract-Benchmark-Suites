 

pragma solidity ^0.4.23;

interface ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data
    ) external;
}


contract Controlled {
     
     
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    constructor() internal { 
        controller = msg.sender; 
    }

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}


 
 


library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

     
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0) 
            return RLPItem(0, 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

     
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }
    }

     

     
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

     
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr);  
           count++;
        }

        return count;
    }

     
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 1;
        
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7)  
                memPtr := add(memPtr, 1)  
                
                 
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))  
                len := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))  
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

     
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)   
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

     

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
         
        require(item.len == 21, "Invalid RLPItem. Addresses are encoded in 20 bytes");
        
        uint memPtr = item.memPtr + 1;  
        uint addr;
        assembly {
            addr := div(mload(memPtr), exp(256, 12))  
        }
        
        return address(addr);
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;

        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len)))  
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;  
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }


     
    function copy(uint src, uint dest, uint len) internal pure {
         
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

         
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))  
            let destpart := and(mload(dest), mask)  
            mstore(dest, or(destpart, srcpart))
        }
    }
}

contract RLPHelper {
    using RLPReader for bytes;
    using RLPReader for uint;
    using RLPReader for RLPReader.RLPItem;

    function isList(bytes memory item) public pure returns (bool) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.isList();
    }

    function itemLength(bytes memory item) public pure returns (uint) {
        uint memPtr;
        assembly {
            memPtr := add(0x20, item)
        }

        return memPtr._itemLength();
    }

    function numItems(bytes memory item) public pure returns (uint) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.numItems();
    }

    function toBytes(bytes memory item) public pure returns (bytes) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toBytes();
    }

    function toUint(bytes memory item) public pure returns (uint) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toUint();
    }

    function toAddress(bytes memory item) public pure returns (address) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toAddress();
    }

    function toBoolean(bytes memory item) public pure returns (bool) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toBoolean();
    }

    function bytesToString(bytes memory item) public pure returns (string) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return string(rlpItem.toBytes());
    }

     
     


     

    function pollTitle(bytes memory item) public pure returns (string) {
        RLPReader.RLPItem[] memory items = item.toRlpItem().toList();
        return string(items[0].toBytes());
    }

    function pollBallot(bytes memory item, uint ballotNum) public pure returns (string) {
        RLPReader.RLPItem[] memory items = item.toRlpItem().toList();
        items = items[1].toList();
        return string(items[ballotNum].toBytes());
    }
}




 
 



 
interface TokenController {
     
    function proxyPayment(address _owner) external payable returns(bool);

     
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

     
    function onApprove(address _owner, address _spender, uint _amount) external
        returns(bool);
}






 
 

interface ERC20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

     
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract MiniMeTokenInterface is ERC20Token {

     
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) 
        external 
        returns (bool success);

     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) 
        public
        returns(address);

     
    function generateTokens(
        address _owner,
        uint _amount
    )
        public
        returns (bool);

     
    function destroyTokens(
        address _owner,
        uint _amount
    ) 
        public
        returns (bool);

     
    function enableTransfers(bool _transfersEnabled) public;

     
    function claimTokens(address _token) public;

     
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) 
        public
        constant
        returns (uint);

     
    function totalSupplyAt(uint _blockNumber) public view returns(uint);

}




 
 
 

 
contract MiniMeTokenFactory {

     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
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

 
contract MiniMeToken is MiniMeTokenInterface, Controlled {

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

 
 
 

     
    constructor(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) 
        public
    {
        require(_tokenFactory != address(0));  
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
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
        return doTransfer(msg.sender, _to, _amount);
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) 
        public 
        returns (bool success)
    {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) { 
                return false;
            }
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
    function doTransfer(
        address _from,
        address _to,
        uint _amount
    ) 
        internal
        returns(bool)
    {

        if (_amount == 0) {
            return true;
        }

        require(parentSnapShotBlock < block.number);

         
        require((_to != 0) && (_to != address(this)));

         
         
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }

         
        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(_from, _to, _amount));
        }

         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

         
         
        uint256 previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

         
        emit Transfer(_from, _to, _amount);

        return true;
    }

    function doApprove(
        address _from,
        address _spender,
        uint256 _amount
    )
        internal 
        returns (bool)
    {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[_from][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(_from, _spender, _amount));
        }

        allowed[_from][_spender] = _amount;
        emit Approval(_from, _spender, _amount);
        return true;
    }

     
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
    function approve(address _spender, uint256 _amount) external returns (bool success) {
        doApprove(msg.sender, _spender, _amount);
    }

     
    function allowance(
        address _owner,
        address _spender
    ) 
        external
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
     
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) 
        external 
        returns (bool success)
    {
        require(doApprove(msg.sender, _spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
    function totalSupply() external view returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) 
        public
        view
        returns (uint) 
    {

         
         
         
         
         
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

     
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

         
         
         
         
         
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
        ) 
            public
            returns(address)
        {
        uint snapshotBlock = _snapshotBlock;
        if (snapshotBlock == 0) {
            snapshotBlock = block.number;
        }
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        emit NewCloneToken(address(cloneToken), snapshotBlock);
        return address(cloneToken);
    }

 
 
 
    
     
    function generateTokens(
        address _owner,
        uint _amount
    )
        public
        onlyController
        returns (bool)
    {
        uint curTotalSupply = totalSupplyAt(block.number);
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOfAt(_owner, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }

     
    function destroyTokens(
        address _owner,
        uint _amount
    ) 
        public
        onlyController
        returns (bool)
    {
        uint curTotalSupply = totalSupplyAt(block.number);
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOfAt(_owner, block.number);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 

     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
    function getValueAt(
        Checkpoint[] storage checkpoints,
        uint _block
    ) 
        view
        internal
        returns (uint)
    {
        if (checkpoints.length == 0) {
            return 0;
        }

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
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
        if (
            (checkpoints.length == 0) ||
            (checkpoints[checkpoints.length - 1].fromBlock < block.number)) 
        {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }

     
    function isContract(address _addr) internal view returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }    
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

     
    function min(uint a, uint b) internal returns (uint) {
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
        uint balance = token.balanceOf(address(this));
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

}



contract PollManager is Controlled {

    struct Poll {
        uint startBlock;
        uint endBlock;
        bool canceled;
        uint voters;
        bytes description;
        uint8 numBallots;
        mapping(uint8 => mapping(address => uint)) ballots;
        mapping(uint8 => uint) qvResults;
        mapping(uint8 => uint) results;
        address author;
    }

    Poll[] _polls;

    MiniMeToken public token;

    RLPHelper public rlpHelper;

     
     
    constructor(address _token) 
        public {
        token = MiniMeToken(_token);
        rlpHelper = new RLPHelper();
    }

     
    modifier onlySNTHolder {
        require(token.balanceOf(msg.sender) > 0, "SNT Balance is required to perform this operation"); 
        _; 
    }

     
     
     
     
    function addPoll(
        uint _endBlock,
        bytes _description,
        uint8 _numBallots)
        public
        onlySNTHolder
        returns (uint _idPoll)
    {
        _idPoll = addPoll(block.number, _endBlock, _description, _numBallots);
    }

     
     
     
     
     
    function addPoll(
        uint _startBlock,
        uint _endBlock,
        bytes _description,
        uint8 _numBallots)
        public
        onlySNTHolder
        returns (uint _idPoll)
    {
        require(_endBlock > block.number, "End block must be greater than current block");
        require(_startBlock >= block.number && _startBlock < _endBlock, "Start block must not be in the past, and should be less than the end block" );
        require(_numBallots <= 15, "Only a max of 15 ballots are allowed");

        _idPoll = _polls.length;
        _polls.length ++;

        Poll storage p = _polls[_idPoll];
        p.startBlock = _startBlock;
        p.endBlock = _endBlock;
        p.voters = 0;
        p.numBallots = _numBallots;
        p.description = _description;
        p.author = msg.sender;

        emit PollCreated(_idPoll); 
    }

     
     
     
     
    function updatePollDescription(
        uint _idPoll, 
        bytes _description,
        uint8 _numBallots)
        public
    {
        require(_idPoll < _polls.length, "Invalid _idPoll");
        require(_numBallots <= 15, "Only a max of 15 ballots are allowed");

        Poll storage p = _polls[_idPoll];
        require(p.startBlock > block.number, "You cannot modify an active poll");
        require(p.author == msg.sender || msg.sender == controller, "Only the owner/controller can modify the poll");

        p.numBallots = _numBallots;
        p.description = _description;
        p.author = msg.sender;
    }

     
     
     
    function cancelPoll(uint _idPoll) 
        public {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];
        
        require(!p.canceled, "Poll has been canceled already");
        require(p.endBlock > block.number, "Only active polls can be canceled");

        if(p.startBlock < block.number){
            require(msg.sender == controller, "Only the controller can cancel the poll");
        } else {
            require(p.author == msg.sender, "Only the owner can cancel the poll");
        }

        p.canceled = true;

        emit PollCanceled(_idPoll);
    }

     
     
     
    function canVote(uint _idPoll) 
        public 
        view 
        returns(bool)
    {
        if(_idPoll >= _polls.length) return false;

        Poll storage p = _polls[_idPoll];
        uint balance = token.balanceOfAt(msg.sender, p.startBlock);
        return block.number >= p.startBlock && block.number < p.endBlock && !p.canceled && balance != 0;
    }
    
     
     
     
    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     
     
     
    function vote(uint _idPoll, uint[] _ballots) public {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];

        require(block.number >= p.startBlock && block.number < p.endBlock && !p.canceled, "Poll is inactive");
        require(_ballots.length == p.numBallots, "Number of ballots is incorrect");

        unvote(_idPoll);

        uint amount = token.balanceOfAt(msg.sender, p.startBlock);
        require(amount != 0, "No SNT balance available at start block of poll");

        p.voters++;

        uint totalBallots = 0;
        for(uint8 i = 0; i < _ballots.length; i++){
            totalBallots += _ballots[i];

            p.ballots[i][msg.sender] = _ballots[i];

            if(_ballots[i] != 0){
                p.qvResults[i] += sqrt(_ballots[i] / 1 ether);
                p.results[i] += _ballots[i];
            }
        }

        require(totalBallots <= amount, "Total ballots must be less than the SNT balance at poll start block");

        emit Vote(_idPoll, msg.sender, _ballots);
    }

     
     
    function unvote(uint _idPoll) public {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];
        
        require(block.number >= p.startBlock && block.number < p.endBlock && !p.canceled, "Poll is inactive");

        if(p.voters == 0) return;

        p.voters--;

        for(uint8 i = 0; i < p.numBallots; i++){
            uint ballotAmount = p.ballots[i][msg.sender];

            p.ballots[i][msg.sender] = 0;

            if(ballotAmount != 0){
                p.qvResults[i] -= sqrt(ballotAmount / 1 ether);
                p.results[i] -= ballotAmount;
            }
        }

        emit Unvote(_idPoll, msg.sender);
    }

     

     
     
    function nPolls()
        public
        view 
        returns(uint)
    {
        return _polls.length;
    }

     
     
    function poll(uint _idPoll)
        public 
        view 
        returns(
        uint _startBlock,
        uint _endBlock,
        bool _canVote,
        bool _canceled,
        bytes _description,
        uint8 _numBallots,
        bool _finalized,
        uint _voters,
        address _author,
        uint[15] _tokenTotal,
        uint[15] _quadraticVotes
    )
    {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];

        _startBlock = p.startBlock;
        _endBlock = p.endBlock;
        _canceled = p.canceled;
        _canVote = canVote(_idPoll);
        _description = p.description;
        _numBallots = p.numBallots;
        _author = p.author;
        _finalized = (!p.canceled) && (block.number >= _endBlock);
        _voters = p.voters;

        for(uint8 i = 0; i < p.numBallots; i++){
            _tokenTotal[i] = p.results[i];
            _quadraticVotes[i] = p.qvResults[i];
        }
    }

     
     
     
    function pollTitle(uint _idPoll) public view returns (string){
        require(_idPoll < _polls.length, "Invalid _idPoll");
        Poll memory p = _polls[_idPoll];

        return rlpHelper.pollTitle(p.description);
    }

     
     
     
     
    function pollBallot(uint _idPoll, uint _ballot) public view returns (string){
        require(_idPoll < _polls.length, "Invalid _idPoll");
        Poll memory p = _polls[_idPoll];

        return rlpHelper.pollBallot(p.description, _ballot);
    }

     
     
     
    function getVote(uint _idPoll, address _voter) 
        public 
        view 
        returns (uint[15] votes){
        require(_idPoll < _polls.length, "Invalid _idPoll");
        Poll storage p = _polls[_idPoll];
        for(uint8 i = 0; i < p.numBallots; i++){
            votes[i] = p.ballots[i][_voter];
        }
        return votes;
    }

    event Vote(uint indexed idPoll, address indexed _voter, uint[] ballots);
    event Unvote(uint indexed idPoll, address indexed _voter);
    event PollCanceled(uint indexed idPoll);
    event PollCreated(uint indexed idPoll);
}