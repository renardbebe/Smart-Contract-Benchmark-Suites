 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
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

contract Owned {
    constructor() public { owner = msg.sender; }
    address payable owner;

     
     
     
     
     
     
     
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

 
contract ERC20Distributor is Owned{
	using SafeMath for uint256;
	
    IERC20 public handledToken;
    
    struct Account {
        address addy;
        uint256 share;
    }
    
	Account[] accounts;
    uint256 totalShares = 0;
	uint256 totalAccounts = 0;
	uint256 fullViewPercentage = 10000;
	
     
	 
    constructor(IERC20 _token) public {
        handledToken = _token;
    }
	
	 
	function getGlobals() public view returns(
		uint256 _tokenBalance, 
		uint256 _totalAccounts, 
		uint256 _totalShares, 
		uint256 _fullViewPercentage){
		return (
			handledToken.balanceOf(address(this)), 
			totalAccounts, 
			totalShares, 
			fullViewPercentage
		);
	}
	
	 
	function getAccountInfo(uint256 index) public view returns(
		uint256 _tokenBalance,
		uint256 _tokenEntitled,
		uint256 _shares, 
		uint256 _percentage,
		address _address){
		return (
			handledToken.balanceOf(accounts[index].addy),
			(accounts[index].share.mul(handledToken.balanceOf(address(this)))).div(totalShares),
			accounts[index].share, 
			(accounts[index].share.mul(fullViewPercentage)).div(totalShares), 
			accounts[index].addy
		);
	}
 
	 
	 
    function distributeTokens() public { 
		uint256 sharesProcessed = 0;
		uint256 currentAmount = handledToken.balanceOf(address(this));
		
        for(uint i = 0; i < accounts.length; i++)
        {
			if(accounts[i].share > 0 && accounts[i].addy != address(0)){
				uint256 amount = (currentAmount.mul(accounts[i].share)).div(totalShares.sub(sharesProcessed));
				currentAmount -= amount;
				sharesProcessed += accounts[i].share;
				handledToken.transfer(accounts[i].addy, amount);
			}
		}
    }

	 
    function writeAccount(address _address, uint256 _share) public onlyOwner {
        require(_address != address(0), "address can't be 0 address");
        require(_address != address(this), "address can't be this contract address");
        require(_share > 0, "share must be more than 0");
		deleteAccount(_address);
        Account memory acc = Account(_address, _share);
        accounts.push(acc);
        totalShares += _share;
		totalAccounts++;
    }
    
	 
    function deleteAccount(address _address) public onlyOwner{
        for(uint i = 0; i < accounts.length; i++)
        {
			if(accounts[i].addy == _address){
				totalShares -= accounts[i].share;
				if(i < accounts.length - 1){
					accounts[i] = accounts[accounts.length - 1];
				}
				delete accounts[accounts.length - 1];
				accounts.length--;
				totalAccounts--;
			}
		}
    }
	
	 
	 
	function withdrawOtherERC20(IERC20 _token) public onlyOwner{
		require(_token.balanceOf(address(this)) > 0, "no balance");
		require(_token != handledToken, "not allowed to withdraw handledToken");
		_token.transfer(owner, _token.balanceOf(address(this)));
	}
}