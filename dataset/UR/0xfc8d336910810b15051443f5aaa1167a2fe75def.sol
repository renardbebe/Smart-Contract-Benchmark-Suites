 

 
 
pragma solidity ^0.5.10;

contract SafeMath {
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(int a, int b) internal pure returns (int) {
        if (b < 0) assert(a - b > a);
        else assert(a - b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

contract ERC20Token {
    function transfer(address receiver, uint amount) public returns (bool) {
        (receiver);
        (amount);
        return false;
    }

    function balanceOf(address holder) public returns (uint) {
        (holder);
        return 0;
    }
}

contract Casino {
    mapping(address => bool) public authorized;
}

contract Owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor() internal {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}

contract BankWallet is SafeMath, Owned {
    Casino public edgelessCasino;
    
    mapping(address => uint) public tokenToLimit; 
    
    bool public paused = false;

    event Transfer(address _token, address _receiver, uint _amount);
    event Withdrawal(address _token, address _receiver, uint _amount);
    event Paused(bool _paused);

    constructor(address _casino) public {
        edgelessCasino = Casino(_casino);
        owner = msg.sender;
    }

     
    function () external payable {}
    
     
    function transfer(address _token, address _receiver, uint _amount) public onlyActive onlyAuthorized returns (bool _success) {
        require(tokenToLimit[_token] == 0 || tokenToLimit[_token] >= _amount, "Amount exceeds transfer limit for asset.");
        _success = _transfer(_token, _receiver, _amount);
        if (_success) {
            emit Transfer(_token, _receiver, _amount);
        }
    }

     
    function adminTransfer(address _token, address _receiver, uint _amount) public onlyOwner returns (bool _success) {
        _success = _transfer(_token, _receiver, _amount);
        if (_success) {
            emit Withdrawal(_token, _receiver, _amount);
        }
    }
    
      
    function _transfer(address _token, address _receiver, uint _amount) internal returns (bool _success) {
        require(_receiver != address(0), "Please use valid receiver wallet address.");
        _success = false;
        if (_token == address (0)) {
            require(_amount <= address(this).balance, "Eth balance is too small.");
            assert(_success = address(uint160(_receiver)).send(_amount));
        } else {
            ERC20Token __token = ERC20Token(_token);
            require(_amount <= __token.balanceOf(address(this)), "Asset balance is too small.");
            _success = __token.transfer(_receiver, _amount);
        }
    }
    
     
    function setTokenLimit(address _token, uint _limit) public onlyOwner {
        tokenToLimit[_token] = _limit;
    }
    
      
    function pause() public onlyActive onlyAuthorized {
        paused = true;
        emit Paused(paused);
    }

      
    function activate() public onlyPaused onlyOwner {
        paused = false;
        emit Paused(paused);
    }
    
    modifier onlyAuthorized {
        require(edgelessCasino.authorized(msg.sender), "Sender is not authorized.");
        _;
    }
    
    modifier onlyPaused {
        require(paused == true, "Contract is not paused.");
        _;
    }

    modifier onlyActive {
        require(paused == false, "Contract is paused.");
        _;
    }
}