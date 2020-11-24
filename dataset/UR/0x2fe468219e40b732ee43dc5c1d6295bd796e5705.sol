 

pragma solidity 0.4.24;

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);

     
     
     
     
    function onBurn(address _owner, uint _amount) public returns(bool);
}
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'EFX_0.1';  


     
     
     
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

     
    Checkpoint[] totalPledgedFeesHistory;  

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

    uint constant MAX_UINT = 2**256 - 1;

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < MAX_UINT) {
                require(allowed[_from][msg.sender] >= _amount);
                allowed[_from][msg.sender] -= _amount;
            }
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

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
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
    ) public constant returns (uint256 remaining) {
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

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
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

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
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

 
 
 

    
    
   function totalPledgedFees() public constant returns (uint) {
       return totalPledgedFeesAt(block.number);
   }

    
    
    
   function totalPledgedFeesAt(uint _blockNumber) public constant returns(uint) {

        
        
        
        
        
       if ((totalPledgedFeesHistory.length == 0)
           || (totalPledgedFeesHistory[0].fromBlock > _blockNumber)) {
           if (address(parentToken) != 0) {
               return parentToken.totalPledgedFeesAt(min(_blockNumber, parentSnapShotBlock));
           } else {
               return 0;
           }

        
       } else {
           return getValueAt(totalPledgedFeesHistory, _blockNumber);
       }
   }

 
 
 

    
    
   function pledgeFees(uint _value) public onlyController returns (bool) {
       uint curTotalFees = totalPledgedFees();
       require(curTotalFees + _value >= curTotalFees);  
       updateValueAtNow(totalPledgedFeesHistory, curTotalFees + _value);
       return true;
   }

    
    
   function reducePledgedFees(uint _value) public onlyController returns (bool) {
       uint curTotalFees = totalPledgedFees();
       require(curTotalFees >= _value);
       updateValueAtNow(totalPledgedFeesHistory, curTotalFees - _value);
       return true;
   }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
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
    ) public onlyController returns (bool) {
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
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
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

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
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

contract DestructibleMiniMeToken is MiniMeToken {

    address public terminator;

    constructor(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled,
        address _terminator
    ) public MiniMeToken(
        _tokenFactory,
        _parentToken,
        _parentSnapShotBlock,
        _tokenName,
        _decimalUnits,
        _tokenSymbol,
        _transfersEnabled
    ) {
        terminator = _terminator;
    }

    function recycle() public {
        require(msg.sender == terminator);
        selfdestruct(terminator);
    }
}

contract DestructibleMiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createDestructibleCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (DestructibleMiniMeToken) {
        DestructibleMiniMeToken newToken = new DestructibleMiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled,
            msg.sender
        );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

contract Ownable {
  
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
 
contract TokenListingManagerAdvanced is Ownable {

    address public constant NECTAR_TOKEN = 0xCc80C051057B774cD75067Dc48f8987C4Eb97A5e;
    address public constant TOKEN_FACTORY = 0x6EB97237B8bc26E8057793200207bB0a2A83C347;
    uint public constant MAX_CANDIDATES = 50;

    struct TokenProposal {
        uint startBlock;
        uint startTime;
        uint duration;
        address votingToken;
         
         
         
         
        uint criteria;
        uint extraData;
    }

    struct Delegate {
        address user;
        bytes32 storageHash;
        bool exists;
    }

    TokenProposal[] public tokenBatches;
    Delegate[] public allDelegates;
    mapping(address => uint) addressToDelegate;

    uint[] public yesVotes;
    address[] public consideredTokens;

    DestructibleMiniMeTokenFactory public tokenFactory;
    address public nectarToken;
    mapping(address => bool) public admins;
    mapping(address => bool) public isWinner;
    mapping(address => bool) public tokenExists;
    mapping(address => uint) public lastVote;

    mapping(address => address[]) public myVotes;
    mapping(address => address) public myDelegate;
    mapping(address => bool) public isDelegate;

    mapping(uint => mapping(address => uint256)) public votesSpentThisRound;

    modifier onlyAdmins() {
        require(isAdmin(msg.sender));
        _;
    }

    constructor(address _tokenFactory, address _nectarToken) public {
        tokenFactory = DestructibleMiniMeTokenFactory(_tokenFactory);
        nectarToken = _nectarToken;
        admins[msg.sender] = true;
        isDelegate[address(0)] = true;
    }

     
     
     
     
     
     
    function startTokenVotes(address[] _tokens, uint _duration, uint _criteria, uint _extraData, address[] _previousWinners) public onlyAdmins {
        require(_tokens.length <= MAX_CANDIDATES);

        for (uint i=0; i < _previousWinners.length; i++) {
            isWinner[_previousWinners[i]] = true;
        }

        if (_criteria == 1) {
             
            require(_extraData < consideredTokens.length);
        }

        uint _proposalId = tokenBatches.length;
        if (_proposalId > 0) {
            TokenProposal memory op = tokenBatches[_proposalId - 1];
            DestructibleMiniMeToken(op.votingToken).recycle();
        }
        tokenBatches.length++;
        TokenProposal storage p = tokenBatches[_proposalId];
        p.duration = _duration * (1 days);

        for (i = 0; i < _tokens.length; i++) {
            require(!tokenExists[_tokens[i]]);

            consideredTokens.push(_tokens[i]);
            yesVotes.push(0);
            lastVote[_tokens[i]] = _proposalId;
            tokenExists[_tokens[i]] = true;
        }

        p.votingToken = tokenFactory.createDestructibleCloneToken(
                nectarToken,
                getBlockNumber(),
                appendUintToString("EfxTokenVotes-", _proposalId),
                MiniMeToken(nectarToken).decimals(),
                appendUintToString("EVT-", _proposalId),
                true);

        p.startTime = now;
        p.startBlock = getBlockNumber();
        p.criteria = _criteria;
        p.extraData = _extraData;

        emit NewTokens(_proposalId);
    }

     
     
     
    function vote(uint _tokenIndex, uint _amount) public {
        require(myDelegate[msg.sender] == address(0));
        require(!isWinner[consideredTokens[_tokenIndex]]);

         
        require(tokenBatches.length > 0);
        uint _proposalId = tokenBatches.length - 1;

        require(isActive(_proposalId));

        TokenProposal memory p = tokenBatches[_proposalId];

        if (lastVote[consideredTokens[_tokenIndex]] < _proposalId) {
             
             
            yesVotes[_tokenIndex] /= 2*(_proposalId - lastVote[consideredTokens[_tokenIndex]]);
            lastVote[consideredTokens[_tokenIndex]] = _proposalId;
        }

        uint balance = DestructibleMiniMeToken(p.votingToken).balanceOf(msg.sender);

         
        if (isDelegate[msg.sender]) {
            for (uint i=0; i < myVotes[msg.sender].length; i++) {
                address user = myVotes[msg.sender][i];
                balance += DestructibleMiniMeToken(p.votingToken).balanceOf(user);
            }
        }

        require(_amount <= balance);
        require(votesSpentThisRound[_proposalId][msg.sender] + _amount <= balance);

        yesVotes[_tokenIndex] += _amount;
         
        votesSpentThisRound[_proposalId][msg.sender] += _amount;

        emit Vote(_proposalId, msg.sender, consideredTokens[_tokenIndex], _amount);
    }

    function unregisterAsDelegate() public {
        require(isDelegate[msg.sender]);

        address lastDelegate = allDelegates[allDelegates.length - 1].user;
        uint currDelegatePos = addressToDelegate[msg.sender];
         
        addressToDelegate[lastDelegate] = currDelegatePos;
        allDelegates[currDelegatePos] = allDelegates[allDelegates.length - 1];

         
        delete allDelegates[allDelegates.length - 1];
        allDelegates.length--;

         
        isDelegate[msg.sender] = false;
    }

    function registerAsDelegate(bytes32 _storageHash) public {
         
        require(!gaveVote(msg.sender));
         
        require(myDelegate[msg.sender] == address(0));
         
        require(!isDelegate[msg.sender]);

        isDelegate[msg.sender] = true;
        allDelegates.push(Delegate({
            user: msg.sender,
            storageHash: _storageHash,
            exists: true
        }));

        addressToDelegate[msg.sender] = allDelegates.length-1;
    }

    function undelegateVote() public {
         
        require(!gaveVote(msg.sender));
         
        require(myDelegate[msg.sender] != address(0));

        address delegate = myDelegate[msg.sender];

        for (uint i=0; i < myVotes[delegate].length; i++) {
            if (myVotes[delegate][i] == msg.sender) {
                myVotes[delegate][i] = myVotes[delegate][myVotes[delegate].length-1];

                delete myVotes[delegate][myVotes[delegate].length-1];
                myVotes[delegate].length--;

                break;
            }
        }

        myDelegate[msg.sender] = address(0);
    }

     
     
    function delegateVote(address _to) public {
         
        require(!gaveVote(msg.sender));
         
        require(!isDelegate[msg.sender]);
         
        require(isDelegate[_to]);
         
        require(myDelegate[msg.sender] == address(0));

        myDelegate[msg.sender] = _to;
        myVotes[_to].push(msg.sender);
    }

    function delegateCount() public view returns(uint) {
        return allDelegates.length;
    }

    function getWinners() public view returns(address[] winners) {
        require(tokenBatches.length > 0);
        uint _proposalId = tokenBatches.length - 1;

        TokenProposal memory p = tokenBatches[_proposalId];

         
        if (p.criteria == 0) {
            winners = new address[](1);
            uint max = 0;

            for (uint i=0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }

                if (isWinner[consideredTokens[max]]) {
                    max = i;
                }

                if (getCurrentVotes(i) > getCurrentVotes(max)) {
                    max = i;
                }
            }

            winners[0] = consideredTokens[max];
        }

         
        if (p.criteria == 1) {
            uint count = 0;
            uint[] memory indexesWithMostVotes = new uint[](p.extraData);
            winners = new address[](p.extraData);

             
             
            for (i = 0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }
                if (count < p.extraData) {
                    indexesWithMostVotes[count] = i;
                    count++;
                    continue;
                }

                 
                if (count == p.extraData) {
                    for (j = 0; j < indexesWithMostVotes.length; j++) {
                        for (uint k = j+1; k < indexesWithMostVotes.length; k++) {
                            if (getCurrentVotes(indexesWithMostVotes[j]) < getCurrentVotes(indexesWithMostVotes[k])) {
                                uint help = indexesWithMostVotes[j];
                                indexesWithMostVotes[j] = indexesWithMostVotes[k];
                                indexesWithMostVotes[k] = help;
                            }
                        }
                    }
                }

                uint last = p.extraData - 1;
                if (getCurrentVotes(i) > getCurrentVotes(indexesWithMostVotes[last])) {
                    indexesWithMostVotes[last] = i;

                    for (uint j=last; j > 0; j--) {
                        if (getCurrentVotes(indexesWithMostVotes[j]) > getCurrentVotes(indexesWithMostVotes[j-1])) {
                            help = indexesWithMostVotes[j];
                            indexesWithMostVotes[j] = indexesWithMostVotes[j-1];
                            indexesWithMostVotes[j-1] = help;
                        }
                    }
                }
            }

            for (i = 0; i < p.extraData; i++) {
                winners[i] = consideredTokens[indexesWithMostVotes[i]];
            }
        }

         
        if (p.criteria == 2) {
            uint numOfTokens = 0;
            for (i = 0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }
                if (getCurrentVotes(i) > p.extraData) {
                    numOfTokens++;
                }
            }

            winners = new address[](numOfTokens);
            count = 0;
            for (i = 0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }
                if (getCurrentVotes(i) > p.extraData) {
                    winners[count] = consideredTokens[i];
                    count++;
                }
            }
        }
    }

     
    function numberOfProposals() public view returns(uint) {
        return tokenBatches.length;
    }

     
     
    function addAdmin(address _newAdmin) public onlyAdmins {
        admins[_newAdmin] = true;
    }

     
     
    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;
    }

     
     
    function proposal(uint _proposalId) public view returns(
        uint _startBlock,
        uint _startTime,
        uint _duration,
        bool _active,
        bool _finalized,
        uint[] _votes,
        address[] _tokens,
        address _votingToken,
        bool _hasBalance
    ) {
        require(_proposalId < tokenBatches.length);

        TokenProposal memory p = tokenBatches[_proposalId];
        _startBlock = p.startBlock;
        _startTime = p.startTime;
        _duration = p.duration;
        _finalized = (_startTime+_duration < now);
        _active = isActive(_proposalId);
        _votes = getVotes();
        _tokens = getConsideredTokens();
        _votingToken = p.votingToken;
        _hasBalance = (p.votingToken == 0x0) ? false : (DestructibleMiniMeToken(p.votingToken).balanceOf(msg.sender) > 0);
    }

    function getConsideredTokens() public view returns(address[] tokens) {
        tokens = new address[](consideredTokens.length);

        for (uint i = 0; i < consideredTokens.length; i++) {
            if (!isWinner[consideredTokens[i]]) {
                tokens[i] = consideredTokens[i];
            } else {
                tokens[i] = address(0);
            }
        }
    }

    function getVotes() public view returns(uint[] votes) {
        votes = new uint[](consideredTokens.length);

        for (uint i = 0; i < consideredTokens.length; i++) {
            votes[i] = getCurrentVotes(i);
        }
    }

    function getCurrentVotes(uint index) public view returns(uint) {
        require(tokenBatches.length > 0);

        uint _proposalId = tokenBatches.length - 1;
        uint vote = yesVotes[index];
        if (_proposalId > lastVote[consideredTokens[index]]) {
            vote = yesVotes[index] / (2 * (_proposalId - lastVote[consideredTokens[index]]));
        }

        return vote;
    }

    function isAdmin(address _admin) public view returns(bool) {
        return admins[_admin];
    }

    function proxyPayment(address ) public payable returns(bool) {
        return false;
    }

     
    function onTransfer(address _from, address _to, uint _amount) public view returns(bool) {
        return !gaveVote(_from);
    }

    function onApprove(address, address, uint ) public pure returns(bool) {
        return true;
    }

    function gaveVote(address _user) public view returns(bool) {
        if (tokenBatches.length == 0) return false;

        uint _proposalId = tokenBatches.length - 1;

        if (votesSpentThisRound[_proposalId][myDelegate[_user]] + votesSpentThisRound[_proposalId][_user] > 0 ) {
            return true;
        } else {
            return false;
        }
    }

    function getBlockNumber() internal constant returns (uint) {
        return block.number;
    }

    function isActive(uint id) internal view returns (bool) {
        TokenProposal memory p = tokenBatches[id];
        bool _finalized = (p.startTime + p.duration < now);
        return !_finalized && (p.startBlock < getBlockNumber());
    }

    function appendUintToString(string inStr, uint v) private pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        if (v == 0) {
            reversed[i++] = byte(48);
        } else {
            while (v != 0) {
                uint remainder = v % 10;
                v = v / 10;
                reversed[i++] = byte(48 + remainder);
            }
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    event Vote(uint indexed idProposal, address indexed _voter, address chosenToken, uint amount);
    event NewTokens(uint indexed idProposal);
}