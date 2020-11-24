 

pragma solidity ^0.4.13;
 
 

contract ERC20 {
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract Controlled {
    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    address public controller;

    function Controlled() {
        controller = msg.sender;
    }

    address public newController;

    function changeOwner(address _newController) onlyController {
        newController = _newController;
    }

    function acceptOwnership() {
        if (msg.sender == newController) {
            controller = newController;
        }
    }
}
contract DAOControlled is Controlled{
    address public dao;
    modifier onlyDAO{
        require(msg.sender == dao);
        _;
    }
    function setDAO(address _dao) onlyController{
        dao = _dao;
    }
}

contract MintableToken is ERC20, SafeMath, DAOControlled{
	mapping(address => uint) public balances;
	address[] public mintingFactories;
	uint public numFactories;
	function resetFactories() onlyController{
	    numFactories = 0;
	}
	function addMintingFactory(address _factory) onlyController{
	    mintingFactories.push(_factory);
	    numFactories += 1;
	}
	
	function removeMintingFactory(address _factory) onlyController{
	    for (uint i = 0; i < numFactories; i++){
	        if (_factory == mintingFactories[i])
	        {
	            mintingFactories[i] = 0;
	        }
	    }
	}
	
	modifier onlyFactory{
	    bool isFactory = false;
	    for (uint i = 0; i < numFactories; i++){
	        if (msg.sender == mintingFactories[i] && msg.sender != address(0))
	        {
	            isFactory = true;
	        }
	    }
	    if (!isFactory) throw;
	    _;
	}
}
contract CollectibleFeeToken is MintableToken{
	uint8 public decimals;
	mapping(uint => uint) public roundFees;
	mapping(uint => uint) public recordedCoinSupplyForRound;
	mapping(uint => mapping (address => uint)) public claimedFees;
	mapping(address => uint) public lastClaimedRound;
	uint public latestRound = 0;
	uint public initialRound = 1;
	uint public reserves;
    event Claimed(address indexed _owner, uint256 _amount);
    event Deposited(uint256 _amount, uint indexed round);
	
	modifier onlyPayloadSize(uint size) {
		if(msg.data.length != size + 4) {
		throw;
		}
		_;
	}
	
	function reduceReserves(uint value) onlyPayloadSize(1 * 32) onlyDAO{
	    reserves = safeSub(reserves, value);
	}
	
	function addReserves(uint value) onlyPayloadSize(1 * 32) onlyDAO{
	    reserves = safeAdd(reserves, value);
	}
	
	function depositFees(uint value) onlyDAO {
		latestRound += 1;
		Deposited(value, latestRound);
		recordedCoinSupplyForRound[latestRound] = totalSupply;
		roundFees[latestRound] = value;
	}
	function claimFees(address _owner) onlyPayloadSize(1 * 32) onlyDAO returns (uint totalFees) {
		totalFees = 0;
		for (uint i = lastClaimedRound[_owner] + 1; i <= latestRound; i++){
			uint feeForRound = balances[_owner] * feePerUnitOfCoin(i);
			if (feeForRound > claimedFees[i][_owner]){
				feeForRound = safeSub(feeForRound,claimedFees[i][_owner]);
			}
			else {
				feeForRound = 0;
			}
			claimedFees[i][_owner] = safeAdd(claimedFees[i][_owner], feeForRound);
			totalFees = safeAdd(totalFees, feeForRound);
		}
		lastClaimedRound[_owner] = latestRound;
		Claimed(_owner, feeForRound);
		return totalFees;
	}

	function claimFeesForRound(address _owner, uint round) onlyPayloadSize(2 * 32) onlyDAO returns (uint feeForRound) {
		feeForRound = balances[_owner] * feePerUnitOfCoin(round);
		if (feeForRound > claimedFees[round][_owner]){
			feeForRound = safeSub(feeForRound,claimedFees[round][_owner]);
		}
		else {
			feeForRound = 0;
		}
		claimedFees[round][_owner] = safeAdd(claimedFees[round][_owner], feeForRound);
		Claimed(_owner, feeForRound);
		return feeForRound;
	}

	function _resetTransferredCoinFees(address _owner, address _receipient, uint numCoins) internal returns (bool){
		for (uint i = lastClaimedRound[_owner] + 1; i <= latestRound; i++){
			uint feeForRound = balances[_owner] * feePerUnitOfCoin(i);
			if (feeForRound > claimedFees[i][_owner]) {
				 
				uint unclaimedFees = min256(numCoins * feePerUnitOfCoin(i), safeSub(feeForRound, claimedFees[i][_owner]));
				reserves = safeAdd(reserves, unclaimedFees);
				claimedFees[i][_owner] = safeAdd(claimedFees[i][_owner], unclaimedFees);
			}
		}
		for (uint x = lastClaimedRound[_receipient] + 1; x <= latestRound; x++){
			 
			claimedFees[x][_receipient] = safeAdd(claimedFees[x][_receipient], numCoins * feePerUnitOfCoin(x));
		}
		return true;
	}
	function feePerUnitOfCoin(uint round) public constant returns (uint fee){
		return safeDiv(roundFees[round], recordedCoinSupplyForRound[round]);
	}
	
	function reservesPerUnitToken() public constant returns(uint) {
	    return reserves / totalSupply;
	}
	
   function mintTokens(address _owner, uint amount) onlyFactory{
        
       lastClaimedRound[msg.sender] = latestRound;
       totalSupply = safeAdd(totalSupply, amount);
       balances[_owner] += amount;
   }
}

contract BurnableToken is CollectibleFeeToken{

    event Burned(address indexed _owner, uint256 _value);
    function burn(address _owner, uint amount) onlyDAO returns (uint burnValue){
        require(balances[_owner] >= amount);
         
        require(latestRound == lastClaimedRound[_owner]);
        burnValue = reservesPerUnitToken() * amount;
        reserves = safeSub(reserves, burnValue);
        balances[_owner] = safeSub(balances[_owner], amount);
        totalSupply = safeSub(totalSupply, amount);
        Transfer(_owner, this, amount);
        Burned(_owner, amount);
        return burnValue;
    }
    
}
 
contract Haltable is Controlled {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyController {
    halted = true;
  }

   
  function unhalt() external onlyController onlyInEmergency {
    halted = false;
  }

}

 
contract SphereToken is BurnableToken, Haltable {
    
    string public name;                 
    string public symbol;               
    string public version = 'SPR_0.1';  
    bool public isTransferEnabled;
  mapping (address => mapping (address => uint)) allowed;

    function SphereToken(){
        name = 'EtherSphere';
        symbol = 'SPR';
        decimals = 4;
        isTransferEnabled = false;
    }
   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       throw;
     }
     _;
  }

    function setTransferEnable(bool enabled) onlyDAO{
        isTransferEnabled = enabled;
    }
    function doTransfer(address _from, address _to, uint _value) private returns (bool success){
        if (_value > balances[_from] || !isTransferEnabled) return false;
        if (!_resetTransferredCoinFees(_from, _to, _value)) return false;
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) stopInEmergency returns (bool success) {
    return doTransfer(msg.sender, _to, _value);
  }

  function exchangeTransfer(address _to, uint _value) stopInEmergency onlyFactory returns (bool success) {
        if (_value > balances[msg.sender]) {return false;}
        if (!_resetTransferredCoinFees(msg.sender, _to, _value)){ return false;}
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
  }
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) stopInEmergency returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
    if (_value > balances[_from] || !isTransferEnabled || _value > _allowance) return false;
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    return doTransfer(_from, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) stopInEmergency returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
        return false;
    }

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
  function addApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2 * 32) stopInEmergency
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = safeAdd(oldValue, _addedValue);
      return true;
  }

   
  function subApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2 * 32) stopInEmergency
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = safeSub(oldVal, _subtractedValue);
      }
      return true;
  }

}