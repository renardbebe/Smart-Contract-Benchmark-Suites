 

pragma solidity ^0.4.11; 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
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
  function mul(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Random is SafeMath {
     
    function getRandomFromBlockHash(uint blockNumber, uint max)
    public
    constant 
    returns(uint) {
         
         
         
         
         
        return(add(uint(sha3(block.blockhash(blockNumber))) % max, 1));
    }
}

 
contract LuckyNumber is Owned {
     
    uint256 public cost;
     
    uint8 public waitTime;
     
    uint256 public max;

     
    struct PendingNumber {
        address requestProxy;
        uint256 renderedNumber;
        uint256 originBlock;
        uint256 max;
         
         
         
        uint8 waitTime;
    }

     
    event EventLuckyNumberRequested(address indexed requestor, uint256 max, uint256 originBlock, uint8 waitTime, address indexed requestProxy);
    event EventLuckyNumberRevealed(address indexed requestor, uint256 originBlock, uint256 renderedNumber, address indexed requestProxy);
    
    mapping (address => PendingNumber) public pendingNumbers;
    mapping (address => bool) public whiteList;

    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime) payable public;
    function revealNumber(address _requestor) payable public;
}

 
contract LuckyNumberService is LuckyNumber, Mortal, Random {
    
     
    function LuckyNumberService() {
        owned();
         
        cost = 20000000000000000;  
        max = 15;  
        waitTime = 3;  
    }

     
     
    function setMax(uint256 _max)
    onlyOwner
    public
    returns (bool) {
        max = _max;
        return true;
    }

     
    function setWaitTime(uint8 _waitTime)
    onlyOwner
    public
    returns (bool) {
        waitTime = _waitTime;
        return true;
    }

     
    function setCost(uint256 _cost)
    onlyOwner
    public
    returns (bool) {
        cost = _cost;
        return true;
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

     
    function withdraw(address _recipient, uint256 _balance)
    onlyOwner
    public
    returns (bool) {
        _recipient.transfer(_balance);
        return true;
    }

     
     
    function () payable public {
        assert(msg.sender != owner);
        requestNumber(msg.sender, max, waitTime);
    }
    
     
    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime)
    payable 
    public {
         
         
         
        if (!whiteList[msg.sender]) {
            require(!(msg.value < cost));
        }

         
         
        assert(!checkNumber(_requestor));
         
        pendingNumbers[_requestor] = PendingNumber({
            requestProxy: tx.origin,  
            renderedNumber: 0,
            max: max,
            originBlock: block.number,
            waitTime: waitTime
        });
        if (_max > 1) {
            pendingNumbers[_requestor].max = _max;
        }
         
         
         
         
        if (_waitTime > 0 && _waitTime < 250) {
            pendingNumbers[_requestor].waitTime = _waitTime;
        }
        EventLuckyNumberRequested(_requestor, pendingNumbers[_requestor].max, pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].waitTime, pendingNumbers[_requestor].requestProxy);
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
         
         
         
         
         
        uint256 luckyNumber = getRandomFromBlockHash(luckyBlock, pendingNumbers[_requestor].max);

         
        pendingNumbers[_requestor].renderedNumber = luckyNumber;
         
        EventLuckyNumberRevealed(_requestor, pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].renderedNumber, pendingNumbers[_requestor].requestProxy);
         
        pendingNumbers[_requestor].waitTime = 0;
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
                 
                if (pendingNumbers[_requestor].requestProxy == _requestor || pendingNumbers[_requestor].requestProxy == _proxy) {
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
        uint256 revealBlock = add(pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].waitTime);
        uint256 remainingBlocks = 0;
        if (revealBlock > block.number) {
            remainingBlocks = sub(revealBlock, block.number);
        }
        return remainingBlocks;
    }

    function _revealBlock(address _requestor)
    internal
    constant
    returns (uint) {
         
         
         
        return add(pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].waitTime);
    }


    function getNumber(address _requestor)
    public
    constant
    returns (uint, uint, uint, address) {
        return (pendingNumbers[_requestor].renderedNumber, pendingNumbers[_requestor].max, pendingNumbers[_requestor].originBlock, _requestor);
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