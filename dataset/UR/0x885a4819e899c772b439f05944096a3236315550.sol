 

pragma solidity ^0.4.19;

 
 
 
 
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "Token Name";
    string public constant symbol = "SYM";
    uint8 public constant decimals = 18;   

}

 

 
contract MarketboardERC20Listing {

     
    function _version() pure public returns(uint32) {
        return 2;
    }

     
    event MarketboardListingComplete(address indexed tokenContract, uint256 numTokensSold, uint256 totalEtherPrice, uint256 fee);

     
    event MarketboardListingBuyback(address indexed tokenContract, uint256 numTokens);

	 
	event MarketboardListingDestroyed();

     
    event MarketboardListingPriceChanged(uint256 oldPricePerToken, uint256 newPricePerToken);


     
    modifier moderatorOnly {
        require(msg.sender == moderator);
        _;
    }

     
    modifier moderatorOrSellerOnly {
        require(moderator == msg.sender || seller == msg.sender);
        _;
    }

     
	uint256 public tokenPrice = 0;

     
    address public tokenContract;

     
    address moderator;

     
    address seller;

     
     
    uint256 public feeFixed;

     
     
    uint32 public feePercentage;
	uint32 constant public feePercentageMax = 100000;

     
    function MarketboardERC20Listing(address _moderator, uint256 _feeFixed, uint32 _feePercentage, address _erc20Token, uint256 _tokenPrice) public {

         
        seller = msg.sender;
        moderator = _moderator;
        feeFixed = _feeFixed;
        feePercentage = _feePercentage;
        tokenContract = _erc20Token;
        tokenPrice = _tokenPrice;

    }

     
    function tokenCount() public view returns(uint256) {

         
        ERC20 erc = ERC20(tokenContract);
        return erc.balanceOf(this);

    }

     
    function tokenBase() public view returns(uint256) {

         
        ERC20 erc = ERC20(tokenContract);
        uint256 decimals = erc.decimals();
        return 10 ** decimals;

    }

     
    function totalPrice() public view returns(uint256) {

         
        return tokenPrice * tokenCount() / tokenBase() + fee();

    }

     
    function fee() public view returns(uint256) {

         
        uint256 price = tokenPrice * tokenCount() / tokenBase();

         
        return price * feePercentage / feePercentageMax + feeFixed;

    }

     
    function setPrice(uint256 newTokenPrice) moderatorOrSellerOnly public {

         
        uint256 oldPrice = tokenPrice;

         
        tokenPrice = newTokenPrice;

         
        MarketboardListingPriceChanged(oldPrice, newTokenPrice);

    }

     
    function buyback(address recipient) moderatorOrSellerOnly public {

         
        ERC20 erc = ERC20(tokenContract);
		uint256 balance = erc.balanceOf(this);
        erc.transfer(recipient, balance);

         
        MarketboardListingBuyback(tokenContract, balance);

         
        reset();

    }

	 
     
    function purchase(address recipient) public payable {

         
        require(msg.value >= totalPrice());

         
        ERC20 erc = ERC20(tokenContract);
		uint256 balance = erc.balanceOf(this);
        erc.transfer(recipient, balance);

		 
		uint256 basePrice = tokenPrice * balance;
		require(basePrice > 0);
		require(basePrice < this.balance);

		 
		seller.transfer(basePrice);

         
        MarketboardListingComplete(tokenContract, balance, 0, 0);

         
        reset();

    }

     
    function claimUnrelatedTokens(address unrelatedTokenContract, address recipient) moderatorOrSellerOnly public {

         
        require(tokenContract != unrelatedTokenContract);

         
        ERC20 erc = ERC20(unrelatedTokenContract);
        uint256 balance = erc.balanceOf(this);
        erc.transfer(recipient, balance);

    }

	 
	function reset() internal {

         
        MarketboardListingDestroyed();

		 
		selfdestruct(moderator);

	}

}