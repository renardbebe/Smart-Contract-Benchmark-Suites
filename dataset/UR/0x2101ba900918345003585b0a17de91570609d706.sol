 

pragma solidity ^0.4.11;

 

 
 

contract ERC20Token {
	function totalSupply() constant returns (uint supply);

	 
	 
	function balanceOf(address _owner) constant returns (uint256 balance);

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) returns (bool success);

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

	 
	 
	 
	 
	function approve(address _spender, uint256 _value) returns (bool success);

	 
	 
	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

pragma solidity ^0.4.11;

 

 
 
 
 
 
 
 


 
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

 
 
 
contract MiniMeToken is Controlled, ERC20Token {

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
        creationBlock = block.number;
    }


 
 
 

	 
	modifier onlyPayloadSize(uint size) {
		if(msg.data.length != size + 4) {
		throw;
		}
		_;
	}

	 
	 
	 
	 
	function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) returns (bool success) {
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

           if (parentSnapShotBlock >= block.number) throw;

            
           if ((_to == 0) || (_to == address(this))) throw;

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               if (!TokenController(controller).onTransfer(_from, _to, _amount))
               throw;
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           if (previousBalanceTo + _amount < previousBalanceTo) throw;  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
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
        ) onlyController returns(address) {
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

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
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
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
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
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
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


	 
	 
	 
	event Transfer(address indexed _from, address indexed _to, uint256 _amount);
	event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

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

 
 


contract ClitCoinToken is MiniMeToken {


	function ClitCoinToken(
		 
	) MiniMeToken(
		0x0,
		0x0,             
		0,               
		"CLIT Token", 	 
		0,               
		"CLIT",          
		false             
	) {
		version = "CLIT 1.0";
	}


}

 
contract SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
}


