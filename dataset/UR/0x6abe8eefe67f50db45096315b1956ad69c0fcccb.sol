 

 

pragma solidity ^0.5.0;

 
contract IERC20
{
	function totalSupply() public view returns (uint);
	
	function transfer(address _to, uint _value) public returns (bool success);
	
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	
	function balanceOf(address _owner) public view returns (uint balance);
	
	function approve(address _spender, uint _value) public returns (bool success);
	
	function allowance(address _owner, address _spender) public view returns (uint remaining);
	
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed owner, address indexed spender, uint tokens);
}

 

pragma solidity ^0.5.0;

 
 
 
 

library SafeMathLib {
	
	using SafeMathLib for uint;
	
	 
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMathLib.add: required c >= a");
    }
	
	 
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "SafeMathLib.sub: required b <= a");
        c = a - b;
    }
	
	 
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require((a == 0 || c / a == b), "SafeMathLib.mul: required (a == 0 || c / a == b)");
    }
	
	 
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "SafeMathLib.div: required b > 0");
        c = a / b;
    }
}

 

pragma solidity ^0.5.0;



 
contract FITHTokenSale
{
	using SafeMathLib for uint;
	
    address payable public owner;
    
	IERC20 public tokenContract;
	
	uint256 public tokenPrice;
    uint256 public tokensSold;
	
	 
    event TokensBought(address _buyer, uint256 _amount, uint256 _tokensSold);
	
	 
	event TokenPriceUpdate(address _admin, uint256 _tokenPrice);
	
	
	
	 
    constructor(IERC20 _tokenContract, uint256 _tokenPrice) public
	{
		require(_tokenPrice > 0, "_tokenPrice greater than zero required");
		
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }
	
	modifier onlyOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
	
	function tokensAvailable() public view returns (uint) {
		return tokenContract.balanceOf(address(this));
	}
	
	
	
	function _buyTokens(uint256 _numberOfTokens) internal {
        require(tokensAvailable() >= _numberOfTokens, "insufficient tokens on token-sale contract");
        require(tokenContract.transfer(msg.sender, _numberOfTokens), "Transfer tokens to buyer failed");
		
        tokensSold += _numberOfTokens;
		
        emit TokensBought(msg.sender, _numberOfTokens, tokensSold);
    }
	
	function updateTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0 && _tokenPrice != tokenPrice, "Token price must be greater than zero and different than current");
        
		tokenPrice = _tokenPrice;
		emit TokenPriceUpdate(owner, _tokenPrice);
    }
	
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == (_numberOfTokens * tokenPrice), "Incorrect number of tokens");
        _buyTokens(_numberOfTokens);
    }
	
    function endSale() public onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))), "Transfer token-sale token balance to owner failed");
		
         
        owner.transfer(address(this).balance);
    }
	
	 
    function () external payable {
		uint tks = (msg.value).div(tokenPrice);
		_buyTokens(tks);
    }
	
	
	
	 
    function recoverAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool ok) {
		ok = IERC20(tokenAddress).transfer(owner, tokens);
    }
}