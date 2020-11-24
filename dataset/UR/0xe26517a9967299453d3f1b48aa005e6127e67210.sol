 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
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


 




 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

 








 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 




contract NIMFAToken is StandardToken {
	using SafeMath for uint256;
	
	
	
	event CreatedNIMFA(address indexed _creator, uint256 _amountOfNIMFA);
	
	 
	string public constant name = "NIMFA Token";
	string public constant symbol = "NIMFA";
	uint256 public constant decimals = 18; 
	string public version = "1.0";
	
	 
	address public executor;
	address public teamETHAddress;  
	address public teamNIMFAAddress;
	address public creditFundNIMFAAddress;
	address public reserveNIMFAAddress;
	
	bool public preSaleHasEnded;
	bool public saleHasEnded;
	bool public allowTransfer;
	bool public maxPreSale;   
	mapping (address => uint256) public ETHContributed;
	uint256 public totalETH;
	uint256 public preSaleStartBlock;
	uint256 public preSaleEndBlock;
	uint256 public saleStartBlock;
	uint256 public saleEndBlock;
	uint256 public constant NIMFA_PER_ETH_PRE_SALE = 1100;   
	uint256 public constant NIMFA_PER_ETH_SALE = 110;   
	

	
	function NIMFAToken(
		address _teamETHAddress,
		address _teamNIMFAAddress,
		address _creditFundNIMFAAddress,
		address _reserveNIMFAAddress,
		uint256 _preSaleStartBlock,
		uint256 _preSaleEndBlock
	) {
		
		if (_teamETHAddress == address(0x0)) throw;
		if (_teamNIMFAAddress == address(0x0)) throw;
		if (_creditFundNIMFAAddress == address(0x0)) throw;
		if (_reserveNIMFAAddress == address(0x0)) throw;
		 
		if (_preSaleEndBlock <= block.number) throw;
		 
		if (_preSaleEndBlock <= _preSaleStartBlock) throw;

		executor = msg.sender;
		preSaleHasEnded = false;
		saleHasEnded = false;
		allowTransfer = false;
		maxPreSale = false;
		teamETHAddress = _teamETHAddress;
		teamNIMFAAddress = _teamNIMFAAddress;
		creditFundNIMFAAddress = _creditFundNIMFAAddress;
		reserveNIMFAAddress = _reserveNIMFAAddress;
		totalETH = 0;
		preSaleStartBlock = _preSaleStartBlock;
		preSaleEndBlock = _preSaleEndBlock;
		saleStartBlock = _preSaleStartBlock;
		saleEndBlock = _preSaleEndBlock;
		totalSupply = 0;
	}
	
	function investment() payable external {
		 
		if (preSaleHasEnded && saleHasEnded) throw;
		if (!preSaleHasEnded) {
		    if (block.number < preSaleStartBlock) throw;
		    if (block.number > preSaleEndBlock) throw;
		}
		if (block.number < saleStartBlock) throw;
		if (block.number > saleEndBlock) throw;
		
		uint256 newEtherBalance = totalETH.add(msg.value);

		 
		if (0 == msg.value) throw;
		
		 
		uint256 amountOfNIMFA = msg.value.mul(NIMFA_PER_ETH_PRE_SALE);
		if (preSaleHasEnded || maxPreSale) amountOfNIMFA = msg.value.mul(NIMFA_PER_ETH_SALE);
		
		if (100000 ether < amountOfNIMFA) throw;
		
		 
		uint256 totalSupplySafe = totalSupply.add(amountOfNIMFA);
		uint256 balanceSafe = balances[msg.sender].add(amountOfNIMFA);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);

		 
		totalSupply = totalSupplySafe;
		if (totalSupply > 2000000 ether) maxPreSale = true;
		balances[msg.sender] = balanceSafe;

		totalETH = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;
		if (!preSaleHasEnded) teamETHAddress.transfer(msg.value);

		CreatedNIMFA(msg.sender, amountOfNIMFA);
	}
	
	function endPreSale() {
		 
		if (preSaleHasEnded) throw;
		
		 
		if (msg.sender != executor) throw;
		
		preSaleHasEnded = true;
	}
	
	
	function endSale() {
		
		if (!preSaleHasEnded) throw;
		 
		if (saleHasEnded) throw;
		
		 
		if (msg.sender != executor) throw;
		
		saleHasEnded = true;
		uint256 EtherAmount = this.balance;
		teamETHAddress.transfer(EtherAmount);
		
		uint256 creditFund = totalSupply.mul(3);
		uint256 reserveNIMFA = totalSupply.div(2);
		uint256 teamNIMFA = totalSupply.div(2);
		uint256 totalSupplySafe = totalSupply.add(creditFund).add(reserveNIMFA).add(teamNIMFA);


		totalSupply = totalSupplySafe;
		balances[creditFundNIMFAAddress] = creditFund;
		balances[reserveNIMFAAddress] = reserveNIMFA;
		balances[teamNIMFAAddress] = teamNIMFA;
		
		CreatedNIMFA(creditFundNIMFAAddress, creditFund);
		CreatedNIMFA(reserveNIMFAAddress, reserveNIMFA);
        CreatedNIMFA(teamNIMFAAddress, teamNIMFA);
	}
	
	
	function changeTeamETHAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		teamETHAddress = _newAddress;
	}
	
	function changeTeamNIMFAAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		teamNIMFAAddress = _newAddress;
	}
	
	function changeCreditFundNIMFAAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		creditFundNIMFAAddress = _newAddress;
	}
	
	 
	function changeAllowTransfer() {
		if (msg.sender != executor) throw;

		allowTransfer = true;
	}
	
	 
	function changeSaleStartBlock(uint256 _saleStartBlock) {
		if (msg.sender != executor) throw;
        saleStartBlock = _saleStartBlock;
	}
	
	 
	function changeSaleEndBlock(uint256 _saleEndBlock) {
		if (msg.sender != executor) throw;
        saleEndBlock = _saleEndBlock;
	}
	
	
	function transfer(address _to, uint _value) {
		 
		if (!allowTransfer) throw;
		
		super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) {
		 
		if (!allowTransfer) throw;
		
		super.transferFrom(_from, _to, _value);
	}
}