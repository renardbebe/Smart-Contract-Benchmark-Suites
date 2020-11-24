 

pragma solidity ^0.4.15;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
contract Owned {
    address public owner;
    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

contract Mortal is Owned {
     
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

 
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

 
 
 
contract Random is SafeMath {
     
    function getRand(uint blockNumber, uint max)
    public
    constant 
    returns(uint) {
         
         
        return(safeAdd(uint(sha3(block.blockhash(blockNumber))) % max, 1));
    }
}

 
 
 
 
 
 
contract LuckyNumber is Owned {
     
    uint256 public cost;
     
    uint8 public waitTime;
     
    uint256 public max;

     
    struct PendingNumber {
        address proxy;
        uint256 renderedNumber;
        uint256 creationBlockNumber;
        uint256 max;
         
         
         
        uint8 waitTime;
    }

     
    event EventLuckyNumberUpdated(uint256 cost, uint256 max, uint8 waitTime);
     
    event EventLuckyNumberRequested(address requestor, uint256 max, uint256 creationBlockNumber, uint8 waitTime);
    event EventLuckyNumberRevealed(address requestor, uint256 max, uint256 renderedNumber);
    
    mapping (address => PendingNumber) public pendingNumbers;
    mapping (address => bool) public whiteList;

    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime) payable public;
    function revealNumber(address _requestor) payable public;
}

 
contract LuckyNumberImp is LuckyNumber, Mortal, Random {
    
     
    function LuckyNumberImp() {
        owned();
         
        cost = 20000000000000000;  
        max = 15;  
        waitTime = 3;  
    }

     
     
     
    function enableProxy(address _proxy)
    onlyOwner
    public
    returns (bool) {
         
        whiteList[_proxy] = true;
        return whiteList[_proxy];
    }

    function removeProxy(address _proxy)
    onlyOwner
    public
    returns (bool) {
        delete whiteList[_proxy];
        return true;
    }

     
    function setMax(uint256 _max)
    onlyOwner
    public
    returns (bool) {
        max = _max;
        EventLuckyNumberUpdated(cost, max, waitTime);
        return true;
    }

     
    function setWaitTime(uint8 _waitTime)
    onlyOwner
    public
    returns (bool) {
        waitTime = _waitTime;
        EventLuckyNumberUpdated(cost, max, waitTime);
        return true;
    }

     
    function setCost(uint256 _cost)
    onlyOwner
    public
    returns (bool) {
        cost = _cost;
        EventLuckyNumberUpdated(cost, max, waitTime);
        return true;
    }
    
     
    function withdraw(address _recipient, uint256 _balance)
    onlyOwner
    public
    returns (bool) {
        _recipient.transfer(_balance);
        return true;
    }

     
     
    function () payable public {
        if (msg.sender != owner) {
            requestNumber(msg.sender, max, waitTime);
        }
    }
    
     
    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime)
    payable 
    public {
         
         
         
        if (!whiteList[msg.sender]) {
            require(!(msg.value < cost));
        }

         
         
        assert(!checkNumber(_requestor));
         
        pendingNumbers[_requestor] = PendingNumber({
            proxy: tx.origin,
            renderedNumber: 0,
            max: max,
            creationBlockNumber: block.number,
            waitTime: waitTime
        });
        if (_max > 1) {
            pendingNumbers[_requestor].max = _max;
        }
         
         
         
         
        if (_waitTime > 0 && _waitTime < 250) {
            pendingNumbers[_requestor].waitTime = _waitTime;
        }
        EventLuckyNumberRequested(_requestor, pendingNumbers[_requestor].max, pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].waitTime);
    }

     
    function revealNumber(address _requestor)
    public
    payable {
        assert(_canReveal(_requestor, msg.sender));
        _revealNumber(_requestor);
    }

     
    function _revealNumber(address _requestor) 
    internal {
         
        uint256 luckyBlock = _revealBlock(_requestor);
         
         
         
         
         
        uint256 luckyNumber = getRand(luckyBlock, pendingNumbers[_requestor].max);

         
        pendingNumbers[_requestor].renderedNumber = luckyNumber;
         
        EventLuckyNumberRevealed(_requestor, pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].renderedNumber);
         
        pendingNumbers[_requestor].waitTime = 0;
         
        pendingNumbers[_requestor].creationBlockNumber = 0;
    }

    function canReveal(address _requestor)
    public
    constant
    returns (bool, uint, uint, address, address) {
        return (_canReveal(_requestor, msg.sender), _remainingBlocks(_requestor), _revealBlock(_requestor), _requestor, msg.sender);
    }

    function _canReveal(address _requestor, address _proxy) 
    internal
    constant
    returns (bool) {
         
        if (checkNumber(_requestor)) {
             
             
            if (_remainingBlocks(_requestor) == 0) {
                 
                if (pendingNumbers[_requestor].proxy == _requestor || pendingNumbers[_requestor].proxy == _proxy) {
                    return true;
                }
            }
        }
        return false;
    }

    function _remainingBlocks(address _requestor)
    internal
    constant
    returns (uint) {
        uint256 revealBlock = safeAdd(pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].waitTime);
        uint256 remainingBlocks = 0;
        if (revealBlock > block.number) {
            remainingBlocks = safeSubtract(revealBlock, block.number);
        }
        return remainingBlocks;
    }

    function _revealBlock(address _requestor)
    internal
    constant
    returns (uint) {
         
         
         
        return safeAdd(pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].waitTime);
    }


    function getNumber(address _requestor)
    public
    constant
    returns (uint, uint, uint, address) {
        return (pendingNumbers[_requestor].renderedNumber, pendingNumbers[_requestor].max, pendingNumbers[_requestor].creationBlockNumber, _requestor);
    }

     
     
     
     
    function checkNumber(address _requestor)
    public
    constant
    returns (bool) {
        if (pendingNumbers[_requestor].renderedNumber == 0 && pendingNumbers[_requestor].waitTime > 0) {
            return true;
        }
        return false;
    }
 
}