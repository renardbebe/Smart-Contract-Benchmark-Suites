 

pragma solidity 0.5.8; 

 
contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }
}

 
contract Owned {
    address public owner = msg.sender;

    modifier isOwner {
        assert(msg.sender == owner); _;
    }

    function changeOwner(address account) external isOwner {
        owner = account;
    }
}

 
contract Authorized is Owned {
    mapping(address => bool) public authorized;

    modifier isAuthorized {
        assert(authorized[msg.sender] == true); _;
    }

    function authorizeAccount(address account) external isOwner {
        authorized[account] = true;
    }

    function unauthorizeAccount(address account) external isOwner {
        authorized[account] = false;
    }
}

 
contract TimeRelease is Owned {
    uint256 public releaseTime = 0;
    
    function changeReleaseTime(uint256 time) external isOwner {
        releaseTime = time;
    }
}

 
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused;

    modifier pausable {
        assert(!paused); _;
    }

    function pause() external isOwner {
        paused = true;

        emit Pause();
    }

    function unpause() external isOwner {
        paused = false;

        emit Unpause();
    }
}

 
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

 
contract ERC20 is ERC20Events {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint);

    function approve(address spender, uint amount) public returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(
        address from, address to, uint amount
    ) public returns (bool);
}

 
contract SingleTokenBank is Owned, Pausable, TimeRelease, Authorized, DSMath {
    struct Withdrawal {
        uint256 amount;
        uint256 timestamp;
    }

    ERC20 public token;
    uint256 public maxWithdrawal = 0;
    uint256 public maxDeposit = 0;
    uint256 public totalPlayerBalance;
    mapping(address => uint256) public balances;
    mapping(address => Withdrawal) public withdrawals;

	 
	event Deposit(address _player, uint256 _amount);

	 
	event WithdrawalEvent(address _player, uint256 _amount);
	
	 
	event WithdrawalSet(address _player, uint256 _amount);
	
	 
	event BalancesChanged(uint256 _totalPlayerBalance);
	
	 
	event MaxWithdrawalChange(uint256 _maxWithdrawal);
	
	 
	event MaxDepositChange(uint256 _maxDeposit);

	constructor(address _token, address _authorized, address _owner) public {
	   token = ERC20(_token);
	   owner = _owner;  
	   authorized[_authorized] = true;  
	   authorized[owner] = true;  
	}

	function deposit(uint256 _amount) external pausable {
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(_amount > 0);
        require(_amount <= allowance);
        require(_amount <= maxDeposit);
        require(token.transferFrom(msg.sender, address(this), _amount));
        balances[msg.sender] = add(balances[msg.sender], _amount);
        emit Deposit(msg.sender, allowance);
	}

     
	function changeBalances(address[] calldata _player, uint256[] calldata  _amount, uint256 _totalPlayerBalance) external pausable isAuthorized {
		for (uint256 i = 0; i < _player.length; i++) {
		    balances[_player[i]] = _amount[i];
		}
		
		totalPlayerBalance = _totalPlayerBalance;
		emit BalancesChanged(_totalPlayerBalance);
	}
    
	 
	function bankroll() view public returns(uint) {
		return sub(token.balanceOf(address(this)), totalPlayerBalance);
	}

     
	function setUserWithdrawal(address _player, uint256 _amount) external pausable isAuthorized {
	    require(_amount <= maxWithdrawal);  
        require(add(withdrawals[_player].amount, _amount) <= maxWithdrawal);
        withdrawals[_player].amount = add(withdrawals[_player].amount, _amount);
        withdrawals[_player].timestamp = block.timestamp;
        emit WithdrawalSet(_player, _amount);
	}

         
	function setOwnerWithdrawal(address _player, uint256 _totalPlayerBalance, uint256 _amount) external pausable isAuthorized {
        totalPlayerBalance = _totalPlayerBalance;
        withdrawals[_player].amount = add(withdrawals[_player].amount, _amount);
        withdrawals[_player].timestamp = block.timestamp;
		emit BalancesChanged(_amount);
        emit WithdrawalSet(_player, _amount);
	}

	function withdraw(uint256 _amount) external pausable {
        require(_amount <= withdrawals[msg.sender].amount);
        require(_amount <= maxWithdrawal);
        require(block.timestamp >= add(withdrawals[msg.sender].timestamp, releaseTime));
        
		balances[msg.sender] = sub(balances[msg.sender], _amount);
		withdrawals[msg.sender].amount = sub(withdrawals[msg.sender].amount, _amount);
		
		require(token.transfer(msg.sender, _amount));
		emit WithdrawalEvent(msg.sender, _amount);
	}

	function changeMaxDeposit(uint256 _max) external pausable isOwner {
	    maxDeposit = _max;
	    emit MaxDepositChange(_max);
	}

	function changeMaxWithdrawal(uint256 _max) external pausable isOwner {
	    maxWithdrawal = _max;
	    emit MaxWithdrawalChange(_max);
	}

	function ownerWithdrawalEther(address payable _destination, uint256 _amount) external isOwner {
		_destination.transfer(_amount);
	}

	function ownerWithdrawalTokens(address _destination, uint256 _amount) external isOwner {
        require(_amount <= withdrawals[msg.sender].amount);
	    require((paused == false && _amount <= bankroll())  
	        || paused == true);  
		require(token.transfer(_destination, _amount));

		withdrawals[msg.sender].amount = sub(withdrawals[msg.sender].amount, _amount);
		emit WithdrawalEvent(address(this), _amount);
	}
}