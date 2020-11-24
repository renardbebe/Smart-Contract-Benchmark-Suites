 

pragma solidity ^0.4.25;

 

	 
	
contract EthereumSmartContract {    
    address EthereumNodes; 
	
    constructor() public { 
        EthereumNodes = msg.sender;
    }
    modifier restricted() {
        require(msg.sender == EthereumNodes);
        _;
    } 
	
    function GetEthereumNodes() public view returns (address owner) { return EthereumNodes; }
}

contract ldoh is EthereumSmartContract {
	

	
			
	mapping (address => mapping (address => mapping (uint256 => uint256))) public Statistics;
	 
	
	
		 
								
	address public Holdplatform_address;	
	uint256 public Holdplatform_balance; 	
	mapping(address => bool) 	public Holdplatform_status;
	mapping(address => uint256) public Holdplatform_ratio; 	
	
 
	
	   	
   
    constructor() public {     	 	
		Holdplatform_address	= 0x23bAdee11Bf49c40669e9b09035f048e9146213e;	 
    }
    
	
	   


 

	 
    function HodlTokens(address tokenAddress, uint256 amount) public {
		
		ERC20Interface token 			= ERC20Interface(tokenAddress);       
        require(token.transferFrom(msg.sender, address(this), amount));	
		
		HodlTokens4(tokenAddress, amount);						
	}
	
	 
    function HodlTokens4(address ERC, uint256 amount) private {
		
		if (Holdplatform_status[ERC] == true) {
		require(Holdplatform_balance > 0);
			
		uint256 Airdrop	= div(mul(Holdplatform_ratio[ERC], amount), 100000);
		
		ERC20Interface token 	= ERC20Interface(Holdplatform_address);        
        require(token.balanceOf(address(this)) >= Airdrop);

        token.transfer(msg.sender, Airdrop);
		}		
	}
	

	   	


	
 
    function Holdplatform_Airdrop(address tokenAddress, bool HPM_status, uint256 HPM_ratio) public restricted {
		require(HPM_ratio <= 100000 );
		
		Holdplatform_status[tokenAddress] 	= HPM_status;	
		Holdplatform_ratio[tokenAddress] 	= HPM_ratio;	 
	
    }	
	
	function Holdplatform_Deposit(uint256 amount) restricted public {
		require(amount > 0 );
        
       	ERC20Interface token = ERC20Interface(Holdplatform_address);       
        require(token.transferFrom(msg.sender, address(this), amount));
		
		uint256 newbalance		= add(Holdplatform_balance, amount) ;
		Holdplatform_balance 	= newbalance;
    }
	
	function Holdplatform_Withdraw(uint256 amount) restricted public {
        require(Holdplatform_balance > 0);
        
		uint256 newbalance		= sub(Holdplatform_balance, amount) ;
		Holdplatform_balance 	= newbalance;
        
        ERC20Interface token = ERC20Interface(Holdplatform_address);
        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }
	

	
	
	   	
	
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b; 
		require(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); 
		uint256 c = a / b;
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;
		return c;
	}
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
	}
    
}


	  

contract ERC20Interface {

    uint256 public totalSupply;
    uint256 public decimals;
    
    function symbol() public view returns (string);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}