contract ClitCrowdFunder is Controlled, SafeMath {

	address public creator;
    address public fundRecipient;
	
	 
    State public state = State.Fundraising;  
    uint public fundingGoal; 
	uint public totalRaised;
	uint public currentBalance;
	uint public issuedTokenBalance;
	uint public totalTokensIssued;
	uint public capTokenAmount;
	uint public startBlockNumber;
	uint public endBlockNumber;
	uint public eolBlockNumber;
	
	uint public firstExchangeRatePeriod;
	uint public secondExchangeRatePeriod;
	uint public thirdExchangeRatePeriod;
	uint public fourthExchangeRatePeriod;
	
	uint public firstTokenExchangeRate;
	uint public secondTokenExchangeRate;
	uint public thirdTokenExchangeRate;
	uint public fourthTokenExchangeRate;
	uint public finalTokenExchangeRate;	
	
	bool public fundingGoalReached;
	
    ClitCoinToken public exchangeToken;
	
	 
	event HardCapReached(address fundRecipient, uint amountRaised);
	event GoalReached(address fundRecipient, uint amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution);	
	event FrozenFunds(address target, bool frozen);
	event RefundPeriodStarted();

	 
	mapping(address => uint256) private balanceOf;
	mapping (address => bool) private frozenAccount;
	
	 
    enum State {
		Fundraising,
		ExpiredRefund,
		Successful,
		Closed
	}
	
	 

	modifier inState(State _state) {
        if (state != _state) throw;
        _;
    }
	
	 
	modifier atEndOfLifecycle() {
        if(!((state == State.ExpiredRefund && block.number > eolBlockNumber) || state == State.Successful)) {
            throw;
        }
        _;
    }
	
	modifier accountNotFrozen() {
        if (frozenAccount[msg.sender] == true) throw;
        _;
    }
	
    modifier minInvestment() {
       
      require(msg.value >= 10 ** 16);
      _;
    }
	
	modifier isStarted() {
		require(block.number >= startBlockNumber);
		_;
	}

	 
	function ClitCrowdFunder(
		address _fundRecipient,
		uint _delayStartHours,
		ClitCoinToken _addressOfExchangeToken
	) {
		creator = msg.sender;
		
		fundRecipient = _fundRecipient;
		fundingGoal = 7000 * 1 ether;
		capTokenAmount = 140 * 10 ** 6;
		state = State.Fundraising;
		fundingGoalReached = false;
		
		totalRaised = 0;
		currentBalance = 0;
		totalTokensIssued = 0;
		issuedTokenBalance = 0;
		
		startBlockNumber = block.number + div(mul(3600, _delayStartHours), 14);
		endBlockNumber = startBlockNumber + div(mul(3600, 1080), 14);  
		eolBlockNumber = endBlockNumber + div(mul(3600, 168), 14);   

		firstExchangeRatePeriod = startBlockNumber + div(mul(3600, 24), 14);    
		secondExchangeRatePeriod = firstExchangeRatePeriod + div(mul(3600, 240), 14);  
		thirdExchangeRatePeriod = secondExchangeRatePeriod + div(mul(3600, 240), 14);  
		fourthExchangeRatePeriod = thirdExchangeRatePeriod + div(mul(3600, 240), 14);  
		
		uint _tokenExchangeRate = 1000;
		firstTokenExchangeRate = (_tokenExchangeRate + 1000);	
		secondTokenExchangeRate = (_tokenExchangeRate + 500);
		thirdTokenExchangeRate = (_tokenExchangeRate + 300);
		fourthTokenExchangeRate = (_tokenExchangeRate + 100);
		finalTokenExchangeRate = _tokenExchangeRate;
		
		exchangeToken = ClitCoinToken(_addressOfExchangeToken);
	}
	
	function freezeAccount(address target, bool freeze) onlyController {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }	
	
	function getCurrentExchangeRate(uint amount) public constant returns(uint) {
		if (block.number <= firstExchangeRatePeriod) {
			return firstTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= secondExchangeRatePeriod) {
			return secondTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= thirdExchangeRatePeriod) {
			return thirdTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= fourthExchangeRatePeriod) {
			return fourthTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= endBlockNumber) {
			return finalTokenExchangeRate * amount / 1 ether;
		}
		
		return finalTokenExchangeRate * amount / 1 ether;
	}

	function investment() public inState(State.Fundraising) isStarted accountNotFrozen minInvestment payable returns(uint)  {
		
		uint amount = msg.value;
		if (amount == 0) throw;
		
		balanceOf[msg.sender] += amount;	
		
		totalRaised += amount;
		currentBalance += amount;
						
		uint tokenAmount = getCurrentExchangeRate(amount);
		exchangeToken.generateTokens(msg.sender, tokenAmount);
		totalTokensIssued += tokenAmount;
		issuedTokenBalance += tokenAmount;
		
		FundTransfer(msg.sender, amount, true); 
		
		checkIfFundingCompleteOrExpired();
		
		return balanceOf[msg.sender];
	}

	function checkIfFundingCompleteOrExpired() {
		if (block.number > endBlockNumber || totalTokensIssued >= capTokenAmount ) {
			 
			if (currentBalance > fundingGoal || fundingGoalReached == true) {
				state = State.Successful;
				payOut();
				
				HardCapReached(fundRecipient, totalRaised);
				
				 
				removeContract();

			} else  {
				state = State.ExpiredRefund;  
				
				RefundPeriodStarted();
			}
		} else if (currentBalance > fundingGoal && fundingGoalReached == false) {
			 
			fundingGoalReached = true;
			
			state = State.Successful;
			payOut();
			
			 
			state = State.Fundraising;
			
			 
			GoalReached(fundRecipient, totalRaised);
		}
	}

	function payOut() public inState(State.Successful) {
		 
		var amount = currentBalance;
		currentBalance = 0;

		fundRecipient.transfer(amount);
		
		 
		var tokenCount = issuedTokenBalance;
		issuedTokenBalance = 0;
		
		exchangeToken.generateTokens(fundRecipient, tokenCount);		
	}

	function getRefund() public inState(State.ExpiredRefund) {	
		uint amountToRefund = balanceOf[msg.sender];
		balanceOf[msg.sender] = 0;
		
		 
		msg.sender.transfer(amountToRefund);
		currentBalance -= amountToRefund;
		
		FundTransfer(msg.sender, amountToRefund, false);
	}
	
	function removeContract() public atEndOfLifecycle {		
		state = State.Closed;
		
		 
		exchangeToken.enableTransfers(true);
		
		 
		exchangeToken.changeController(controller);

		selfdestruct(msg.sender);
	}
	
	 
	function () payable { 
		investment(); 
	}	

}