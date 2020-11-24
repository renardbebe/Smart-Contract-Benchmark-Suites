 

pragma solidity ^0.4.19;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {

    address public owner;
    address public proposedOwner = address(0);

    event OwnershipTransferInitiated(address indexed _proposedOwner);
    event OwnershipTransferCompleted(address indexed _newOwner);
    event OwnershipTransferCanceled();


    function Owned() public
    {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }


    function isOwner(address _address) public view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        require(_proposedOwner != address(0));
        require(_proposedOwner != address(this));
        require(_proposedOwner != owner);

        proposedOwner = _proposedOwner;

        OwnershipTransferInitiated(proposedOwner);

        return true;
    }


    function cancelOwnershipTransfer() public onlyOwner returns (bool) {
         
        if (proposedOwner == address(0)) {
            return true;
        }
         
        proposedOwner = address(0);

        OwnershipTransferCanceled();

        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {

        require(msg.sender == proposedOwner);

        owner = msg.sender;
        proposedOwner = address(0);

        OwnershipTransferCompleted(owner);

        return true;
    }
}

contract TokenTransfer {
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    function decimals() public view returns (uint8 tokenDecimals);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract FlexibleTokenSale is  Owned {

    using SafeMath for uint256;

     
     
     
    bool public suspended;

     
     
     
    uint256 public tokenPrice;
    uint256 public tokenPerEther;
    uint256 public contributionMin;
    uint256 public tokenConversionFactor;

     
     
     
    address public walletAddress;

     
     
     
    TokenTransfer token;


     
     
     
    uint256 public totalTokensSold;
    uint256 public totalEtherCollected;
    
     
     
     
    address public priceUpdateAddress;


     
     
     
    event Initialized();
    event TokenPriceUpdated(uint256 _newValue);
    event TokenPerEtherUpdated(uint256 _newValue);
    event TokenMinUpdated(uint256 _newValue);
    event WalletAddressUpdated(address indexed _newAddress);
    event SaleSuspended();
    event SaleResumed();
    event TokensPurchased(address indexed _beneficiary, uint256 _cost, uint256 _tokens);
    event TokensReclaimed(uint256 _amount);
    event PriceAddressUpdated(address indexed _newAddress);


    function FlexibleTokenSale(address _tokenAddress,address _walletAddress,uint _tokenPerEther,address _priceUpdateAddress) public
    Owned()
    {

        require(_walletAddress != address(0));
        require(_walletAddress != address(this));
        require(address(token) == address(0));
        require(address(_tokenAddress) != address(0));
        require(address(_tokenAddress) != address(this));
        require(address(_tokenAddress) != address(walletAddress));

        walletAddress = _walletAddress;
        priceUpdateAddress = _priceUpdateAddress;
        token = TokenTransfer(_tokenAddress);
        suspended = false;
        tokenPrice = 100;
        tokenPerEther = _tokenPerEther;
        contributionMin     = 5 * 10**18; 
        totalTokensSold     = 0;
        totalEtherCollected = 0;
         
        
       
       tokenConversionFactor = 10**(uint256(18).sub(token.decimals()).add(2));
        assert(tokenConversionFactor > 0);
    }


     
     
     

     
     
    function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
        require(_walletAddress != address(0));
        require(_walletAddress != address(this));
        require(_walletAddress != address(token));
        require(isOwner(_walletAddress) == false);

        walletAddress = _walletAddress;

        WalletAddressUpdated(_walletAddress);

        return true;
    }

     
    function setTokenPrice(uint _tokenPrice) external onlyOwner returns (bool) {
        require(_tokenPrice >= 100 && _tokenPrice <= 100000);

        tokenPrice=_tokenPrice;

        TokenPriceUpdated(_tokenPrice);
        return true;
    }

    function setMinToken(uint256 _minToken) external onlyOwner returns(bool) {
        require(_minToken > 0);

        contributionMin = _minToken;

        TokenMinUpdated(_minToken);

        return true;
    }

     
    function suspend() external onlyOwner returns(bool) {
        if (suspended == true) {
            return false;
        }

        suspended = true;

        SaleSuspended();

        return true;
    }

     
    function resume() external onlyOwner returns(bool) {
        if (suspended == false) {
            return false;
        }

        suspended = false;

        SaleResumed();

        return true;
    }


     
     
     

     
    function () payable public {
        buyTokens(msg.sender);
    }


     
    function buyTokens(address _beneficiary) public payable returns (uint256) {
        require(!suspended);

        require(address(token) !=  address(0));
        require(_beneficiary != address(0));
        require(_beneficiary != address(this));
        require(_beneficiary != address(token));


         
         
        require(msg.sender != address(walletAddress));

         
        uint256 saleBalance = token.balanceOf(address(this));
        assert(saleBalance > 0);


        return buyTokensInternal(_beneficiary);
    }

    function updateTokenPerEther(uint _etherPrice) public returns(bool){
        require(_etherPrice > 0);
        require(msg.sender == priceUpdateAddress || msg.sender == owner);
        tokenPerEther=_etherPrice;
        TokenPerEtherUpdated(_etherPrice);
        return true;
    }
    
    function updatePriceAddress(address _newAddress) public onlyOwner returns(bool){
        require(_newAddress != address(0));
        priceUpdateAddress=_newAddress;
        PriceAddressUpdated(_newAddress);
        return true;
    }


    function buyTokensInternal(address _beneficiary) internal returns (uint256) {

         
        uint256 tokens =msg.value.mul(tokenPerEther.mul(100).div(tokenPrice)).div(tokenConversionFactor);
        require(tokens >= contributionMin);

         
        uint256 contribution =msg.value;
        walletAddress.transfer(contribution);
        totalEtherCollected = totalEtherCollected.add(contribution);

         
        totalTokensSold = totalTokensSold.add(tokens);

         
        require(token.transfer(_beneficiary, tokens));

        TokensPurchased(_beneficiary, msg.value, tokens);

        return tokens;
    }


     
    function reclaimTokens() external onlyOwner returns (bool) {

        uint256 tokens = token.balanceOf(address(this));

        if (tokens == 0) {
            return false;
        }

        require(token.transfer(owner, tokens));

        TokensReclaimed(tokens);

        return true;
    }
}

contract DOCTokenSaleConfig {
    address WALLET_ADDRESS = 0x347364f2bc343f6c676620d09eb9c37431dbee60;
    address TOKEN_ADDRESS = 0xede3fe45d0c671f21ed10eb7bcd0a85ec9f8418e;
    address UPDATE_PRICE_ADDRESS = 0x29b997d4b41b9840e60b86f32be029382b14bdcd;
    uint ETHER_PRICE = 46500; 
}

contract DOCTokenSale is FlexibleTokenSale, DOCTokenSaleConfig {

    function DOCTokenSale() public
    FlexibleTokenSale(TOKEN_ADDRESS,WALLET_ADDRESS,ETHER_PRICE,UPDATE_PRICE_ADDRESS)
    {

    }

}