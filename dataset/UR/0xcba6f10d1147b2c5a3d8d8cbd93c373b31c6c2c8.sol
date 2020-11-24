 

pragma solidity^0.4.17;

 
contract Ownable{
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract VuePayTokenSale is StandardToken, Ownable {
	using SafeMath for uint256;
	 
	event CreatedVUP(address indexed _creator, uint256 _amountOfVUP);
	event VUPRefundedForWei(address indexed _refunder, uint256 _amountOfWei);
	event print(uint256 vup);
	 
	string public constant name = "VuePay Token";
	string public constant symbol = "VUP";
	uint256 public constant decimals = 18;   
	string public version = "1.0";
	
	 
	address public executor;
	 
	address public vuePayETHDestination=0x8B8698DEe100FC5F561848D0E57E94502Bd9318b;
	 
	address public constant devVUPDestination=0x31403fA55aEa2065bBDd2778bFEd966014ab0081;
	 
	address public constant coreVUPDestination=0x22d310194b5ac5086bDacb2b0f36D8f0a5971b23;
	 
	address public constant advisoryVUPDestination=0x991ABE74a1AC3d903dA479Ca9fede3d0954d430B;
	 
	address public constant udfVUPDestination=0xf4307C073451b80A0BaD1E099fD2B7f0fe38b7e9;
	 
	address public constant cofounderVUPDestination=0x863B2217E80e6C6192f63D3716c0cC7711Fad5b4;
	 
	address public constant unsoldVUPDestination=0x5076084a3377ecDF8AD5cD0f26A21bA848DdF435;
	 
	uint256 public totalVUP;
	
	 
	bool public saleHasEnded;
	bool public minCapReached;
	bool public preSaleEnded;
	bool public allowRefund;
	mapping (address => uint256) public ETHContributed;
	uint256 public totalETHRaised;
	uint256 public preSaleStartBlock;
	uint256 public preSaleEndBlock;
	uint256 public icoEndBlock;
	
    uint public constant coldStorageYears = 10 years;
    uint public coreTeamUnlockedAt;
    uint public unsoldUnlockedAt;
    uint256 coreTeamShare;
    uint256 cofounderShare;
    uint256 advisoryTeamShare;
    
	 
	uint256 curTokenRate = VUP_PER_ETH_BASE_RATE;
	uint256 public constant INITIAL_VUP_TOKEN_SUPPLY =1000000000e18;
	uint256 public constant VUP_TOKEN_SUPPLY_TIER1 =150000000e18;
    uint256 public constant VUP_TOKEN_SUPPLY_TIER2 =270000000e18;
	uint256 public constant VUP_TOKEN_SUPPLY_TIER3 =380000000e18;
	uint256 public constant VUP_TOKEN_SUPPLY_TIER4 =400000000e18;
	
	uint256 public constant PRESALE_ICO_PORTION =400000000e18;   
	uint256 public constant ADVISORY_TEAM_PORTION =50000000e18;   
	uint256 public constant CORE_TEAM_PORTION =50000000e18;   
	uint256 public constant DEV_TEAM_PORTION =50000000e18;   
	uint256 public constant CO_FOUNDER_PORTION = 350000000e18;   
	uint256 public constant UDF_PORTION =100000000e18;   
	
	uint256 public constant VUP_PER_ETH_BASE_RATE = 2000;   
	uint256 public constant VUP_PER_ETH_PRE_SALE_RATE = 3000;  
	
	uint256 public constant VUP_PER_ETH_ICO_TIER2_RATE = 2500;  
	uint256 public constant VUP_PER_ETH_ICO_TIER3_RATE = 2250; 
	
	
	function VuePayTokenSale () public payable
	{

	    totalSupply = INITIAL_VUP_TOKEN_SUPPLY;

		 
	    preSaleStartBlock=4340582;
	     
	    preSaleEndBlock = preSaleStartBlock + 37800;   
	    icoEndBlock = preSaleEndBlock + 81000;   
		executor = msg.sender;
		saleHasEnded = false;
		minCapReached = false;
		allowRefund = false;
		advisoryTeamShare = ADVISORY_TEAM_PORTION;
		totalETHRaised = 0;
		totalVUP=0;

	}

	function () payable public {
		
		 
		require(msg.value >= .05 ether);
		 
		require(!saleHasEnded);
		 
		require(block.number >= preSaleStartBlock);
		 
		require(block.number < icoEndBlock);
		 
		if (block.number > preSaleEndBlock){
		    preSaleEnded=true;
		}
		 
		require(msg.value!=0);

		uint256 newEtherBalance = totalETHRaised.add(msg.value);
		 
		getCurrentVUPRate();
		 
		
		uint256 amountOfVUP = msg.value.mul(curTokenRate);
	
         
		totalVUP=totalVUP.add(amountOfVUP);
	     
		require(totalVUP<= PRESALE_ICO_PORTION);
		
		 
		uint256 totalSupplySafe = totalSupply.sub(amountOfVUP);
		uint256 balanceSafe = balances[msg.sender].add(amountOfVUP);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);
		
		 
		totalSupply = totalSupplySafe;
		balances[msg.sender] = balanceSafe;

		totalETHRaised = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;

		CreatedVUP(msg.sender, amountOfVUP);
	}
	
	function getCurrentVUPRate() internal {
	         
	        curTokenRate = VUP_PER_ETH_BASE_RATE;

	         
	        if ((totalVUP <= VUP_TOKEN_SUPPLY_TIER1) && (!preSaleEnded)) {    
			        curTokenRate = VUP_PER_ETH_PRE_SALE_RATE;
	        }
		     
	        if ((totalVUP <= VUP_TOKEN_SUPPLY_TIER1) && (preSaleEnded)) {
			     curTokenRate = VUP_PER_ETH_ICO_TIER2_RATE;
		    }
		     
		    if (totalVUP >VUP_TOKEN_SUPPLY_TIER1 ) {
			    curTokenRate = VUP_PER_ETH_ICO_TIER2_RATE;
		    }
		     
		    if (totalVUP >VUP_TOKEN_SUPPLY_TIER2 ) {
			    curTokenRate = VUP_PER_ETH_ICO_TIER3_RATE;
		        
		    }
             
		    if (totalVUP >VUP_TOKEN_SUPPLY_TIER3){
		        curTokenRate = VUP_PER_ETH_BASE_RATE;
		    }
	}
     
     
     
    function createCustomVUP(address _clientVUPAddress,uint256 _value) public onlyOwner {
	     
	    require(_clientVUPAddress != address(0x0));
		require(_value >0);
		require(advisoryTeamShare>= _value);
	   
	  	uint256 amountOfVUP = _value;
	  	 
	    advisoryTeamShare=advisoryTeamShare.sub(amountOfVUP);
         
		totalVUP=totalVUP.add(amountOfVUP);
		 
		uint256 balanceSafe = balances[_clientVUPAddress].add(amountOfVUP);
		balances[_clientVUPAddress] = balanceSafe;
		 
		CreatedVUP(_clientVUPAddress, amountOfVUP);
	
	}
    
	function endICO() public onlyOwner{
		 
		require(!saleHasEnded);
		 
		require(minCapReached);
		
		saleHasEnded = true;

		 
	
	    coreTeamShare = CORE_TEAM_PORTION;
	    uint256 devTeamShare = DEV_TEAM_PORTION;
	    cofounderShare = CO_FOUNDER_PORTION;
	    uint256 udfShare = UDF_PORTION;
	
	    
		balances[devVUPDestination] = devTeamShare;
		balances[advisoryVUPDestination] = advisoryTeamShare;
		balances[udfVUPDestination] = udfShare;
       
         
        uint nineMonths = 9 * 30 days;
        coreTeamUnlockedAt = now.add(nineMonths);
         
        uint lockTime = coldStorageYears;
        unsoldUnlockedAt = now.add(lockTime);

		CreatedVUP(devVUPDestination, devTeamShare);
		CreatedVUP(advisoryVUPDestination, advisoryTeamShare);
		CreatedVUP(udfVUPDestination, udfShare);

	}
	function unlock() public onlyOwner{
	   require(saleHasEnded);
       require(now > coreTeamUnlockedAt || now > unsoldUnlockedAt);
       if (now > coreTeamUnlockedAt) {
          balances[coreVUPDestination] = coreTeamShare;
          CreatedVUP(coreVUPDestination, coreTeamShare);
          balances[cofounderVUPDestination] = cofounderShare;
          CreatedVUP(cofounderVUPDestination, cofounderShare);
         
       }
       if (now > unsoldUnlockedAt) {
          uint256 unsoldTokens=PRESALE_ICO_PORTION.sub(totalVUP);
          require(unsoldTokens > 0);
          balances[unsoldVUPDestination] = unsoldTokens;
          CreatedVUP(coreVUPDestination, unsoldTokens);
         }
    }

	 
	function withdrawFunds() public onlyOwner {
		 
		require(minCapReached);
		require(this.balance > 0);
		if(this.balance > 0) {
			vuePayETHDestination.transfer(this.balance);
		}
	}

	 
	function triggerMinCap() public onlyOwner {
		minCapReached = true;
	}

	 
	function triggerRefund() public onlyOwner{
		 
		require(!saleHasEnded);
		 
		require(!minCapReached);
		 
	    require(block.number >icoEndBlock);
		require(msg.sender == executor);
		allowRefund = true;
	}

	function claimRefund() external {
		 
		require(allowRefund);
		 
		require(ETHContributed[msg.sender]!=0);

		 
		uint256 etherAmount = ETHContributed[msg.sender];
		ETHContributed[msg.sender] = 0;

		VUPRefundedForWei(msg.sender, etherAmount);
		msg.sender.transfer(etherAmount);
	}
     
	function changeVuePayETHDestinationAddress(address _newAddress) public onlyOwner {
		vuePayETHDestination = _newAddress;
	}
	
	function transfer(address _to, uint _value) public returns (bool) {
		 
		require(minCapReached);
		return super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) public returns (bool) {
		 
		require(minCapReached);
		return super.transferFrom(_from, _to, _value);
	}

	
}